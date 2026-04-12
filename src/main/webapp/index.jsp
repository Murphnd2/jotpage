<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JotPage</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Source+Sans+3:wght@400;500;600&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/theme.css" rel="stylesheet">
    <style>
        body {
            background:
                radial-gradient(circle at 20% 20%, rgba(201,168,76,0.08), transparent 40%),
                radial-gradient(circle at 80% 80%, rgba(124,50,56,0.06), transparent 45%),
                var(--bg-cream);
            min-height: 100vh;
        }
        .login-wrap {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }
        .login-card {
            background: var(--bg-card);
            border: 1px solid var(--border-warm);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-paper);
            padding: 56px 56px 48px;
            text-align: center;
            max-width: 460px;
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
        .login-title {
            font-family: var(--font-serif);
            font-weight: 700;
            font-size: 3.4rem;
            line-height: 1;
            margin: 0 0 10px;
            color: var(--accent-brown);
            letter-spacing: -0.02em;
        }
        .login-rule {
            width: 64px;
            height: 2px;
            background: var(--accent-gold);
            border: 0;
            margin: 16px auto 20px;
            opacity: 0.8;
        }
        .login-subtitle {
            color: var(--text-muted);
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 1.15rem;
            margin-bottom: 36px;
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
        .login-footer {
            margin-top: 28px;
            color: var(--text-muted);
            font-size: 0.85rem;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="login-wrap">
        <div class="login-card">
            <h1 class="login-title">JotPage</h1>
            <hr class="login-rule">
            <p class="login-subtitle">Your digital notebook</p>
            <a id="googleSignInBtn" class="btn btn-primary btn-lg google-btn"
               href="${pageContext.request.contextPath}/login">
                <svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                    <path fill="#fff" d="M44.5 20H24v8.5h11.8C34.7 33.1 30 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3 0 5.7 1.1 7.8 2.9l6-6C34.4 5.5 29.5 3.5 24 3.5 12.7 3.5 3.5 12.7 3.5 24S12.7 44.5 24 44.5c11 0 20-8 20-20 0-1.5-.2-3-.5-4.5z"/>
                </svg>
                Sign in with Google
            </a>
            <div class="login-footer">A quiet place for your pages</div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
