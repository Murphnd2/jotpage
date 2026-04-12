package com.jotpage.dao;

import com.jotpage.model.AiJob;
import com.jotpage.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class AiJobDao {

    private static final String SELECT_COLUMNS =
            "SELECT id, user_id, job_type, status, input_text, output_text, "
                    + "audio_file_path, custom_prompt, error_message, "
                    + "created_at, updated_at FROM ai_jobs";

    public AiJob create(AiJob job) throws SQLException {
        if (job == null) return null;
        String sql = "INSERT INTO ai_jobs "
                + "(user_id, job_type, status, input_text, audio_file_path, custom_prompt) "
                + "VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, job.getUserId());
            ps.setString(2, job.getJobType());
            ps.setString(3, job.getStatus() == null ? "pending" : job.getStatus());
            setStringOrNull(ps, 4, job.getInputText());
            setStringOrNull(ps, 5, job.getAudioFilePath());
            setStringOrNull(ps, 6, job.getCustomPrompt());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    job.setId(keys.getLong(1));
                }
            }
        }
        return findById(job.getId(), job.getUserId());
    }

    public AiJob findById(long id, long userId) throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE id = ? AND user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.setLong(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
                return null;
            }
        }
    }

    public void updateStatus(long id, String status, String outputText, String errorMessage)
            throws SQLException {
        String sql = "UPDATE ai_jobs SET status = ?, output_text = ?, error_message = ? "
                + "WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            setStringOrNull(ps, 2, outputText);
            setStringOrNull(ps, 3, errorMessage);
            ps.setLong(4, id);
            ps.executeUpdate();
        }
    }

    public List<AiJob> findByUserId(long userId) throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE user_id = ? ORDER BY created_at DESC LIMIT 50";
        List<AiJob> results = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    results.add(mapRow(rs));
                }
            }
        }
        return results;
    }

    public int countByUserIdAndJobType(long userId, String jobType) throws SQLException {
        String sql = "SELECT COUNT(*) FROM ai_jobs WHERE user_id = ? AND job_type = ? "
                + "AND status IN ('complete','processing')";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setString(2, jobType);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private AiJob mapRow(ResultSet rs) throws SQLException {
        AiJob j = new AiJob();
        j.setId(rs.getLong("id"));
        j.setUserId(rs.getLong("user_id"));
        j.setJobType(rs.getString("job_type"));
        j.setStatus(rs.getString("status"));
        j.setInputText(rs.getString("input_text"));
        j.setOutputText(rs.getString("output_text"));
        j.setAudioFilePath(rs.getString("audio_file_path"));
        j.setCustomPrompt(rs.getString("custom_prompt"));
        j.setErrorMessage(rs.getString("error_message"));
        j.setCreatedAt(rs.getTimestamp("created_at"));
        j.setUpdatedAt(rs.getTimestamp("updated_at"));
        return j;
    }

    private void setStringOrNull(PreparedStatement ps, int idx, String value) throws SQLException {
        if (value == null) {
            ps.setNull(idx, Types.LONGVARCHAR);
        } else {
            ps.setString(idx, value);
        }
    }
}
