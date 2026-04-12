package com.jotpage.dao;

import com.jotpage.model.UsageRecord;
import com.jotpage.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.Date;

public class UsageDao {

    private static final String SELECT_COLUMNS =
            "SELECT id, user_id, month_year, pages_created, ai_jobs_run, "
                    + "audio_minutes_processed, created_at, updated_at FROM usage_tracking";

    public UsageRecord findOrCreateCurrentMonth(long userId) throws SQLException {
        String month = currentMonthYear();
        UsageRecord existing = findByUserAndMonth(userId, month);
        if (existing != null) return existing;

        // Create a new row. Use INSERT IGNORE for idempotency in case another
        // thread raced us and won.
        String insert = "INSERT IGNORE INTO usage_tracking (user_id, month_year) VALUES (?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(insert, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, userId);
            ps.setString(2, month);
            ps.executeUpdate();
        }
        return findByUserAndMonth(userId, month);
    }

    public void incrementPages(long userId, int count) throws SQLException {
        upsertAndIncrement(userId, "pages_created", (double) count);
    }

    public void incrementAiJobs(long userId) throws SQLException {
        upsertAndIncrement(userId, "ai_jobs_run", 1.0);
    }

    public void incrementAudioMinutes(long userId, double minutes) throws SQLException {
        upsertAndIncrement(userId, "audio_minutes_processed", minutes);
    }

    /**
     * Atomic upsert-and-increment for a single numeric column. Makes sure a
     * row exists for the current month before adding to it.
     *
     * The column name is NEVER user-supplied — all callers pass string
     * literals — so we can safely splice it into the SQL.
     */
    private void upsertAndIncrement(long userId, String column, double delta) throws SQLException {
        String month = currentMonthYear();
        // Single statement: insert row if missing, else add delta to the column.
        String sql = "INSERT INTO usage_tracking (user_id, month_year, " + column + ") "
                + "VALUES (?, ?, ?) "
                + "ON DUPLICATE KEY UPDATE " + column + " = " + column + " + VALUES(" + column + ")";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setString(2, month);
            ps.setDouble(3, delta);
            ps.executeUpdate();
        }
    }

    private UsageRecord findByUserAndMonth(long userId, String monthYear) throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE user_id = ? AND month_year = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setString(2, monthYear);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
                return null;
            }
        }
    }

    private UsageRecord mapRow(ResultSet rs) throws SQLException {
        UsageRecord u = new UsageRecord();
        u.setId(rs.getLong("id"));
        u.setUserId(rs.getLong("user_id"));
        u.setMonthYear(rs.getString("month_year"));
        u.setPagesCreated(rs.getInt("pages_created"));
        u.setAiJobsRun(rs.getInt("ai_jobs_run"));
        u.setAudioMinutesProcessed(rs.getDouble("audio_minutes_processed"));
        u.setCreatedAt(rs.getTimestamp("created_at"));
        u.setUpdatedAt(rs.getTimestamp("updated_at"));
        return u;
    }

    private String currentMonthYear() {
        return new SimpleDateFormat("yyyy-MM").format(new Date());
    }
}
