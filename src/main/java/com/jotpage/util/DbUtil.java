package com.jotpage.util;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Simple JDBC connection utility that obtains connections from the
 * JNDI DataSource "jdbc/jotpage" configured in context.xml.
 */
public class DbUtil {

    private static final String JNDI_NAME = "java:comp/env/jdbc/jotpage";

    private static DataSource dataSource;

    private DbUtil() {
    }

    private static synchronized DataSource getDataSource() throws NamingException {
        if (dataSource == null) {
            Context initCtx = new InitialContext();
            dataSource = (DataSource) initCtx.lookup(JNDI_NAME);
        }
        return dataSource;
    }

    public static Connection getConnection() throws SQLException {
        try {
            return getDataSource().getConnection();
        } catch (NamingException e) {
            throw new SQLException("Unable to look up JNDI DataSource " + JNDI_NAME, e);
        }
    }
}
