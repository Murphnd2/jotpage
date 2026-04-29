package com.jotpage.util;

/**
 * Immutable result from a ClaudeService.process() call.
 * Carries the assistant response text alongside the token counts
 * reported by the Anthropic API so callers can log or store usage.
 * inputTokens / outputTokens are -1 when the API response omits the
 * usage field (defensive default).
 */
public final class ClaudeResult {

    private final String text;
    private final int inputTokens;
    private final int outputTokens;

    public ClaudeResult(String text, int inputTokens, int outputTokens) {
        this.text = text;
        this.inputTokens = inputTokens;
        this.outputTokens = outputTokens;
    }

    public String getText() {
        return text;
    }

    public int getInputTokens() {
        return inputTokens;
    }

    public int getOutputTokens() {
        return outputTokens;
    }
}
