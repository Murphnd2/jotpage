package com.jotpage.dao;

import com.jotpage.model.Tag;
import com.jotpage.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class TagDao {

    private static final String SELECT_COLUMNS =
            "SELECT id, user_id, name, color, created_at FROM tags";

    public List<Tag> findByUserId(long userId) throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE user_id = ? ORDER BY name";
        List<Tag> results = new ArrayList<>();
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

    public Tag create(Tag tag) throws SQLException {
        String sql = "INSERT INTO tags (user_id, name, color) VALUES (?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, tag.getUserId());
            ps.setString(2, tag.getName());
            ps.setString(3, tag.getColor() == null ? "#6c757d" : tag.getColor());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    tag.setId(keys.getLong(1));
                }
            }
        }
        return findById(tag.getId(), tag.getUserId());
    }

    public void delete(long id, long userId) throws SQLException {
        String sql = "DELETE FROM tags WHERE id = ? AND user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.setLong(2, userId);
            ps.executeUpdate();
        }
    }

    private Tag findById(long id, long userId) throws SQLException {
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

    static Tag mapRow(ResultSet rs) throws SQLException {
        Tag t = new Tag();
        t.setId(rs.getLong("id"));
        t.setUserId(rs.getLong("user_id"));
        t.setName(rs.getString("name"));
        t.setColor(rs.getString("color"));
        t.setCreatedAt(rs.getTimestamp("created_at"));
        return t;
    }
}
