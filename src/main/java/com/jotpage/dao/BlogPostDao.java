package com.jotpage.dao;

import com.jotpage.model.BlogPost;
import com.jotpage.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class BlogPostDao {

    private static final String SELECT_COLUMNS =
            "SELECT id, slug, title, summary, body, author_name, status, "
                    + "published_at, created_at, updated_at FROM blog_posts";

    public BlogPost findById(long id) throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    public BlogPost findBySlug(String slug) throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE slug = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, slug);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    public List<BlogPost> listPublished() throws SQLException {
        String sql = SELECT_COLUMNS
                + " WHERE status = 'published' ORDER BY published_at DESC";
        List<BlogPost> results = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                results.add(mapRow(rs));
            }
        }
        return results;
    }

    public List<BlogPost> listAll() throws SQLException {
        String sql = SELECT_COLUMNS + " ORDER BY updated_at DESC";
        List<BlogPost> results = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                results.add(mapRow(rs));
            }
        }
        return results;
    }

    public long create(BlogPost post) throws SQLException {
        String sql = "INSERT INTO blog_posts "
                + "(slug, title, summary, body, author_name, status, published_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, post.getSlug());
            ps.setString(2, post.getTitle());
            ps.setString(3, post.getSummary());
            ps.setString(4, post.getBody());
            ps.setString(5, post.getAuthorName() != null ? post.getAuthorName() : "Kevin Murphy");
            ps.setString(6, post.getStatus() != null ? post.getStatus() : "draft");
            ps.setTimestamp(7, post.getPublishedAt());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getLong(1);
                }
            }
        }
        return -1;
    }

    public void update(BlogPost post) throws SQLException {
        String sql = "UPDATE blog_posts "
                + "SET slug = ?, title = ?, summary = ?, body = ?, author_name = ?, "
                + "status = ?, published_at = ? "
                + "WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, post.getSlug());
            ps.setString(2, post.getTitle());
            ps.setString(3, post.getSummary());
            ps.setString(4, post.getBody());
            ps.setString(5, post.getAuthorName() != null ? post.getAuthorName() : "Kevin Murphy");
            ps.setString(6, post.getStatus());
            ps.setTimestamp(7, post.getPublishedAt());
            ps.setLong(8, post.getId());
            ps.executeUpdate();
        }
    }

    public void delete(long id) throws SQLException {
        String sql = "DELETE FROM blog_posts WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.executeUpdate();
        }
    }

    private BlogPost mapRow(ResultSet rs) throws SQLException {
        BlogPost p = new BlogPost();
        p.setId(rs.getLong("id"));
        p.setSlug(rs.getString("slug"));
        p.setTitle(rs.getString("title"));
        p.setSummary(rs.getString("summary"));
        p.setBody(rs.getString("body"));
        p.setAuthorName(rs.getString("author_name"));
        p.setStatus(rs.getString("status"));
        p.setPublishedAt(rs.getTimestamp("published_at"));
        p.setCreatedAt(rs.getTimestamp("created_at"));
        p.setUpdatedAt(rs.getTimestamp("updated_at"));
        return p;
    }
}
