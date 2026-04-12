package com.jotpage.util;

import com.jotpage.model.User;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * Pure feature/limit gatekeeper for the free/pro tier split.
 *
 * Free tier limits:
 *   - 50 pages maximum (lifetime)
 *   - 5 custom templates maximum
 *   - 1 AI processing trial per mode
 *   - No page deletion
 *   - No export/download
 *   - Verbatim voice transcription is free
 *
 * Pro tier: everything unlimited.
 *
 * A comma-separated {@code pro.emails} property in jotpage.properties
 * overrides the database tier for listed email addresses.
 */
public final class TierCheck {

    public static final String FEATURE_WHISPER = "whisper_transcription";
    public static final String FEATURE_AI_PROCESSING = "ai_processing";
    public static final String FEATURE_CUSTOM_TEMPLATES = "custom_templates";
    public static final String FEATURE_UNLIMITED_PAGES = "unlimited_pages";
    public static final String FEATURE_DELETE = "delete_page";
    public static final String FEATURE_EXPORT = "export";

    public static final int FREE_PAGE_LIMIT = 50;
    public static final int FREE_CUSTOM_TEMPLATE_LIMIT = 5;
    public static final int FREE_AI_TRIAL_PER_MODE = 1;

    private static volatile Set<String> proEmails;

    private TierCheck() {
    }

    public static boolean isPro(User user) {
        if (user == null) return false;
        if ("pro".equalsIgnoreCase(user.getTier())) return true;
        // Check properties-file whitelist
        return user.getEmail() != null
                && getProEmails().contains(user.getEmail().toLowerCase());
    }

    private static Set<String> getProEmails() {
        if (proEmails != null) return proEmails;
        String raw = AppConfig.get("pro.emails", "");
        Set<String> set = new HashSet<>();
        for (String e : raw.split(",")) {
            String trimmed = e.trim().toLowerCase();
            if (!trimmed.isEmpty()) set.add(trimmed);
        }
        proEmails = Collections.unmodifiableSet(set);
        return proEmails;
    }

    public static boolean isFeatureAllowed(User user, String feature) {
        if (user == null || feature == null) return false;
        if (isPro(user)) return true;

        switch (feature) {
            case FEATURE_WHISPER:
            case FEATURE_AI_PROCESSING:
            case FEATURE_CUSTOM_TEMPLATES:
            case FEATURE_UNLIMITED_PAGES:
            case FEATURE_DELETE:
            case FEATURE_EXPORT:
                return false;
            default:
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
                return "Audio transcription is a Jyrnyl Pro feature. Upgrade to transcribe recordings.";
            case FEATURE_AI_PROCESSING:
                return "You\u2019ve used your free trial of this mode. Upgrade to Jyrnyl Pro for unlimited use.";
            case FEATURE_CUSTOM_TEMPLATES:
                return "You\u2019ve reached the " + FREE_CUSTOM_TEMPLATE_LIMIT
                        + "-template limit on the free tier. Upgrade to Jyrnyl Pro for unlimited templates.";
            case FEATURE_UNLIMITED_PAGES:
                return "You\u2019ve reached the " + FREE_PAGE_LIMIT
                        + "-page limit on the free tier. Upgrade to Jyrnyl Pro for unlimited pages.";
            case FEATURE_DELETE:
                return "Page deletion is a Jyrnyl Pro feature. Upgrade to delete pages.";
            case FEATURE_EXPORT:
                return "Export is a Jyrnyl Pro feature. Upgrade to download your pages.";
            default:
                return "This feature is only available on Jyrnyl Pro.";
        }
    }
}
