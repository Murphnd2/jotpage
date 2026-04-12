package com.jotpage.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import com.jotpage.dao.PageDao;
import com.jotpage.dao.PageTypeDao;
import com.jotpage.model.Page;
import com.jotpage.model.PageType;
import com.jotpage.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Lightweight JSON endpoint used by the book view to lazy-load the render
 * data for a single page. Returns only the fields needed to draw a miniature
 * version of the page onto an offscreen canvas.
 */
@WebServlet("/app/api/page-thumbnail/*")
public class PageThumbnailServlet extends HttpServlet {

    private final PageDao pageDao = new PageDao();
    private final PageTypeDao pageTypeDao = new PageTypeDao();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        User user = (User) session.getAttribute("user");

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
            Page page = pageDao.findById(pageId, user.getId());
            if (page == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            PageType pageType = pageTypeDao.findById(page.getPageTypeId());

            JsonObject out = new JsonObject();
            out.addProperty("id", page.getId());
            out.addProperty("pageTypeId", page.getPageTypeId());
            out.addProperty("backgroundType",
                    pageType == null ? "blank" : pageType.getBackgroundType());
            if (pageType != null
                    && "custom".equals(pageType.getBackgroundType())
                    && pageType.getBackgroundData() != null) {
                out.addProperty("backgroundData", pageType.getBackgroundData());
            }
            out.addProperty("createdAt",
                    page.getCreatedAt() == null ? "" : page.getCreatedAt().toString());
            try {
                out.add("inkData",
                        page.getInkData() == null || page.getInkData().isEmpty()
                                ? JsonParser.parseString("{\"strokes\":[]}")
                                : JsonParser.parseString(page.getInkData()));
            } catch (Exception e) {
                out.add("inkData", JsonParser.parseString("{\"strokes\":[]}"));
            }
            try {
                out.add("textLayers",
                        page.getTextLayers() == null || page.getTextLayers().isEmpty()
                                ? JsonParser.parseString("[]")
                                : JsonParser.parseString(page.getTextLayers()));
            } catch (Exception e) {
                out.add("textLayers", JsonParser.parseString("[]"));
            }
            try {
                out.add("imageLayers",
                        page.getImageLayers() == null || page.getImageLayers().isEmpty()
                                ? JsonParser.parseString("[]")
                                : JsonParser.parseString(page.getImageLayers()));
            } catch (Exception e) {
                out.add("imageLayers", JsonParser.parseString("[]"));
            }

            resp.setStatus(HttpServletResponse.SC_OK);
            resp.setContentType("application/json");
            resp.setCharacterEncoding("UTF-8");
            resp.getWriter().write(gson.toJson(out));
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }
}
