package com.jotpage.dao;

import com.jotpage.model.PageType;
import com.jotpage.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class PageTypeDao {

    private static final String SELECT_COLUMNS =
            "SELECT id, user_id, name, background_type, background_data, "
                    + "immutable_on_close, is_system, created_at FROM page_types";

    public List<PageType> findSystemTypes() throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE is_system = TRUE ORDER BY id";
        List<PageType> results = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                results.add(mapRow(rs));
            }
        }
        return results;
    }

    public List<PageType> findByUserId(long userId) throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE is_system = TRUE OR user_id = ? ORDER BY is_system DESC, id";
        List<PageType> results = new ArrayList<>();
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

    public PageType findById(long id) throws SQLException {
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

    public PageType create(PageType pt) throws SQLException {
        String sql = "INSERT INTO page_types "
                + "(user_id, name, background_type, background_data, immutable_on_close, is_system) "
                + "VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            if (pt.getUserId() == null) {
                ps.setNull(1, Types.BIGINT);
            } else {
                ps.setLong(1, pt.getUserId());
            }
            ps.setString(2, pt.getName());
            ps.setString(3, pt.getBackgroundType());
            ps.setString(4, pt.getBackgroundData());
            ps.setBoolean(5, pt.isImmutableOnClose());
            ps.setBoolean(6, pt.isSystem());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    pt.setId(keys.getLong(1));
                }
            }
        }
        return findById(pt.getId());
    }

    public void delete(long id, long userId) throws SQLException {
        String sql = "DELETE FROM page_types WHERE id = ? AND user_id = ? AND is_system = FALSE";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.setLong(2, userId);
            ps.executeUpdate();
        } catch (SQLException e) {
            // Foreign key violation: pages still reference this page_type.
            // MySQL reports SQLState 23000 and error code 1451 in this case.
            if ("23000".equals(e.getSQLState()) || e.getErrorCode() == 1451) {
                throw new TemplateInUseException(
                        "Template is still referenced by one or more pages", e);
            }
            throw e;
        }
    }

    private PageType mapRow(ResultSet rs) throws SQLException {
        PageType pt = new PageType();
        pt.setId(rs.getLong("id"));
        long userId = rs.getLong("user_id");
        pt.setUserId(rs.wasNull() ? null : userId);
        pt.setName(rs.getString("name"));
        pt.setBackgroundType(rs.getString("background_type"));
        pt.setBackgroundData(rs.getString("background_data"));
        pt.setImmutableOnClose(rs.getBoolean("immutable_on_close"));
        pt.setSystem(rs.getBoolean("is_system"));
        pt.setCreatedAt(rs.getTimestamp("created_at"));
        return pt;
    }
}
