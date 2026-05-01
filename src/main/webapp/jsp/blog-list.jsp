<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Thoughts and updates from the Jyrnyl team on journaling, voice recording, and building in public.">
    <title>Blog — Jyrnyl</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/blog.css" rel="stylesheet">
</head>
<body>
<div class="blog-shell">

    <nav class="blog-nav">
        <a class="blog-nav-brand" href="${pageContext.request.contextPath}/">Jyrnyl</a>
        <a class="blog-nav-home" href="${pageContext.request.contextPath}/">← Back to Jyrnyl</a>
    </nav>

    <h1 class="blog-list-heading">Blog</h1>
    <p class="blog-list-sub">Thoughts on journaling, voice recording, and building in public.</p>

    <c:choose>
        <c:when test="${empty posts}">
            <div class="blog-empty">Nothing here yet. Check back soon.</div>
        </c:when>
        <c:otherwise>
            <c:forEach var="post" items="${posts}">
                <div class="blog-post-card">
                    <h2 class="blog-card-title">
                        <a href="${pageContext.request.contextPath}/blog/${post.slug}"><c:out value="${post.title}"/></a>
                    </h2>
                    <c:if test="${not empty post.summary}">
                        <p class="blog-card-summary"><c:out value="${post.summary}"/></p>
                    </c:if>
                    <div class="blog-card-meta">
                        <c:out value="${post.authorName}"/>
                        &nbsp;&middot;&nbsp;
                        <fmt:formatDate value="${post.publishedAt}" pattern="MMMM d, yyyy"/>
                    </div>
                </div>
            </c:forEach>
        </c:otherwise>
    </c:choose>

</div>
</body>
</html>
