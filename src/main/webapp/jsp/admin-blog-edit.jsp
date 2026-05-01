<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><c:choose><c:when test="${not empty post}">Edit Post</c:when><c:otherwise>New Post</c:otherwise></c:choose> — Jyrnyl Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/theme.css" rel="stylesheet">
    <style>
        body { background: var(--bg-cream); }
        .admin-wrap { max-width: 820px; margin: 0 auto; padding: 40px 24px 80px; }
        #body { font-family: monospace; font-size: 0.9rem; min-height: 360px; }
        .slug-note { font-size: 0.78rem; color: var(--text-muted); margin-top: 4px; }
    </style>
</head>
<body>
<div class="admin-wrap">

    <div class="d-flex align-items-center justify-content-between mb-4">
        <h1 class="serif mb-0" style="font-size:1.8rem;">
            <c:choose>
                <c:when test="${not empty post}">Edit Post</c:when>
                <c:otherwise>New Post</c:otherwise>
            </c:choose>
        </h1>
        <a href="${pageContext.request.contextPath}/app/admin/blog"
           class="btn btn-sm btn-outline-secondary">← All posts</a>
    </div>

    <form method="post" action="${pageContext.request.contextPath}/app/admin/blog">
        <c:if test="${not empty post}">
            <input type="hidden" name="id" value="${post.id}">
        </c:if>

        <div class="mb-3">
            <label for="title" class="form-label fw-medium">Title</label>
            <input type="text" class="form-control" id="title" name="title" required
                   value="<c:out value='${post.title}'/>">
        </div>

        <div class="mb-3">
            <label for="slug" class="form-label fw-medium">Slug</label>
            <input type="text" class="form-control" id="slug" name="slug" required
                   pattern="[a-z0-9\-]+" title="Lowercase letters, numbers, and hyphens only"
                   value="<c:out value='${post.slug}'/>">
            <div class="slug-note">URL: /blog/<span id="slugPreview"><c:out value='${post.slug}'/></span></div>
        </div>

        <div class="mb-3">
            <label for="summary" class="form-label fw-medium">Summary <span class="text-muted fw-normal">(optional — shown in list view)</span></label>
            <textarea class="form-control" id="summary" name="summary" rows="2"><c:out value="${post.summary}"/></textarea>
        </div>

        <div class="mb-3">
            <label for="authorName" class="form-label fw-medium">Author Name</label>
            <input type="text" class="form-control" id="authorName" name="authorName"
                   value="<c:choose><c:when test='${not empty post}'><c:out value='${post.authorName}'/></c:when><c:otherwise>Kevin Murphy</c:otherwise></c:choose>">
        </div>

        <div class="mb-4">
            <label for="body" class="form-label fw-medium">Body <span class="text-muted fw-normal">(HTML)</span></label>
            <textarea class="form-control" id="body" name="body"><c:out value="${post.body}"/></textarea>
        </div>

        <div class="d-flex gap-2 flex-wrap">
            <button type="submit" name="action" value="save" class="btn btn-outline-secondary">
                Save Draft
            </button>
            <c:choose>
                <c:when test="${post.status eq 'published'}">
                    <button type="submit" name="action" value="unpublish" class="btn btn-outline-warning">
                        Unpublish
                    </button>
                    <button type="submit" name="action" value="publish" class="btn btn-dark">
                        Save &amp; Keep Published
                    </button>
                </c:when>
                <c:otherwise>
                    <button type="submit" name="action" value="publish" class="btn btn-dark">
                        Publish
                    </button>
                </c:otherwise>
            </c:choose>
        </div>

    </form>

</div>

<script>
(function () {
    var titleEl = document.getElementById('title');
    var slugEl  = document.getElementById('slug');
    var preview = document.getElementById('slugPreview');
    var slugEdited = slugEl.value.length > 0;

    function toSlug(s) {
        return s.toLowerCase()
                .replace(/[^a-z0-9\s-]/g, '')
                .trim()
                .replace(/[\s]+/g, '-')
                .replace(/-+/g, '-');
    }

    titleEl.addEventListener('input', function () {
        if (!slugEdited) {
            var generated = toSlug(titleEl.value);
            slugEl.value = generated;
            preview.textContent = generated;
        }
    });

    slugEl.addEventListener('input', function () {
        slugEdited = slugEl.value.length > 0;
        preview.textContent = slugEl.value;
    });
}());
</script>
</body>
</html>
