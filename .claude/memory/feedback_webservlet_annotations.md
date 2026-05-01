---
name: No @WebServlet annotations — use web.xml only
description: New servlets must NOT use @WebServlet annotations; all mappings go in web.xml or Tomcat rejects the WAR with a duplicate url-pattern error
type: feedback
---

Do not add `@WebServlet` annotations to any servlet class in this project. All URL mappings are defined in `web.xml`. If a class has both an annotation and a web.xml mapping, Tomcat throws:

```
IllegalArgumentException: The servlets named [X] and [com.jotpage.servlet.X] are both mapped to the url-pattern [/...] which is not permitted
```

This causes the WAR to fail deployment entirely.

**Why:** Discovered 2026-05-01 when BlogServlet and AdminBlogServlet were written with `@WebServlet` annotations and web.xml entries. The duplicate caused a prod outage until the annotations were removed.

**How to apply:** When creating any new servlet, omit the `@WebServlet` import and annotation. Add the `<servlet>` and `<servlet-mapping>` blocks to `web.xml` only.
