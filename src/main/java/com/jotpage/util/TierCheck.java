package com.jotpage.util;

import com.jotpage.model.User;

/**
 * Pure feature/limit gatekeeper for the free/pro tier split.
 *
 * Free tier limits:
 *   - 50 pages maximum
 *   - No AI processing (Claude / LLM features)
 *   - No Whisper transcription
 *   - Only system page templates (no custom PNG templates)
 *
 * Pro tier: everything unlimited.
 *
 * This class intentionally has no database access — callers pass the already
 * loaded User and we inspect the tier string. Usage limits (page count,
 * monthly caps) are enforced at the servlet layer using UsageDao.
 */
public final class TierCheck {

    public static final String FEATURE_WHISPER = "whisper_transcription";
    public static final String FEATURE_AI_PROCESSING = "ai_processing";
    public static final String FEATURE_CUSTOM_TEMPLATES = "custom_templates";
    public static final String FEATURE_UNLIMITED_PAGES = "unlimited_pages";

    public static final int FREE_PAGE_LIMIT = 50;

    private TierCheck() {
    }

    public static boolean isPro(User user) {
        return user != null && "pro".equalsIgnoreCase(user.getTier());
    }

    public static boolean isFeatureAllowed(User user, String feature) {
        if (user == null || feature == null) return false;
        // Pro gets everything.
        if (isPro(user)) return true;

        // Free tier explicit allow list — currently empty, all Pro-exclusive
        // features return false. Listed here for clarity.
        switch (feature) {
            case FEATURE_WHISPER:
            case FEATURE_AI_PROCESSING:
            case FEATURE_CUSTOM_TEMPLATES:
            case FEATURE_UNLIMITED_PAGES:
                return false;
            default:
                // Unknown feature — default to allow so future free-tier
                // additions don't accidentally get blocked by a typo.
                return true;
        }
    }

    public static int getPageLimit(User user) {
        return isPro(user) ? Integer.MAX_VALUE : FREE_PAGE_LIMIT;
    }

    /**
     * Convenience for servlet code: returns null if the feature is allowed,
     * or a user-facing error message explaining that Pro is required.
     */
    public static String requirePro(User user, String feature) {
        if (isFeatureAllowed(user, feature)) return null;
        switch (feature) {
            case FEATURE_WHISPER:
                return "Audio transcription is a Pro feature. Upgrade to transcribe recordings.";
            case FEATURE_AI_PROCESSING:
                return "AI processing is a Pro feature. Upgrade to run notes through the AI pipeline.";
            case FEATURE_CUSTOM_TEMPLATES:
                return "Custom templates are a Pro feature. Upgrade to upload your own backgrounds.";
            case FEATURE_UNLIMITED_PAGES:
                return "You've reached the " + FREE_PAGE_LIMIT
                        + "-page limit on the free tier. Upgrade to Pro for unlimited pages.";
            default:
                return "This feature is only available on Pro. Upgrade to unlock it.";
        }
    }
}
