package com.jotpage.dao;

import com.jotpage.model.User;
import com.jotpage.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class UserDao {

    private static final String SELECT_COLUMNS =
            "SELECT id, google_id, email, display_name, avatar_url, tier, "
                    + "created_at, updated_at FROM users";

    public User findByGoogleId(String googleId) throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE google_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, googleId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
                return null;
            }
        }
    }

    public User createOrUpdate(String googleId, String email, String displayName, String avatarUrl)
            throws SQLException {
        User existing = findByGoogleId(googleId);
        if (existing == null) {
            // New user — tier defaults to 'free' via the column default, we don't set it here.
            String insert = "INSERT INTO users (google_id, email, display_name, avatar_url) "
                    + "VALUES (?, ?, ?, ?)";
            try (Connection conn = DbUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(insert, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, googleId);
                ps.setString(2, email);
                ps.setString(3, displayName);
                ps.setString(4, avatarUrl);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) {
                        long id = keys.getLong(1);
                        return findById(id);
                    }
                }
            }
            return findByGoogleId(googleId);
        } else {
            // Update profile-ish fields only — tier is managed separately via updateTier.
            String update = "UPDATE users SET email = ?, display_name = ?, avatar_url = ? "
                    + "WHERE google_id = ?";
            try (Connection conn = DbUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(update)) {
                ps.setString(1, email);
                ps.setString(2, displayName);
                ps.setString(3, avatarUrl);
                ps.setString(4, googleId);
                ps.executeUpdate();
            }
            return findByGoogleId(googleId);
        }
    }

    public void updateTier(long userId, String tier) throws SQLException {
        if (!"free".equals(tier) && !"pro".equals(tier)) {
            throw new SQLException("invalid tier: " + tier);
        }
        String sql = "UPDATE users SET tier = ? WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tier);
            ps.setLong(2, userId);
            ps.executeUpdate();
        }
    }

    private User findById(long id) throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
                return null;
            }
        }
    }

    private User mapRow(ResultSet rs) throws SQLException {
        User u = new User();
        u.setId(rs.getLong("id"));
        u.setGoogleId(rs.getString("google_id"));
        u.setEmail(rs.getString("email"));
        u.setDisplayName(rs.getString("display_name"));
        u.setAvatarUrl(rs.getString("avatar_url"));
        String tier = rs.getString("tier");
        u.setTier(tier == null ? "free" : tier);
        u.setCreatedAt(rs.getTimestamp("created_at"));
        u.setUpdatedAt(rs.getTimestamp("updated_at"));
        return u;
    }
}
