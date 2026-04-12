package com.jotpage.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import com.jotpage.dao.PageTypeDao;
import com.jotpage.dao.TemplateInUseException;
import com.jotpage.model.PageType;
import com.jotpage.model.User;
import com.jotpage.util.TierCheck;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.io.InputStream;
import java.sql.SQLException;
import java.util.Base64;
import java.util.List;

@WebServlet("/app/api/pagetypes/*")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,          // 1 MB in-memory before spilling to tmp
        maxFileSize = 5L * 1024 * 1024,           // 5 MB per file
        maxRequestSize = 6L * 1024 * 1024          // leave headroom for form fields
)
public class PageTypeServlet extends HttpServlet {

    private static final long MAX_FILE_BYTES = 5L * 1024 * 1024;

    private final PageTypeDao pageTypeDao = new PageTypeDao();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = requireUser(req, resp);
        if (user == null) return;

        try {
            List<PageType> types = pageTypeDao.findByUserId(user.getId());
            // Strip heavy backgroundData from the list response — the client only
            // needs it when it actually loads a page of that type.
            JsonArray arr = new JsonArray();
            for (PageType t : types) {
                arr.add(toLightJson(t));
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

        // Enforce free-tier custom template limit
        if (!TierCheck.isPro(user)) {
            try {
                int count = pageTypeDao.countCustomByUserId(user.getId());
                if (count >= TierCheck.FREE_CUSTOM_TEMPLATE_LIMIT) {
                    writeJson(resp, HttpServletResponse.SC_FORBIDDEN,
                            "{\"error\":\"" + TierCheck.requirePro(user, TierCheck.FEATURE_CUSTOM_TEMPLATES)
                                    .replace("\"", "\\\"") + "\"}");
                    return;
                }
            } catch (SQLException e) {
                throw new ServletException(e);
            }
        }

        String contentType = req.getContentType();
        if (contentType == null || !contentType.toLowerCase().startsWith("multipart/")) {
            resp.sendError(HttpServletResponse.SC_UNSUPPORTED_MEDIA_TYPE,
                    "multipart/form-data required");
            return;
        }

        String name = req.getParameter("name");
        if (name == null || name.trim().isEmpty()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "name required");
            return;
        }
        name = name.trim();
        if (name.length() > 100) name = name.substring(0, 100);

        String immutableParam = req.getParameter("immutableOnClose");
        boolean immutableOnClose = immutableParam != null
                && ("true".equalsIgnoreCase(immutableParam)
                        || "on".equalsIgnoreCase(immutableParam)
                        || "1".equals(immutableParam));

        Part filePart;
        try {
            filePart = req.getPart("backgroundImage");
        } catch (IllegalStateException e) {
            resp.sendError(HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE, "file too large");
            return;
        }
        if (filePart == null || filePart.getSize() == 0) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "backgroundImage required");
            return;
        }
        if (filePart.getSize() > MAX_FILE_BYTES) {
            resp.sendError(HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE,
                    "max file size is 5 MB");
            return;
        }

        String partContentType = filePart.getContentType() == null
                ? "" : filePart.getContentType().toLowerCase();
        String submittedName = filePart.getSubmittedFileName() == null
                ? "" : filePart.getSubmittedFileName().toLowerCase();
        boolean isPng = partContentType.contains("png") || submittedName.endsWith(".png");
        if (!isPng) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "PNG only");
            return;
        }

        byte[] bytes;
        try (InputStream in = filePart.getInputStream()) {
            bytes = in.readAllBytes();
        }
        // Cheap magic-number check so people can't smuggle other formats by
        // renaming to .png
        if (bytes.length < 8
                || (bytes[0] & 0xFF) != 0x89
                || bytes[1] != 'P'
                || bytes[2] != 'N'
                || bytes[3] != 'G') {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "not a valid PNG");
            return;
        }

        String base64 = Base64.getEncoder().encodeToString(bytes);

        PageType pt = new PageType();
        pt.setUserId(user.getId());
        pt.setName(name);
        pt.setBackgroundType("custom");
        pt.setBackgroundData(base64);
        pt.setImmutableOnClose(immutableOnClose);
        pt.setSystem(false);

        try {
            PageType created = pageTypeDao.create(pt);
            // Strip the heavy base64 from the response — the client only needs
            // the metadata to show the template in the list.
            writeJson(resp, HttpServletResponse.SC_CREATED, gson.toJson(toLightJson(created)));
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

        try {
            pageTypeDao.delete(id, user.getId());
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (TemplateInUseException e) {
            writeJson(resp, HttpServletResponse.SC_CONFLICT,
                    "{\"error\":\"Cannot delete \\u2014 pages still use this template. "
                            + "Delete or reassign those pages first.\"}");
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
        if (pathInfo == null || !pathInfo.equals("/reorder")) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        JsonObject body;
        try {
            body = gson.fromJson(req.getReader(), JsonObject.class);
        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "invalid JSON");
            return;
        }
        if (body == null || !body.has("typeIds") || !body.get("typeIds").isJsonArray()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "typeIds array required");
            return;
        }

        com.google.gson.JsonArray arr = body.getAsJsonArray("typeIds");
        java.util.List<Long> ids = new java.util.ArrayList<>();
        for (int i = 0; i < arr.size(); i++) {
            ids.add(arr.get(i).getAsLong());
        }

        try {
            pageTypeDao.updateSortOrder(user.getId(), ids);
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    private JsonObject toLightJson(PageType t) {
        JsonObject obj = new JsonObject();
        obj.addProperty("id", t.getId());
        if (t.getUserId() != null) {
            obj.addProperty("userId", t.getUserId());
        } else {
            obj.add("userId", null);
        }
        obj.addProperty("name", t.getName());
        obj.addProperty("backgroundType", t.getBackgroundType());
        obj.addProperty("immutableOnClose", t.isImmutableOnClose());
        obj.addProperty("system", t.isSystem());
        obj.addProperty("sortOrder", t.getSortOrder());
        return obj;
    }

    private User requireUser(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return null;
        }
        return (User) session.getAttribute("user");
    }

    private void writeJson(HttpServletResponse resp, int status, String json) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        resp.getWriter().write(json);
    }
}
