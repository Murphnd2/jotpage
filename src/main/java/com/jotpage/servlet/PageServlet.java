package com.jotpage.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import com.jotpage.dao.PageDao;
import com.jotpage.dao.PageTagDao;
import com.jotpage.dao.PageTypeDao;
import com.jotpage.dao.UsageDao;
import com.jotpage.model.Page;
import com.jotpage.model.PageType;
import com.jotpage.model.Tag;
import com.jotpage.model.UsageRecord;
import com.jotpage.model.User;
import com.jotpage.util.TierCheck;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.BufferedReader;
import java.io.IOException;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@WebServlet("/app/page/*")
public class PageServlet extends HttpServlet {

    private final PageDao pageDao = new PageDao();
    private final PageTypeDao pageTypeDao = new PageTypeDao();
    private final PageTagDao pageTagDao = new PageTagDao();
    private final UsageDao usageDao = new UsageDao();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = requireUser(req, resp);
        if (user == null) return;

        String pathInfo = req.getPathInfo();
        if (pathInfo == null || "/".equals(pathInfo)) {
            resp.sendRedirect(req.getContextPath() + "/app/dashboard");
            return;
        }

        String segment = pathInfo.substring(1);

        try {
            if ("new".equals(segment)) {
                handleNew(req, resp, user);
                return;
            }

            long pageId;
            try {
                pageId = Long.parseLong(segment);
            } catch (NumberFormatException e) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            Page page = pageDao.findById(pageId, user.getId());
            if (page == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            PageType pageType = pageTypeDao.findById(page.getPageTypeId());

            JsonObject pageDataJson = new JsonObject();
            pageDataJson.addProperty("id", page.getId());
            pageDataJson.addProperty("pageTypeId", page.getPageTypeId());
            pageDataJson.addProperty("isClosed", page.isClosed());
            pageDataJson.addProperty("backgroundType",
                    pageType == null ? "blank" : pageType.getBackgroundType());
            pageDataJson.addProperty("pageTypeName",
                    pageType == null ? "Blank" : pageType.getName());
            pageDataJson.addProperty("immutableOnClose",
                    pageType != null && pageType.isImmutableOnClose());
            if (pageType != null
                    && "custom".equals(pageType.getBackgroundType())
                    && pageType.getBackgroundData() != null) {
                pageDataJson.addProperty("backgroundData", pageType.getBackgroundData());
            }
            try {
                pageDataJson.add("inkData",
                        page.getInkData() == null || page.getInkData().isEmpty()
                                ? JsonParser.parseString("{\"strokes\":[]}")
                                : JsonParser.parseString(page.getInkData()));
            } catch (Exception e) {
                pageDataJson.add("inkData", JsonParser.parseString("{\"strokes\":[]}"));
            }
            try {
                pageDataJson.add("textLayers",
                        page.getTextLayers() == null || page.getTextLayers().isEmpty()
                                ? JsonParser.parseString("[]")
                                : JsonParser.parseString(page.getTextLayers()));
            } catch (Exception e) {
                pageDataJson.add("textLayers", JsonParser.parseString("[]"));
            }
            try {
                pageDataJson.add("imageLayers",
                        page.getImageLayers() == null || page.getImageLayers().isEmpty()
                                ? JsonParser.parseString("[]")
                                : JsonParser.parseString(page.getImageLayers()));
            } catch (Exception e) {
                pageDataJson.add("imageLayers", JsonParser.parseString("[]"));
            }

            // Header text: "Apr 11, 2026 — Lined"
            String headerDate = page.getCreatedAt() == null
                    ? ""
                    : new SimpleDateFormat("MMM d, yyyy").format(page.getCreatedAt());
            String typeName = pageType == null ? "Blank" : pageType.getName();
            String pageHeader = headerDate.isEmpty() ? typeName : headerDate + " \u2014 " + typeName;

            // Prev/next navigation scoped by an optional ?tags=1,2 filter
            String tagsParam = req.getParameter("tags");
            Set<Long> tagFilter = parseTagIds(tagsParam);
            List<Page> pool = pageDao.findByUserId(user.getId());
            List<Page> filtered = filterByAnyTag(pool, tagFilter);

            Long prevId = null, nextId = null;
            Long firstId = null, lastId = null;
            if (!filtered.isEmpty()) {
                firstId = filtered.get(0).getId();
                lastId = filtered.get(filtered.size() - 1).getId();
            }
            for (int i = 0; i < filtered.size(); i++) {
                if (filtered.get(i).getId() == pageId) {
                    if (i > 0) prevId = filtered.get(i - 1).getId();
                    if (i < filtered.size() - 1) nextId = filtered.get(i + 1).getId();
                    // Don't show first/last if already at the boundary
                    if (i == 0) firstId = null;
                    if (i == filtered.size() - 1) lastId = null;
                    break;
                }
            }

            String tagSuffix = (tagsParam == null || tagsParam.isEmpty())
                    ? "" : ("?tags=" + tagsParam);
            String firstHref = firstId == null
                    ? null
                    : req.getContextPath() + "/app/page/" + firstId + tagSuffix;
            String prevHref = prevId == null
                    ? null
                    : req.getContextPath() + "/app/page/" + prevId + tagSuffix;
            String nextHref = nextId == null
                    ? null
                    : req.getContextPath() + "/app/page/" + nextId + tagSuffix;
            String lastHref = lastId == null
                    ? null
                    : req.getContextPath() + "/app/page/" + lastId + tagSuffix;
            String backHref = req.getContextPath() + "/app/dashboard" + tagSuffix;

            req.setAttribute("page", page);
            req.setAttribute("pageType", pageType);
            req.setAttribute("pageDataJson", gson.toJson(pageDataJson));
            req.setAttribute("pageHeader", pageHeader);
            req.setAttribute("firstHref", firstHref);
            req.setAttribute("prevHref", prevHref);
            req.setAttribute("nextHref", nextHref);
            req.setAttribute("lastHref", lastHref);
            req.setAttribute("backHref", backHref);
            req.setAttribute("isPro", TierCheck.isPro(user));
            req.getRequestDispatcher("/jsp/editor.jsp").forward(req, resp);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    private Set<Long> parseTagIds(String param) {
        if (param == null || param.isEmpty()) return Collections.emptySet();
        Set<Long> out = new HashSet<>();
        for (String s : param.split(",")) {
            try {
                out.add(Long.parseLong(s.trim()));
            } catch (NumberFormatException ignored) {
            }
        }
        return out;
    }

    private List<Page> filterByAnyTag(List<Page> pages, Set<Long> tagFilter) throws SQLException {
        if (tagFilter == null || tagFilter.isEmpty()) return pages;
        List<Page> out = new ArrayList<>();
        for (Page p : pages) {
            List<Tag> pageTags = pageTagDao.findTagsByPageId(p.getId());
            for (Tag t : pageTags) {
                if (tagFilter.contains(t.getId())) {
                    out.add(p);
                    break;
                }
            }
        }
        return out;
    }

    private void handleNew(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException, SQLException {
        String typeIdParam = req.getParameter("typeId");
        if (typeIdParam == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "typeId required");
            return;
        }
        long typeId;
        try {
            typeId = Long.parseLong(typeIdParam);
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "bad typeId");
            return;
        }

        PageType pt = pageTypeDao.findById(typeId);
        if (pt == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "unknown typeId");
            return;
        }
        if (!pt.isSystem() && (pt.getUserId() == null || pt.getUserId() != user.getId())) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        // Enforce free-tier monthly page limit (Pro and first-month free users are unlimited).
        UsageRecord usage = usageDao.findOrCreateCurrentMonth(user.getId());
        int pagesThisMonth = usage == null ? 0 : usage.getPagesCreated();
        if (!TierCheck.canCreatePage(user, pagesThisMonth)) {
            resp.sendRedirect(req.getContextPath() + "/app/dashboard?error=page_limit");
            return;
        }

        Page page = new Page();
        page.setUserId(user.getId());
        page.setPageTypeId(typeId);
        page.setTitle("");
        page.setInkData("{\"strokes\":[]}");
        page.setTextLayers("[]");
        page.setClosed(false);

        Page created = pageDao.create(page);
        usageDao.incrementPages(user.getId(), 1);
        resp.sendRedirect(req.getContextPath() + "/app/page/" + created.getId());
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

        String segment = pathInfo.substring(1);

        req.setCharacterEncoding("UTF-8");
        String body;
        try (BufferedReader reader = req.getReader()) {
            body = reader.lines().collect(Collectors.joining("\n"));
        }

        JsonObject json;
        try {
            json = JsonParser.parseString(body).getAsJsonObject();
        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "invalid JSON");
            return;
        }

        if ("reorder".equals(segment)) {
            handleReorder(resp, user, json);
            return;
        }

        long pageId;
        try {
            pageId = Long.parseLong(segment);
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            Page existing = pageDao.findById(pageId, user.getId());
            if (existing == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            if (json.has("inkData") && !json.get("inkData").isJsonNull()) {
                existing.setInkData(json.get("inkData").toString());
            }
            if (json.has("textLayers") && !json.get("textLayers").isJsonNull()) {
                existing.setTextLayers(json.get("textLayers").toString());
            }
            if (json.has("imageLayers") && !json.get("imageLayers").isJsonNull()) {
                existing.setImageLayers(json.get("imageLayers").toString());
            }

            try {
                pageDao.update(existing);
            } catch (SQLException e) {
                String msg = e.getMessage() == null ? "" : e.getMessage();
                if (msg.contains("closed") && msg.contains("immutable")) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    resp.setContentType("application/json");
                    resp.getWriter().write("{\"error\":\"page is locked\"}");
                    return;
                }
                throw e;
            }

            resp.setStatus(HttpServletResponse.SC_OK);
            resp.setContentType("application/json");
            resp.getWriter().write("{\"ok\":true}");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    private void handleReorder(HttpServletResponse resp, User user, JsonObject json)
            throws IOException, ServletException {
        if (!json.has("pageIds") || !json.get("pageIds").isJsonArray()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "pageIds array required");
            return;
        }
        JsonArray arr = json.getAsJsonArray("pageIds");
        List<Long> ids = new ArrayList<>(arr.size());
        for (JsonElement el : arr) {
            try {
                ids.add(el.getAsLong());
            } catch (Exception e) {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "bad pageId");
                return;
            }
        }
        try {
            pageDao.reorder(user.getId(), ids);
            resp.setStatus(HttpServletResponse.SC_OK);
            resp.setContentType("application/json");
            resp.getWriter().write("{\"ok\":true}");
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
        long pageId;
        try {
            pageId = Long.parseLong(pathInfo.substring(1));
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            pageDao.delete(pageId, user.getId());
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
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
}
