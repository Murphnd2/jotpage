package com.jotpage.dao;

import com.jotpage.model.Page;
import com.jotpage.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class PageDao {

    private static final String SELECT_COLUMNS =
            "SELECT id, user_id, page_type_id, title, sort_order, ink_data, text_layers, "
                    + "image_layers, is_closed, created_at, updated_at FROM pages";

    public Page findById(long id, long userId) throws SQLException {
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

    public List<Page> findByUserId(long userId) throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE user_id = ? ORDER BY sort_order ASC, created_at ASC";
        List<Page> results = new ArrayList<>();
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

    public List<Page> findByUserIdAndPageTypeId(long userId, long pageTypeId) throws SQLException {
        String sql = SELECT_COLUMNS
                + " WHERE user_id = ? AND page_type_id = ? ORDER BY sort_order ASC, created_at ASC";
        List<Page> results = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setLong(2, pageTypeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    results.add(mapRow(rs));
                }
            }
        }
        return results;
    }

    public Page create(Page page) throws SQLException {
        int nextOrder = nextSortOrder(page.getUserId());
        String sql = "INSERT INTO pages "
                + "(user_id, page_type_id, title, sort_order, ink_data, text_layers, is_closed) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, page.getUserId());
            ps.setLong(2, page.getPageTypeId());
            ps.setString(3, page.getTitle() == null ? "" : page.getTitle());
            ps.setInt(4, nextOrder);
            ps.setString(5, page.getInkData());
            ps.setString(6, page.getTextLayers());
            ps.setBoolean(7, page.isClosed());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    page.setId(keys.getLong(1));
                }
            }
        }
        return findById(page.getId(), page.getUserId());
    }

    private int nextSortOrder(long userId) throws SQLException {
        String sql = "SELECT COALESCE(MAX(sort_order), -1) + 1 FROM pages WHERE user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    public void update(Page page) throws SQLException {
        String checkSql = "SELECT p.is_closed, pt.immutable_on_close "
                + "FROM pages p JOIN page_types pt ON pt.id = p.page_type_id "
                + "WHERE p.id = ? AND p.user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement check = conn.prepareStatement(checkSql)) {
            check.setLong(1, page.getId());
            check.setLong(2, page.getUserId());
            try (ResultSet rs = check.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("Page not found or not owned by user");
                }
                boolean isClosed = rs.getBoolean("is_closed");
                boolean immutable = rs.getBoolean("immutable_on_close");
                if (isClosed && immutable) {
                    throw new SQLException("Page is closed and its page type is immutable on close");
                }
            }
        }

        String sql = "UPDATE pages SET ink_data = ?, text_layers = ?, image_layers = ?, is_closed = ? "
                + "WHERE id = ? AND user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, page.getInkData());
            ps.setString(2, page.getTextLayers());
            ps.setString(3, page.getImageLayers());
            ps.setBoolean(4, page.isClosed());
            ps.setLong(5, page.getId());
            ps.setLong(6, page.getUserId());
            ps.executeUpdate();
        }
    }

    public void reorder(long userId, List<Long> pageIdsInOrder) throws SQLException {
        if (pageIdsInOrder == null || pageIdsInOrder.isEmpty()) return;
        String sql = "UPDATE pages SET sort_order = ? WHERE id = ? AND user_id = ?";
        try (Connection conn = DbUtil.getConnection()) {
            boolean prevAuto = conn.getAutoCommit();
            conn.setAutoCommit(false);
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                for (int i = 0; i < pageIdsInOrder.size(); i++) {
                    ps.setInt(1, i);
                    ps.setLong(2, pageIdsInOrder.get(i));
                    ps.setLong(3, userId);
                    ps.addBatch();
                }
                ps.executeBatch();
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(prevAuto);
            }
        }
    }

    public void close(long id, long userId) throws SQLException {
        String sql = "UPDATE pages SET is_closed = TRUE WHERE id = ? AND user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.setLong(2, userId);
            ps.executeUpdate();
        }
    }

    public int countByUserId(long userId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM pages WHERE user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public void delete(long id, long userId) throws SQLException {
        String sql = "DELETE FROM pages WHERE id = ? AND user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.setLong(2, userId);
            ps.executeUpdate();
        }
    }

    private Page mapRow(ResultSet rs) throws SQLException {
        Page p = new Page();
        p.setId(rs.getLong("id"));
        p.setUserId(rs.getLong("user_id"));
        p.setPageTypeId(rs.getLong("page_type_id"));
        p.setTitle(rs.getString("title"));
        p.setSortOrder(rs.getInt("sort_order"));
        p.setInkData(rs.getString("ink_data"));
        p.setTextLayers(rs.getString("text_layers"));
        p.setImageLayers(rs.getString("image_layers"));
        p.setClosed(rs.getBoolean("is_closed"));
        p.setCreatedAt(rs.getTimestamp("created_at"));
        p.setUpdatedAt(rs.getTimestamp("updated_at"));
        return p;
    }
}
