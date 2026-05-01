package com.jotpage.servlet;

import com.jotpage.dao.BlogPostDao;
import com.jotpage.model.BlogPost;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/blog/*")
public class BlogServlet extends HttpServlet {

    private final BlogPostDao blogPostDao = new BlogPostDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();

        if (pathInfo == null || pathInfo.equals("/")) {
            showList(req, resp);
        } else {
            String slug = pathInfo.substring(1); // strip leading /
            showPost(req, resp, slug);
        }
    }

    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            List<BlogPost> posts = blogPostDao.listPublished();
            req.setAttribute("posts", posts);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        req.getRequestDispatcher("/jsp/blog-list.jsp").forward(req, resp);
    }

    private void showPost(HttpServletRequest req, HttpServletResponse resp, String slug)
            throws ServletException, IOException {
        BlogPost post;
        try {
            post = blogPostDao.findBySlug(slug);
        } catch (SQLException e) {
            throw new ServletException(e);
        }

        if (post == null || !"published".equals(post.getStatus())) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        req.setAttribute("post", post);
        req.getRequestDispatcher("/jsp/blog-post.jsp").forward(req, resp);
    }
}
