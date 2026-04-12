package com.jotpage.util;

import java.sql.Connection;
import java.sql.SQLException;

import com.mysql.cj.jdbc.MysqlDataSource;

/**
 * Simple JDBC connection utility. Reads all {@code db.*} keys from
 * {@link AppConfig} and hands out connections from a MySQL DataSource.
 *
 * Previous versions used a JNDI DataSource configured in
 * {@code META-INF/context.xml}. This version reads from the external
 * {@code jotpage.properties} file instead, so credentials stay out of the
 * WAR and the repo.
 */
public class DbUtil {

    private static volatile MysqlDataSource dataSource;

    private DbUtil() {
    }

    private static MysqlDataSource getDataSource() {
        if (dataSource != null) return dataSource;
        synchronized (DbUtil.class) {
            if (dataSource != null) return dataSource;

            String url = AppConfig.get("db.url");
            String user = AppConfig.get("db.username");
            String pass = AppConfig.get("db.password");

            if (url == null || url.isEmpty()) {
                throw new RuntimeException(
                        "[DbUtil] db.url is not configured in jotpage.properties");
            }

            MysqlDataSource ds = new MysqlDataSource();
            ds.setUrl(url);
            if (user != null) ds.setUser(user);
            if (pass != null) ds.setPassword(pass);

            System.out.println("[DbUtil] DataSource configured for "
                    + url.replaceAll("password=[^&]*", "password=***"));

            dataSource = ds;
        }
        return dataSource;
    }

    public static Connection getConnection() throws SQLException {
        return getDataSource().getConnection();
    }
}
