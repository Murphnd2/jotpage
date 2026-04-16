package com.jotpage.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import com.jotpage.dao.AiJobDao;
import com.jotpage.dao.PageDao;
import com.jotpage.dao.PageTagDao;
import com.jotpage.dao.PageTypeDao;
import com.jotpage.dao.TagDao;
import com.jotpage.dao.UsageDao;
import com.jotpage.model.AiJob;
import com.jotpage.model.Page;
import com.jotpage.model.PageType;
import com.jotpage.model.UsageRecord;
import com.jotpage.model.User;
import com.jotpage.util.AppConfig;
import com.jotpage.util.ClaudeService;
import com.jotpage.util.PageSplitter;
import com.jotpage.util.TierCheck;
import com.jotpage.util.VoiceModeValidator;
import com.jotpage.util.WhisperService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@WebServlet("/app/voice-record")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 26_214_400L,       // 25 MB
        maxRequestSize = 27_262_976L      // 26 MB (headroom for form fields)
)
public class VoiceRecordServlet extends HttpServlet {

    private static final int TEXT_X = 50;
    private static final int TEXT_Y = 50;
    private static final int TEXT_W = 1380;
    private static final int TEXT_H = 2000;
    private static final String TEXT_COLOR = "#3b2f2f";

    private final TagDao tagDao = new TagDao();
    private final PageDao pageDao = new PageDao();
    private final PageTypeDao pageTypeDao = new PageTypeDao();
    private final PageTagDao pageTagDao = new PageTagDao();
    private final AiJobDao aiJobDao = new AiJobDao();
    private final UsageDao usageDao = new UsageDao();
    private final Gson gson = new Gson();

    private WhisperService whisperService;
    private ClaudeService claudeService;

    @Override
    public void init() throws ServletException {
        String whisperCommand = AppConfig.get("whisper.command", "whisper");
        String whisperModel = AppConfig.get("whisper.model", "base");
        String ffmpegPath = AppConfig.get("ffmpeg.path", "");
        whisperService = new WhisperService(whisperCommand, whisperModel, ffmpegPath);
        if (ffmpegPath != null && !ffmpegPath.trim().isEmpty()) {
            log("[voice] ffmpeg.path configured: " + ffmpegPath.trim());
        }

        String apiKey = AppConfig.get("anthropic.apiKey");
        if (apiKey != null) apiKey = apiKey.trim();
        if (apiKey != null && !apiKey.isEmpty()
                && !"PASTE_YOUR_API_KEY_HERE".equals(apiKey)) {
            try {
                claudeService = new ClaudeService(apiKey);
            } catch (Exception e) {
                log("ClaudeService init failed", e);
                claudeService = null;
            }
        } else {
            claudeService = null;
            log("anthropic.apiKey not configured \u2014 AI processing will be unavailable");
        }
    }

    // ------------------------------------------------------------------
    // GET — render the voice entry page
    // ------------------------------------------------------------------
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = requireUser(req, resp);
        if (user == null) return;

        try {
            req.setAttribute("tags", tagDao.findByUserId(user.getId()));

            // Pass AI trial usage per mode so the frontend can show status
            if (!TierCheck.isPro(user)) {
                JsonObject trialUsage = new JsonObject();
                String[] modes = {"study_notes", "meeting_minutes", "journal_entry", "outline", "custom"};
                for (String mode : modes) {
                    trialUsage.addProperty(mode, aiJobDao.countByUserIdAndJobType(user.getId(), mode));
                }
                req.setAttribute("trialUsageJson", gson.toJson(trialUsage));
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        req.setAttribute("userTier", user.getTier() == null ? "free" : user.getTier());
        req.setAttribute("isPro", TierCheck.isPro(user));
        req.getRequestDispatcher("/jsp/voice-record.jsp").forward(req, resp);
    }

    // ------------------------------------------------------------------
    // POST — run the pipeline
    // ------------------------------------------------------------------
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = requireUser(req, resp);
        if (user == null) return;

        String jobType = stringParam(req, "jobType", "verbatim");
        String customPrompt = stringParam(req, "customPrompt", null);
        String browserTranscript = stringParam(req, "browserTranscript", "");
        // fontSize here is the UI point size (e.g. 16). PageSplitter scales
        // it to canvas pixels internally; we also multiply by
        // PageSplitter.POINT_TO_PIXEL when writing the text_layers JSON so
        // ink-engine renders the block at the correct real-world size.
        int fontSize = intParam(req, "fontSize", 16);
        String tagIdsStr = stringParam(req, "tagIds", "");

        boolean isPro = TierCheck.isPro(user);

        log("[voice] POST userId=" + user.getId()
                + " tier=" + (isPro ? "pro" : "free")
                + " jobType=" + jobType
                + " fontSize=" + fontSize
                + " browserTranscriptLen="
                + (browserTranscript == null ? 0 : browserTranscript.length()));

        // Tier gate: non-verbatim modes allowed for Pro, or 1 free trial per mode.
        if (!"verbatim".equals(jobType)) {
            if (!isPro) {
                try {
                    int used = aiJobDao.countByUserIdAndJobType(user.getId(), jobType);
                    if (used >= TierCheck.FREE_AI_TRIAL_PER_MODE) {
                        writeJsonError(resp, HttpServletResponse.SC_FORBIDDEN,
                                "You\u2019ve used your free trial of this mode. "
                                        + "Upgrade to Jyrnyl Pro for unlimited AI processing.");
                        return;
                    }
                } catch (SQLException e) {
                    throw new ServletException(e);
                }
            }
            if (claudeService == null) {
                writeJsonError(resp, HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                        "AI processing is not configured on this server.");
                return;
            }
            if ("custom".equals(jobType)
                    && (customPrompt == null || customPrompt.trim().isEmpty())) {
                writeJsonError(resp, HttpServletResponse.SC_BAD_REQUEST,
                        "A custom prompt is required for the Custom job type.");
                return;
            }
        }

        // Stash the uploaded audio as a temp file (if present)
        File audioTempFile = null;
        try {
            Part audioPart;
            try {
                audioPart = req.getPart("audioFile");
            } catch (IllegalStateException e) {
                writeJsonError(resp, HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE,
                        "Audio file too large (max 25 MB).");
                return;
            }
            if (audioPart != null && audioPart.getSize() > 0) {
                audioTempFile = saveToTempFile(audioPart);
                log("[voice] audio saved to " + audioTempFile.getAbsolutePath()
                        + " (" + audioPart.getSize() + " bytes)");
            } else {
                log("[voice] no audio file in request");
            }

            // Track attempt in ai_jobs
            AiJob job = new AiJob();
            job.setUserId(user.getId());
            job.setJobType(jobType);
            job.setStatus("processing");
            job.setCustomPrompt(customPrompt);
            if (audioTempFile != null) {
                job.setAudioFilePath(audioTempFile.getAbsolutePath());
            }
            try {
                job = aiJobDao.create(job);
                if (!"verbatim".equals(jobType)) {
                    usageDao.incrementAiJobs(user.getId());
                }
            } catch (SQLException e) {
                throw new ServletException(e);
            }

            // ---- Transcription ---------------------------------------
            // Whisper runs whenever we have an audio file, regardless of
            // tier. Free-tier uploads have no browser-side transcript, so
            // server-side transcription is the only path. If Whisper fails
            // (e.g. binary missing, timeout), we fall back to whatever
            // transcript the browser sent with the request.
            String transcript = null;
            if (audioTempFile != null) {
                try {
                    log("[voice] running Whisper on " + audioTempFile.getAbsolutePath());
                    long t0 = System.currentTimeMillis();
                    transcript = whisperService.transcribe(audioTempFile);
                    long took = System.currentTimeMillis() - t0;
                    log("[voice] Whisper complete in " + took + " ms, "
                            + (transcript == null ? 0 : transcript.length())
                            + " chars");
                } catch (Exception e) {
                    log("[voice] Whisper failed, falling back to browser transcript", e);
                    transcript = null;
                }
            }
            if (transcript == null || transcript.isEmpty()) {
                transcript = browserTranscript == null ? "" : browserTranscript.trim();
            }
            if (transcript == null || transcript.isEmpty()) {
                log("[voice] no transcript available after Whisper + fallback");
                markJobFailed(job, "No transcript available");
                String msg = (audioTempFile != null)
                        ? "Audio was uploaded but we couldn't produce a transcript. "
                                + "Check that Whisper is installed on the server."
                        : "No transcript was provided. Record or type something first.";
                writeJsonError(resp, HttpServletResponse.SC_BAD_REQUEST, msg);
                return;
            }

            // ---- Mode-specific transcript validation -----------------
            // Verbatim passes straight through; other modes check that the
            // transcript carries the signals the target format needs so we
            // don't burn a Claude call on content it can't shape.
            VoiceModeValidator.Result vr = VoiceModeValidator.validate(jobType, transcript, customPrompt);
            log("[voice-record] validation=" + (vr.ok ? "ok" : "fail:" + vr.detail));
            if (!vr.ok) {
                markJobFailed(job, "Validation failed: " + vr.detail);
                // 422 Unprocessable Entity — not defined as a constant on
                // HttpServletResponse in Jakarta Servlet, so pass the literal.
                writeJsonError(resp, 422, vr.userMessage);
                return;
            }

            // ---- LLM processing --------------------------------------
            String outputText;
            if ("verbatim".equals(jobType)) {
                outputText = transcript;
            } else {
                try {
                    outputText = claudeService.process(transcript, jobType, customPrompt);
                } catch (Exception e) {
                    log("[voice] Claude processing failed", e);
                    markJobFailed(job, "AI processing failed: " + e.getMessage());
                    writeJsonError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                            "AI processing failed: " + safeMessage(e));
                    return;
                }
            }

            // ---- Page creation ---------------------------------------
            // PageSplitter takes the point size and handles canvas-pixel
            // scaling internally when computing chars-per-line and
            // lines-per-page.
            List<String> chunks = PageSplitter.splitToPages(outputText, fontSize);
            int pageCount = chunks.size();
            log("[voice] split into " + pageCount + " page(s)");

            // Enforce the free-tier monthly page cap. Pro users and free users
            // still in their first calendar month get UNLIMITED and skip this.
            int monthlyLimit = TierCheck.getMonthlyPageLimit(user);
            if (monthlyLimit != TierCheck.UNLIMITED) {
                try {
                    UsageRecord usage = usageDao.findOrCreateCurrentMonth(user.getId());
                    int alreadyThisMonth = usage == null ? 0 : usage.getPagesCreated();
                    if (alreadyThisMonth + pageCount > monthlyLimit) {
                        markJobFailed(job, "Page limit reached");
                        writeJsonError(resp, HttpServletResponse.SC_FORBIDDEN,
                                "You've reached this month's " + monthlyLimit
                                        + "-page limit on the free tier. "
                                        + "Upgrade to Pro for unlimited pages.");
                        return;
                    }
                } catch (SQLException e) {
                    throw new ServletException(e);
                }
            }

            PageType blankType;
            try {
                blankType = findBlankSystemType();
            } catch (SQLException e) {
                throw new ServletException(e);
            }
            if (blankType == null) {
                markJobFailed(job, "No blank page type configured");
                writeJsonError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                        "Server misconfiguration: no blank page template available.");
                return;
            }

            List<Long> tagIds = parseIdList(tagIdsStr);

            List<Long> createdPageIds = new ArrayList<>();
            try {
                for (String chunk : chunks) {
                    Page page = buildPage(user.getId(), blankType.getId(), chunk, fontSize);
                    Page created = pageDao.create(page);
                    createdPageIds.add(created.getId());
                    for (Long tid : tagIds) {
                        try {
                            pageTagDao.addTag(created.getId(), tid);
                        } catch (SQLException ignored) {
                            // A stale tag id shouldn't kill the whole batch.
                        }
                    }
                }
                usageDao.incrementPages(user.getId(), pageCount);
                aiJobDao.updateStatus(job.getId(), "complete", outputText, null);
            } catch (SQLException e) {
                markJobFailed(job, "Page creation failed: " + e.getMessage());
                throw new ServletException(e);
            }

            log("[voice] created pages " + createdPageIds);

            JsonObject result = new JsonObject();
            result.addProperty("success", true);
            result.addProperty("pagesCreated", pageCount);
            result.addProperty("redirectUrl", req.getContextPath() + "/app/dashboard");
            JsonArray ids = new JsonArray();
            for (Long id : createdPageIds) ids.add(id);
            result.add("pageIds", ids);
            writeJson(resp, HttpServletResponse.SC_OK, gson.toJson(result));
        } finally {
            if (audioTempFile != null) {
                try {
                    if (!audioTempFile.delete()) {
                        audioTempFile.deleteOnExit();
                    }
                } catch (Exception ignored) {
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------
    /**
     * Build a Page with a single text block containing the given chunk.
     *
     * @param pointSize the UI-displayed font size (point size). We multiply
     *                  by PageSplitter.POINT_TO_PIXEL when writing the
     *                  text_layers JSON so ink-engine can render it at the
     *                  correct real-world size on the 1480x2100 canvas.
     */
    private Page buildPage(long userId, long pageTypeId, String text, int pointSize) {
        int canvasFontSize = pointSize * PageSplitter.POINT_TO_PIXEL;

        JsonObject tb = new JsonObject();
        tb.addProperty("id", UUID.randomUUID().toString());
        tb.addProperty("x", TEXT_X);
        tb.addProperty("y", TEXT_Y);
        tb.addProperty("text", text == null ? "" : text);
        tb.addProperty("fontSize", canvasFontSize);
        tb.addProperty("color", TEXT_COLOR);
        tb.addProperty("width", TEXT_W);
        tb.addProperty("height", TEXT_H);
        JsonArray layers = new JsonArray();
        layers.add(tb);

        Page page = new Page();
        page.setUserId(userId);
        page.setPageTypeId(pageTypeId);
        page.setTitle("");
        page.setInkData("{\"strokes\":[]}");
        page.setTextLayers(gson.toJson(layers));
        page.setClosed(false);
        return page;
    }

    private PageType findBlankSystemType() throws SQLException {
        List<PageType> systemTypes = pageTypeDao.findSystemTypes();
        for (PageType pt : systemTypes) {
            if ("blank".equalsIgnoreCase(pt.getBackgroundType())) return pt;
        }
        // Fallback: first system type
        return systemTypes.isEmpty() ? null : systemTypes.get(0);
    }

    private List<Long> parseIdList(String raw) {
        List<Long> out = new ArrayList<>();
        if (raw == null || raw.isEmpty()) return out;
        for (String token : raw.split(",")) {
            String t = token.trim();
            if (t.isEmpty()) continue;
            try {
                out.add(Long.parseLong(t));
            } catch (NumberFormatException ignored) {
            }
        }
        return out;
    }

    private File saveToTempFile(Part part) throws IOException {
        String submitted = part.getSubmittedFileName();
        String ext = "";
        if (submitted != null) {
            int dot = submitted.lastIndexOf('.');
            if (dot > 0 && dot < submitted.length() - 1) {
                ext = submitted.substring(dot);
            }
        }
        if (ext.isEmpty()) ext = ".webm";
        Path temp = Files.createTempFile("jotpage-audio-", ext);
        try (InputStream in = part.getInputStream()) {
            Files.copy(in, temp, StandardCopyOption.REPLACE_EXISTING);
        }
        return temp.toFile();
    }

    private void markJobFailed(AiJob job, String msg) {
        if (job == null) return;
        try {
            aiJobDao.updateStatus(job.getId(), "failed", null, msg);
        } catch (SQLException e) {
            log("Failed to mark AiJob " + job.getId() + " failed: " + e.getMessage());
        }
    }

    private User requireUser(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return null;
        }
        return (User) session.getAttribute("user");
    }

    private String stringParam(HttpServletRequest req, String name, String fallback) {
        String v = req.getParameter(name);
        return v == null ? fallback : v;
    }

    private int intParam(HttpServletRequest req, String name, int fallback) {
        String v = req.getParameter(name);
        if (v == null || v.isEmpty()) return fallback;
        try {
            return Integer.parseInt(v.trim());
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    private static String safeMessage(Throwable t) {
        String m = t.getMessage();
        return m == null ? t.getClass().getSimpleName() : m;
    }

    private void writeJson(HttpServletResponse resp, int status, String body) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        resp.getWriter().write(body);
    }

    private void writeJsonError(HttpServletResponse resp, int status, String message)
            throws IOException {
        JsonObject err = new JsonObject();
        err.addProperty("success", false);
        err.addProperty("error", message);
        writeJson(resp, status, gson.toJson(err));
    }
}
