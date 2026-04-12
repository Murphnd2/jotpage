package com.jotpage.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import com.jotpage.dao.PageDao;
import com.jotpage.dao.PageTagDao;
import com.jotpage.model.Page;
import com.jotpage.model.Tag;
import com.jotpage.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.BufferedReader;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.stream.Collectors;

@WebServlet("/app/api/page-tags/*")
public class PageTagServlet extends HttpServlet {

    private final PageDao pageDao = new PageDao();
    private final PageTagDao pageTagDao = new PageTagDao();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = requireUser(req, resp);
        if (user == null) return;

        long[] parts = parsePath(req, resp, 1);
        if (parts == null) return;
        long pageId = parts[0];

        try {
            if (!ownsPage(user, pageId)) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            List<Tag> tags = pageTagDao.findTagsByPageId(pageId);
            writeJson(resp, HttpServletResponse.SC_OK, gson.toJson(tags));
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = requireUser(req, resp);
        if (user == null) return;

        long[] parts = parsePath(req, resp, 1);
        if (parts == null) return;
        long pageId = parts[0];

        JsonObject body = readJsonBody(req, resp);
        if (body == null) return;
        if (!body.has("tagId") || body.get("tagId").isJsonNull()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "tagId required");
            return;
        }
        long tagId;
        try {
            tagId = body.get("tagId").getAsLong();
        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "bad tagId");
            return;
        }

        try {
            if (!ownsPage(user, pageId)) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            pageTagDao.addTag(pageId, tagId);
            writeJson(resp, HttpServletResponse.SC_OK, "{\"ok\":true}");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = requireUser(req, resp);
        if (user == null) return;

        long[] parts = parsePath(req, resp, 2);
        if (parts == null) return;
        long pageId = parts[0];
        long tagId = parts[1];

        try {
            if (!ownsPage(user, pageId)) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            pageTagDao.removeTag(pageId, tagId);
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    private boolean ownsPage(User user, long pageId) throws SQLException {
        Page p = pageDao.findById(pageId, user.getId());
        return p != null;
    }

    private long[] parsePath(HttpServletRequest req, HttpServletResponse resp, int expected)
            throws IOException {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.length() < 2) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return null;
        }
        String[] tokens = pathInfo.substring(1).split("/");
        if (tokens.length != expected) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return null;
        }
        long[] out = new long[expected];
        for (int i = 0; i < expected; i++) {
            try {
                out[i] = Long.parseLong(tokens[i]);
            } catch (NumberFormatException e) {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return null;
            }
        }
        return out;
    }

    private User requireUser(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return null;
        }
        return (User) session.getAttribute("user");
    }

    private JsonObject readJsonBody(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");
        String body;
        try (BufferedReader reader = req.getReader()) {
            body = reader.lines().collect(Collectors.joining("\n"));
        }
        try {
            return JsonParser.parseString(body).getAsJsonObject();
        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "invalid JSON");
            return null;
        }
    }

    private void writeJson(HttpServletResponse resp, int status, String json) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        resp.getWriter().write(json);
    }
}
