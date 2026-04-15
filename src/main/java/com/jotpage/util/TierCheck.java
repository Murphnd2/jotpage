package com.jotpage.util;

import com.jotpage.model.User;

import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.ZoneId;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * Pure feature/limit gatekeeper for the free/pro tier split.
 *
 * Free tier limits:
 *   - Month 1 (the calendar month the user was created): unlimited pages
 *   - Month 2+: 20 pages per calendar month
 *   - 5 custom templates maximum
 *   - 1 AI processing trial per mode
 *   - No export/download
 *   - Verbatim voice transcription is free
 *   - Page deletion is allowed on all tiers
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
    public static final String FEATURE_EXPORT = "export";

    /** Monthly page cap for free users after their first calendar month. */
    public static final int FREE_MONTHLY_PAGE_LIMIT = 20;
    public static final int FREE_CUSTOM_TEMPLATE_LIMIT = 5;
    public static final int FREE_AI_TRIAL_PER_MODE = 1;

    /** Sentinel returned by {@link #getMonthlyPageLimit(User)} meaning "no cap". */
    public static final int UNLIMITED = -1;

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
            case FEATURE_EXPORT:
                return false;
            default:
                return true;
        }
    }

    /**
     * Returns true if the user is still within their first calendar month
     * (the month/year of their account creation matches the current month/year).
     * Users with no createdAt timestamp are treated as NOT in their first month.
     */
    public static boolean isInFirstMonth(User user) {
        if (user == null) return false;
        Timestamp createdAt = user.getCreatedAt();
        if (createdAt == null) return false;
        YearMonth created = YearMonth.from(
                createdAt.toLocalDateTime().toLocalDate());
        YearMonth now = YearMonth.from(LocalDate.now(ZoneId.systemDefault()));
        return created.equals(now);
    }

    /**
     * Returns the monthly page-creation cap for this user.
     *
     * @return {@link #UNLIMITED} (-1) for Pro users or free users still in their
     *         first calendar month; otherwise {@link #FREE_MONTHLY_PAGE_LIMIT}.
     */
    public static int getMonthlyPageLimit(User user) {
        if (isPro(user)) return UNLIMITED;
        if (isInFirstMonth(user)) return UNLIMITED;
        return FREE_MONTHLY_PAGE_LIMIT;
    }

    /**
     * Returns true if the user may create another page given the number of
     * pages they have already created in the current calendar month.
     */
    public static boolean canCreatePage(User user, int pagesCreatedThisMonth) {
        int limit = getMonthlyPageLimit(user);
        if (limit == UNLIMITED) return true;
        return pagesCreatedThisMonth < limit;
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
                return "You\u2019ve reached the " + FREE_MONTHLY_PAGE_LIMIT
                        + "-page monthly limit on the free tier. Upgrade to Jyrnyl Pro for unlimited pages.";
            case FEATURE_EXPORT:
                return "Export is a Jyrnyl Pro feature. Upgrade to download your pages.";
            default:
                return "This feature is only available on Jyrnyl Pro.";
        }
    }
}
