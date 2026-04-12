package com.jotpage.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import com.jotpage.dao.TagDao;
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

@WebServlet("/app/api/tags/*")
public class TagServlet extends HttpServlet {

    private final TagDao tagDao = new TagDao();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = requireUser(req, resp);
        if (user == null) return;

        try {
            List<Tag> tags = tagDao.findByUserId(user.getId());
            JsonArray arr = new JsonArray();
            for (Tag t : tags) {
                JsonObject obj = new JsonObject();
                obj.addProperty("id", t.getId());
                obj.addProperty("userId", t.getUserId());
                obj.addProperty("name", t.getName());
                obj.addProperty("color", t.getColor());
                obj.addProperty("pageCount", tagDao.countPages(t.getId()));
                arr.add(obj);
            }
            writeJson(resp, HttpServletResponse.SC_OK, gson.toJson(arr));
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = requireUser(req, resp);
        if (user == null) return;

        JsonObject body = readJsonBody(req, resp);
        if (body == null) return;

        if (!body.has("name") || body.get("name").isJsonNull()
                || body.get("name").getAsString().trim().isEmpty()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "name required");
            return;
        }

        Tag tag = new Tag();
        tag.setUserId(user.getId());
        tag.setName(body.get("name").getAsString().trim());
        if (body.has("color") && !body.get("color").isJsonNull()) {
            tag.setColor(body.get("color").getAsString());
        }

        try {
            Tag created = tagDao.create(tag);
            writeJson(resp, HttpServletResponse.SC_CREATED, gson.toJson(created));
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = requireUser(req, resp);
        if (user == null) return;

        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.length() < 2) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        long id;
        try {
            id = Long.parseLong(pathInfo.substring(1));
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        JsonObject body = readJsonBody(req, resp);
        if (body == null) return;

        if (!body.has("name") || body.get("name").isJsonNull()
                || body.get("name").getAsString().trim().isEmpty()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "name required");
            return;
        }

        Tag tag = new Tag();
        tag.setId(id);
        tag.setUserId(user.getId());
        tag.setName(body.get("name").getAsString().trim());
        if (body.has("color") && !body.get("color").isJsonNull()) {
            tag.setColor(body.get("color").getAsString());
        }

        try {
            tagDao.update(tag);
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

        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.length() < 2) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        long id;
        try {
            id = Long.parseLong(pathInfo.substring(1));
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String replaceWith = req.getParameter("replaceWith");

        try {
            if (replaceWith != null && !replaceWith.isEmpty()) {
                long replaceId = Long.parseLong(replaceWith);
                tagDao.replaceTag(id, replaceId, user.getId());
            } else {
                tagDao.delete(id, user.getId());
            }
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "bad replaceWith");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
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
