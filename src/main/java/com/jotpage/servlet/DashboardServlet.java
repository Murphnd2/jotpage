package com.jotpage.servlet;

import com.google.gson.Gson;

import com.jotpage.dao.PageDao;
import com.jotpage.dao.PageTagDao;
import com.jotpage.dao.PageTypeDao;
import com.jotpage.dao.TagDao;
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

import java.io.IOException;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/app/dashboard")
public class DashboardServlet extends HttpServlet {

    private final PageDao pageDao = new PageDao();
    private final PageTypeDao pageTypeDao = new PageTypeDao();
    private final PageTagDao pageTagDao = new PageTagDao();
    private final TagDao tagDao = new TagDao();
    private final UsageDao usageDao = new UsageDao();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        User user = (User) session.getAttribute("user");

        List<Page> pages;
        try {
            pages = pageDao.findByUserId(user.getId());
            List<PageType> types = pageTypeDao.findByUserId(user.getId());
            List<Tag> allTags = tagDao.findByUserId(user.getId());

            Map<Long, PageType> typesById = new HashMap<>();
            for (PageType t : types) {
                typesById.put(t.getId(), t);
            }

            SimpleDateFormat fmt = new SimpleDateFormat("MMM d, yyyy");
            List<Map<String, Object>> view = new ArrayList<>();
            for (Page p : pages) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("id", p.getId());
                row.put("sortOrder", p.getSortOrder());
                row.put("closed", p.isClosed());
                PageType t = typesById.get(p.getPageTypeId());
                row.put("typeName", t == null ? "Unknown" : t.getName());
                row.put("backgroundType", t == null ? "blank" : t.getBackgroundType());
                boolean locked = p.isClosed() && t != null && t.isImmutableOnClose();
                row.put("locked", locked);
                row.put("createdAt", p.getCreatedAt() == null ? "" : fmt.format(p.getCreatedAt()));

                List<Tag> pageTags = pageTagDao.findTagsByPageId(p.getId());
                List<Map<String, Object>> tagViews = new ArrayList<>();
                List<Long> tagIds = new ArrayList<>();
                for (Tag tag : pageTags) {
                    Map<String, Object> tv = new LinkedHashMap<>();
                    tv.put("id", tag.getId());
                    tv.put("name", tag.getName());
                    tv.put("color", tag.getColor());
                    tagViews.add(tv);
                    tagIds.add(tag.getId());
                }
                row.put("tags", tagViews);
                row.put("tagIds", tagIds);
                view.add(row);
            }

            req.setAttribute("pages", view);
            // Pre-escape "</" so a user-supplied string containing "</script>"
            // cannot break out of the inline <script> block that renders this.
            req.setAttribute("pagesJson", gson.toJson(view).replace("</", "<\\/"));
            req.setAttribute("allTags", allTags);
        } catch (SQLException e) {
            throw new ServletException(e);
        }

        // View mode ("book" default, "list" alternate)
        String viewMode = req.getParameter("view");
        if (!"list".equals(viewMode) && !"book".equals(viewMode)) {
            viewMode = "book";
        }
        req.setAttribute("viewMode", viewMode);

        // Preserve ?tags= when switching views
        String tagsParam = req.getParameter("tags");
        String tagQuery = (tagsParam == null || tagsParam.isEmpty())
                ? "" : ("&tags=" + tagsParam);
        String base = req.getContextPath() + "/app/dashboard";
        req.setAttribute("bookViewUrl", base + "?view=book" + tagQuery);
        req.setAttribute("listViewUrl", base + "?view=list" + tagQuery);

        // Tier info for frontend gating
        boolean isPro = TierCheck.isPro(user);
        boolean firstMonth = TierCheck.isInFirstMonth(user);
        int monthlyLimit = TierCheck.getMonthlyPageLimit(user);

        int pagesThisMonth = 0;
        try {
            UsageRecord usage = usageDao.findOrCreateCurrentMonth(user.getId());
            if (usage != null) pagesThisMonth = usage.getPagesCreated();
        } catch (SQLException e) {
            // Fall through with 0; display logic will just show "0 / 20".
        }

        req.setAttribute("isPro", isPro);
        req.setAttribute("isFirstMonth", firstMonth);
        req.setAttribute("pagesThisMonth", pagesThisMonth);
        req.setAttribute("monthlyPageLimit", monthlyLimit); // -1 = unlimited
        req.setAttribute("pageCount", pages.size()); // kept for any legacy references
        try {
            req.setAttribute("customTemplateCount", pageTypeDao.countCustomByUserId(user.getId()));
        } catch (SQLException e) {
            req.setAttribute("customTemplateCount", 0);
        }
        req.setAttribute("customTemplateLimit", TierCheck.FREE_CUSTOM_TEMPLATE_LIMIT);

        // Pass error param (e.g. page_limit redirect)
        req.setAttribute("errorParam", req.getParameter("error"));

        req.getRequestDispatcher("/jsp/dashboard.jsp").forward(req, resp);
    }
}
