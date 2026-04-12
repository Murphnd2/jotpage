package com.jotpage.dao;

import com.jotpage.model.Page;
import com.jotpage.model.Tag;
import com.jotpage.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class PageTagDao {

    public void addTag(long pageId, long tagId) throws SQLException {
        String sql = "INSERT IGNORE INTO page_tags (page_id, tag_id) VALUES (?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, pageId);
            ps.setLong(2, tagId);
            ps.executeUpdate();
        }
    }

    public void removeTag(long pageId, long tagId) throws SQLException {
        String sql = "DELETE FROM page_tags WHERE page_id = ? AND tag_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, pageId);
            ps.setLong(2, tagId);
            ps.executeUpdate();
        }
    }

    public List<Tag> findTagsByPageId(long pageId) throws SQLException {
        String sql = "SELECT t.id, t.user_id, t.name, t.color, t.created_at "
                + "FROM tags t JOIN page_tags pt ON pt.tag_id = t.id "
                + "WHERE pt.page_id = ? ORDER BY t.name";
        List<Tag> results = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, pageId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    results.add(TagDao.mapRow(rs));
                }
            }
        }
        return results;
    }

    public List<Page> findPagesByTagId(long tagId, long userId) throws SQLException {
        String sql = "SELECT p.id, p.user_id, p.page_type_id, p.title, p.ink_data, p.text_layers, "
                + "p.is_closed, p.created_at, p.updated_at "
                + "FROM pages p JOIN page_tags pt ON pt.page_id = p.id "
                + "WHERE pt.tag_id = ? AND p.user_id = ? ORDER BY p.updated_at DESC";
        List<Page> results = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, tagId);
            ps.setLong(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Page p = new Page();
                    p.setId(rs.getLong("id"));
                    p.setUserId(rs.getLong("user_id"));
                    p.setPageTypeId(rs.getLong("page_type_id"));
                    p.setTitle(rs.getString("title"));
                    p.setInkData(rs.getString("ink_data"));
                    p.setTextLayers(rs.getString("text_layers"));
                    p.setClosed(rs.getBoolean("is_closed"));
                    p.setCreatedAt(rs.getTimestamp("created_at"));
                    p.setUpdatedAt(rs.getTimestamp("updated_at"));
                    results.add(p);
                }
            }
        }
        return results;
    }
}
