package com.jotpage.listener;

import com.jotpage.util.DbUtil;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

@WebListener
public class AppStartupListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        String sql = "UPDATE ai_jobs SET status = 'failed', "
                + "error_message = 'Recovered: server restarted while processing' "
                + "WHERE status IN ('processing', 'pending')";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            int rows = ps.executeUpdate();
            System.out.println("[AppStartupListener] Recovered " + rows
                    + " stuck ai_job(s) to failed status.");
        } catch (SQLException e) {
            System.out.println("[AppStartupListener] WARNING: could not recover stuck ai_jobs: "
                    + e.getMessage());
        }
    }
}
