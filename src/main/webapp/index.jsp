<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jyrnyl — Record your life.</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/theme.css" rel="stylesheet">
    <%@ include file="/WEB-INF/jspf/pwa-head.jspf" %>
    <style>
        body {
            background:
                radial-gradient(circle at 20% 20%, rgba(212,148,58,0.08), transparent 40%),
                radial-gradient(circle at 80% 80%, rgba(160,82,45,0.06), transparent 45%),
                var(--bg-cream);
            min-height: 100vh;
        }
        .login-wrap {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 24px;
            gap: 20px;
        }
        .login-card {
            background: var(--bg-card);
            border: 1px solid var(--border-warm);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-paper);
            padding: 18px;
            max-width: 420px;
            width: 100%;
            position: relative;
        }
        .login-card::before {
            content: "";
            position: absolute;
            top: 18px;
            left: 18px;
            right: 18px;
            bottom: 18px;
            border: 1px solid var(--border-warm);
            border-radius: 8px;
            pointer-events: none;
        }
        .login-logo {
            /* Fill the area inside the inner border frame */
            position: relative;
            display: block;
            width: calc(100% - 36px);
            height: auto;
            margin: 18px auto;
            border-radius: 8px;
            z-index: 1;
        }
        .google-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            min-height: 48px;
            padding: 0 22px;
            font-weight: 500;
            font-size: 1rem;
        }
        .google-btn svg {
            width: 20px;
            height: 20px;
        }
    </style>
</head>
<body>
    <div class="login-wrap">
        <div class="login-card">
            <img src="${pageContext.request.contextPath}/images/jyrnyl-logo-square.svg"
                 alt="Jyrnyl — Record your life." class="login-logo">
        </div>
        <a id="googleSignInBtn" class="btn btn-primary btn-lg google-btn"
           href="${pageContext.request.contextPath}/login">
            <svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                <path fill="#fff" d="M44.5 20H24v8.5h11.8C34.7 33.1 30 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3 0 5.7 1.1 7.8 2.9l6-6C34.4 5.5 29.5 3.5 24 3.5 12.7 3.5 3.5 12.7 3.5 24S12.7 44.5 24 44.5c11 0 20-8 20-20 0-1.5-.2-3-.5-4.5z"/>
            </svg>
            Sign in with Google
        </a>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <%@ include file="/WEB-INF/jspf/pwa-register.jspf" %>
</body>
</html>
