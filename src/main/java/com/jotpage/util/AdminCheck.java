package com.jotpage.util;

import com.jotpage.model.User;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * Gate for admin-only features. Reads the comma-separated {@code admin.emails}
 * property from jotpage.properties and caches it on first call.
 *
 * Usage: AdminCheck.isAdmin(user)
 */
public final class AdminCheck {

    private static volatile Set<String> adminEmails;

    private AdminCheck() {
    }

    public static boolean isAdmin(User user) {
        if (user == null) return false;
        return user.getEmail() != null
                && getAdminEmails().contains(user.getEmail().toLowerCase());
    }

    private static Set<String> getAdminEmails() {
        if (adminEmails != null) return adminEmails;
        String raw = AppConfig.get("admin.emails", "");
        Set<String> set = new HashSet<>();
        for (String e : raw.split(",")) {
            String trimmed = e.trim().toLowerCase();
            if (!trimmed.isEmpty()) set.add(trimmed);
        }
        adminEmails = Collections.unmodifiableSet(set);
        return adminEmails;
    }
}
