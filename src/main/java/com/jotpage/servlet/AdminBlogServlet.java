package com.jotpage.servlet;

import com.jotpage.dao.BlogPostDao;
import com.jotpage.model.BlogPost;
import com.jotpage.model.User;
import com.jotpage.util.AdminCheck;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.List;

@WebServlet("/app/admin/blog/*")
public class AdminBlogServlet extends HttpServlet {

    private final BlogPostDao blogPostDao = new BlogPostDao();

    // ------------------------------------------------------------------
    // Auth gate — applied at the top of every handler
    // ------------------------------------------------------------------
    private User requireAdmin(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        if (!AdminCheck.isAdmin(user)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN);
            return null;
        }
        return user;
    }

    // ------------------------------------------------------------------
    // GET
    // ------------------------------------------------------------------
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (requireAdmin(req, resp) == null) return;

        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.equals("/")) {
            showList(req, resp);
        } else if (pathInfo.equals("/new")) {
            showEditForm(req, resp, null);
        } else if (pathInfo.startsWith("/edit/")) {
            String idStr = pathInfo.substring("/edit/".length());
            showEditFormById(req, resp, idStr);
        } else {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            List<BlogPost> posts = blogPostDao.listAll();
            req.setAttribute("posts", posts);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        req.getRequestDispatcher("/jsp/admin-blog-list.jsp").forward(req, resp);
    }

    private void showEditFormById(HttpServletRequest req, HttpServletResponse resp,
            String idStr) throws ServletException, IOException {
        long id;
        try {
            id = Long.parseLong(idStr);
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        BlogPost post;
        try {
            post = blogPostDao.findById(id);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        if (post == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        showEditForm(req, resp, post);
    }

    private void showEditForm(HttpServletRequest req, HttpServletResponse resp,
            BlogPost post) throws ServletException, IOException {
        req.setAttribute("post", post); // null for new post
        req.getRequestDispatcher("/jsp/admin-blog-edit.jsp").forward(req, resp);
    }

    // ------------------------------------------------------------------
    // POST
    // ------------------------------------------------------------------
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (requireAdmin(req, resp) == null) return;

        String pathInfo = req.getPathInfo();
        if (pathInfo != null && pathInfo.startsWith("/delete/")) {
            String idStr = pathInfo.substring("/delete/".length());
            handleDelete(req, resp, idStr);
        } else {
            handleSave(req, resp);
        }
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp,
            String idStr) throws ServletException, IOException {
        long id;
        try {
            id = Long.parseLong(idStr);
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        try {
            blogPostDao.delete(id);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        resp.sendRedirect(req.getContextPath() + "/app/admin/blog");
    }

    private void handleSave(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String idParam = req.getParameter("id");
        String action  = req.getParameter("action");

        String title      = trimOrEmpty(req.getParameter("title"));
        String slug       = trimOrEmpty(req.getParameter("slug"));
        String summary    = trimOrEmpty(req.getParameter("summary"));
        String body       = trimOrEmpty(req.getParameter("body"));
        String authorName = trimOrEmpty(req.getParameter("authorName"));
        if (authorName.isEmpty()) authorName = "Kevin Murphy";

        try {
            if (idParam != null && !idParam.isBlank()) {
                // --- Update existing ---
                long id = Long.parseLong(idParam.trim());
                BlogPost post = blogPostDao.findById(id);
                if (post == null) {
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    return;
                }
                post.setTitle(title);
                post.setSlug(slug);
                post.setSummary(summary.isEmpty() ? null : summary);
                post.setBody(body);
                post.setAuthorName(authorName);
                applyAction(post, action);
                blogPostDao.update(post);
            } else {
                // --- Create new ---
                BlogPost post = new BlogPost();
                post.setTitle(title);
                post.setSlug(slug);
                post.setSummary(summary.isEmpty() ? null : summary);
                post.setBody(body);
                post.setAuthorName(authorName);
                post.setStatus("draft");
                applyAction(post, action);
                blogPostDao.create(post);
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }

        resp.sendRedirect(req.getContextPath() + "/app/admin/blog");
    }

    private void applyAction(BlogPost post, String action) {
        if ("publish".equals(action)) {
            post.setStatus("published");
            if (post.getPublishedAt() == null) {
                post.setPublishedAt(new Timestamp(System.currentTimeMillis()));
            }
        } else if ("unpublish".equals(action)) {
            post.setStatus("draft");
        } else {
            // "save" or anything else — keep current status; default draft for new posts
            if (post.getStatus() == null) {
                post.setStatus("draft");
            }
        }
    }

    private static String trimOrEmpty(String s) {
        return s == null ? "" : s.trim();
    }
}
