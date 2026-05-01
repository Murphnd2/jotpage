<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="${not empty post.summary ? post.summary : 'Read this post on the Jyrnyl blog.'}">
    <title><c:out value="${post.title}"/> — Jyrnyl Blog</title>
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

    <article>
        <h1 class="blog-post-title"><c:out value="${post.title}"/></h1>
        <div class="blog-post-meta">
            <c:out value="${post.authorName}"/>
            &nbsp;&middot;&nbsp;
            <fmt:formatDate value="${post.publishedAt}" pattern="MMMM d, yyyy"/>
        </div>
        <div class="blog-post-body">${post.body}</div>
    </article>

    <div class="blog-back">
        <a href="${pageContext.request.contextPath}/blog">← Back to blog</a>
    </div>

</div>
</body>
</html>
