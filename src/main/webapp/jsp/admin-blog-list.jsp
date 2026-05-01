<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Blog Admin — Jyrnyl</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/theme.css" rel="stylesheet">
    <style>
        body { background: var(--bg-cream); }
        .admin-wrap { max-width: 900px; margin: 0 auto; padding: 40px 24px; }
        .badge-published { background-color: #4c7c59; }
        .badge-draft     { background-color: var(--text-light); }
    </style>
</head>
<body>
<div class="admin-wrap">

    <div class="d-flex align-items-center justify-content-between mb-4">
        <h1 class="serif mb-0" style="font-size:1.8rem;">Blog Posts</h1>
        <a href="${pageContext.request.contextPath}/app/admin/blog/new"
           class="btn btn-sm btn-dark">New Post</a>
    </div>

    <c:choose>
        <c:when test="${empty posts}">
            <p class="text-muted">No posts yet. <a href="${pageContext.request.contextPath}/app/admin/blog/new">Create one.</a></p>
        </c:when>
        <c:otherwise>
            <table class="table table-hover align-middle">
                <thead class="table-light">
                    <tr>
                        <th>Title</th>
                        <th>Status</th>
                        <th>Published</th>
                        <th>Updated</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="post" items="${posts}">
                        <tr>
                            <td>
                                <a href="${pageContext.request.contextPath}/app/admin/blog/edit/${post.id}"
                                   class="fw-medium text-dark text-decoration-none">
                                    <c:out value="${post.title}"/>
                                </a>
                            </td>
                            <td>
                                <c:choose>
                                    <c:when test="${post.status eq 'published'}">
                                        <span class="badge badge-published">published</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="badge badge-draft">draft</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td class="text-muted small">
                                <c:choose>
                                    <c:when test="${not empty post.publishedAt}">
                                        <fmt:formatDate value="${post.publishedAt}" pattern="MMM d, yyyy"/>
                                    </c:when>
                                    <c:otherwise>—</c:otherwise>
                                </c:choose>
                            </td>
                            <td class="text-muted small">
                                <fmt:formatDate value="${post.updatedAt}" pattern="MMM d, yyyy"/>
                            </td>
                            <td class="text-end">
                                <a href="${pageContext.request.contextPath}/app/admin/blog/edit/${post.id}"
                                   class="btn btn-sm btn-outline-secondary me-1">Edit</a>
                                <form method="post"
                                      action="${pageContext.request.contextPath}/app/admin/blog/delete/${post.id}"
                                      class="d-inline"
                                      onsubmit="return confirm('Delete “${post.title}”? This cannot be undone.');">
                                    <button type="submit" class="btn btn-sm btn-outline-danger">Delete</button>
                                </form>
                            </td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>
        </c:otherwise>
    </c:choose>

    <div class="mt-4 pt-3 border-top small text-muted">
        <a href="${pageContext.request.contextPath}/app/dashboard">← Dashboard</a>
        &nbsp;&middot;&nbsp;
        <a href="${pageContext.request.contextPath}/blog" target="_blank">View public blog ↗</a>
    </div>

</div>
</body>
</html>
