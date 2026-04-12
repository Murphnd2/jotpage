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

    public void update(Tag tag) throws SQLException {
        String sql = "UPDATE tags SET name = ?, color = ? WHERE id = ? AND user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tag.getName());
            ps.setString(2, tag.getColor() == null ? "#6c757d" : tag.getColor());
            ps.setLong(3, tag.getId());
            ps.setLong(4, tag.getUserId());
            ps.executeUpdate();
        }
    }

    public int countPages(long tagId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM page_tags WHERE tag_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, tagId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    /**
     * Replace all occurrences of oldTagId with newTagId on pages owned by userId,
     * then delete oldTag. Uses INSERT IGNORE so pages that already have newTag
     * don't get duplicates.
     */
    public void replaceTag(long oldTagId, long newTagId, long userId) throws SQLException {
        try (Connection conn = DbUtil.getConnection()) {
            boolean prevAuto = conn.getAutoCommit();
            conn.setAutoCommit(false);
            try {
                // Add newTag to all pages that have oldTag (skip if already present)
                String insertSql = "INSERT IGNORE INTO page_tags (page_id, tag_id) "
                        + "SELECT pt.page_id, ? FROM page_tags pt "
                        + "JOIN pages p ON p.id = pt.page_id "
                        + "WHERE pt.tag_id = ? AND p.user_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                    ps.setLong(1, newTagId);
                    ps.setLong(2, oldTagId);
                    ps.setLong(3, userId);
                    ps.executeUpdate();
                }
                // Delete old tag (CASCADE removes remaining page_tags rows)
                String delSql = "DELETE FROM tags WHERE id = ? AND user_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(delSql)) {
                    ps.setLong(1, oldTagId);
                    ps.setLong(2, userId);
                    ps.executeUpdate();
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(prevAuto);
            }
        }
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
