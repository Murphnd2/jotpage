package com.jotpage.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Centralized configuration loader for JotPage.
 *
 * Loads a single {@code jotpage.properties} file once on first access and
 * exposes its values via static {@link #get(String)} / {@link #get(String,String)}.
 *
 * <h3>Lookup order</h3>
 * <ol>
 *   <li>System property {@code -Djotpage.config=/custom/path/jotpage.properties}</li>
 *   <li>Fallback: {@code {catalina.base}/conf/jotpage.properties}</li>
 *   <li>Fallback: classpath resource {@code jotpage.properties} (dev / tests)</li>
 * </ol>
 *
 * This mirrors the pattern already used by the SSA application on the same
 * production server ({@code ssa.properties} in {@code {catalina.base}/conf/}).
 */
public final class AppConfig {

    private static final String FILE_NAME = "jotpage.properties";
    private static final String SYS_PROP = "jotpage.config";

    private static volatile Properties props;

    private AppConfig() {
    }

    /**
     * Returns the value for the given key, or {@code null} if not found.
     */
    public static String get(String key) {
        return getProps().getProperty(key);
    }

    /**
     * Returns the value for the given key, or {@code defaultValue} if not found.
     */
    public static String get(String key, String defaultValue) {
        return getProps().getProperty(key, defaultValue);
    }

    /**
     * Returns the value for the given key as an int, or {@code defaultValue}
     * if not found or not parseable.
     */
    public static int getInt(String key, int defaultValue) {
        String v = get(key);
        if (v == null || v.trim().isEmpty()) return defaultValue;
        try {
            return Integer.parseInt(v.trim());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    // ------------------------------------------------------------------
    // Lazy init
    // ------------------------------------------------------------------
    private static Properties getProps() {
        if (props != null) return props;
        synchronized (AppConfig.class) {
            if (props != null) return props;
            props = load();
        }
        return props;
    }

    private static Properties load() {
        Properties p = new Properties();

        // 1. Explicit system property
        String explicit = System.getProperty(SYS_PROP);
        if (explicit != null && !explicit.isEmpty()) {
            File f = new File(explicit);
            if (f.isFile()) {
                loadFrom(p, f, "system property -D" + SYS_PROP);
                return p;
            }
            System.err.println("[AppConfig] WARNING: -D" + SYS_PROP + "="
                    + explicit + " does not exist or is not a file");
        }

        // 2. {catalina.base}/conf/jotpage.properties
        String catalinaBase = System.getProperty("catalina.base");
        if (catalinaBase != null && !catalinaBase.isEmpty()) {
            File f = new File(catalinaBase, "conf" + File.separator + FILE_NAME);
            if (f.isFile()) {
                loadFrom(p, f, "catalina.base/conf/" + FILE_NAME);
                return p;
            }
        }

        // 3. Classpath (src/main/resources during dev, WEB-INF/classes in WAR)
        try (InputStream in = AppConfig.class.getClassLoader()
                .getResourceAsStream(FILE_NAME)) {
            if (in != null) {
                p.load(in);
                System.out.println("[AppConfig] Loaded from classpath: " + FILE_NAME);
                return p;
            }
        } catch (IOException e) {
            System.err.println("[AppConfig] Failed to read classpath " + FILE_NAME + ": " + e);
        }

        System.err.println("[AppConfig] WARNING: No " + FILE_NAME + " found. "
                + "Checked: -D" + SYS_PROP + ", {catalina.base}/conf/, classpath. "
                + "All config values will return null.");
        return p;
    }

    private static void loadFrom(Properties p, File f, String label) {
        try (FileInputStream fis = new FileInputStream(f)) {
            p.load(fis);
            System.out.println("[AppConfig] Loaded from " + label + ": "
                    + f.getAbsolutePath()
                    + " (" + p.size() + " keys)");
        } catch (IOException e) {
            System.err.println("[AppConfig] Failed to read " + f.getAbsolutePath()
                    + ": " + e);
        }
    }
}
