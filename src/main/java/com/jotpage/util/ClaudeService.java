package com.jotpage.util;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

/**
 * Thin wrapper around the Anthropic Messages API.
 *
 * Config comes from web.xml context params:
 *   anthropic.apiKey
 *
 * Usage:
 *   ClaudeService svc = new ClaudeService(apiKey);
 *   String out = svc.process(inputText, "study_notes", null);
 *
 * The LLM HTTP call lives in a single private method (sendRequest) so swapping
 * to a different provider later means replacing that one method — the public
 * process() surface stays stable.
 */
public class ClaudeService {

    private static final String API_URL = "https://api.anthropic.com/v1/messages";
    private static final String ANTHROPIC_VERSION = "2023-06-01";
    private static final String MODEL = "claude-sonnet-4-20250514";
    private static final int MAX_TOKENS = 4096;
    private static final int CONNECT_TIMEOUT_MS = 30_000;
    private static final int READ_TIMEOUT_MS = 120_000;

    private final String apiKey;
    private final Gson gson = new Gson();

    public ClaudeService(String apiKey) {
        if (apiKey == null || apiKey.isEmpty() || "PASTE_YOUR_API_KEY_HERE".equals(apiKey)) {
            throw new IllegalArgumentException(
                    "ClaudeService: anthropic.apiKey is not configured");
        }
        this.apiKey = apiKey;
    }

    /**
     * Run inputText through Claude according to the named job type.
     *
     * @param inputText    The raw user text (usually a transcript)
     * @param jobType      One of: study_notes, meeting_minutes, journal_entry,
     *                     outline, custom
     * @param customPrompt Required only when jobType == "custom"; used as the
     *                     system prompt with a clarifying prefix.
     * @return The assistant's response text.
     */
    public String process(String inputText, String jobType, String customPrompt) {
        if (inputText == null) inputText = "";
        String system = systemPromptFor(jobType, customPrompt);
        return sendRequest(system, inputText);
    }

    private String systemPromptFor(String jobType, String customPrompt) {
        if (jobType == null) jobType = "";
        switch (jobType) {
            case "study_notes":
                return "You are a study assistant. Take the following lecture transcript and "
                        + "create well-organized study notes with clear headers, key concepts, "
                        + "definitions, and important points. Use markdown formatting with ## "
                        + "headers, **bold** for key terms, and bullet points. Organize "
                        + "logically by topic, not chronologically.";
            case "meeting_minutes":
                return "You are a professional meeting assistant. Take the following transcript "
                        + "and create structured meeting minutes with: Attendees (if mentioned), "
                        + "Key Discussion Points, Decisions Made, Action Items (with owners if "
                        + "mentioned), and Next Steps. Use markdown formatting.";
            case "journal_entry":
                return "You are a reflective writing assistant. Take the following transcript "
                        + "and rewrite it as a thoughtful first-person journal entry. Maintain "
                        + "the key content and emotions but make it read naturally as a written "
                        + "journal entry. Use flowing paragraphs, not bullet points.";
            case "outline":
                return "You are an academic assistant. Take the following transcript and "
                        + "extract a clean structured outline with main topics and subtopics. "
                        + "Use markdown with ## for main topics and - for subtopics. Be "
                        + "concise \u2014 capture the structure, not every detail.";
            case "custom":
                String cp = (customPrompt == null) ? "" : customPrompt.trim();
                if (cp.isEmpty()) {
                    throw new IllegalArgumentException(
                            "ClaudeService: customPrompt is required for job type 'custom'");
                }
                return "Process the following transcript according to these instructions: " + cp;
            default:
                throw new IllegalArgumentException(
                        "ClaudeService: unknown jobType '" + jobType + "'");
        }
    }

    // ------------------------------------------------------------------
    // Private: the only place that talks HTTP to the LLM. Swap this to
    // retarget a different provider.
    // ------------------------------------------------------------------
    private String sendRequest(String systemPrompt, String userText) {
        JsonObject body = new JsonObject();
        body.addProperty("model", MODEL);
        body.addProperty("max_tokens", MAX_TOKENS);
        body.addProperty("system", systemPrompt);
        JsonArray messages = new JsonArray();
        JsonObject userMsg = new JsonObject();
        userMsg.addProperty("role", "user");
        userMsg.addProperty("content", userText);
        messages.add(userMsg);
        body.add("messages", messages);

        byte[] payload = gson.toJson(body).getBytes(StandardCharsets.UTF_8);

        HttpURLConnection conn = null;
        try {
            URL url = new URL(API_URL);
            conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setConnectTimeout(CONNECT_TIMEOUT_MS);
            conn.setReadTimeout(READ_TIMEOUT_MS);
            conn.setDoOutput(true);
            conn.setRequestProperty("x-api-key", apiKey);
            conn.setRequestProperty("anthropic-version", ANTHROPIC_VERSION);
            conn.setRequestProperty("content-type", "application/json");
            conn.setFixedLengthStreamingMode(payload.length);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(payload);
            }

            int status = conn.getResponseCode();
            if (status < 200 || status >= 300) {
                String errBody = readStream(safeErrorStream(conn));
                throw new RuntimeException(
                        "Claude API error " + status + ": " + errBody);
            }

            String responseBody = readStream(conn.getInputStream());
            JsonObject resp = JsonParser.parseString(responseBody).getAsJsonObject();
            if (!resp.has("content") || !resp.get("content").isJsonArray()) {
                throw new RuntimeException(
                        "Claude API: unexpected response shape: " + responseBody);
            }
            JsonArray content = resp.getAsJsonArray("content");
            StringBuilder out = new StringBuilder();
            for (int i = 0; i < content.size(); i++) {
                JsonObject part = content.get(i).getAsJsonObject();
                if (part.has("type") && "text".equals(part.get("type").getAsString())
                        && part.has("text")) {
                    if (out.length() > 0) out.append("\n");
                    out.append(part.get("text").getAsString());
                }
            }
            return out.toString();
        } catch (IOException e) {
            throw new RuntimeException("Claude API: network failure", e);
        } finally {
            if (conn != null) conn.disconnect();
        }
    }

    private static InputStream safeErrorStream(HttpURLConnection conn) {
        InputStream es = conn.getErrorStream();
        if (es != null) return es;
        try {
            return conn.getInputStream();
        } catch (IOException e) {
            return new java.io.ByteArrayInputStream(new byte[0]);
        }
    }

    private static String readStream(InputStream in) {
        if (in == null) return "";
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(in, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (sb.length() > 0) sb.append('\n');
                sb.append(line);
            }
        } catch (IOException ignored) {
        }
        return sb.toString();
    }
}
