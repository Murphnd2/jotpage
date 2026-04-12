<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JotPage &mdash; Notebook</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Source+Sans+3:wght@400;500;600&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/theme.css" rel="stylesheet">
    <style>
        body {
            background:
                radial-gradient(circle at 15% 10%, rgba(201,168,76,0.06), transparent 40%),
                radial-gradient(circle at 90% 90%, rgba(124,50,56,0.04), transparent 45%),
                var(--bg-cream);
        }
        .notebook-header h1 {
            font-family: var(--font-serif);
            font-weight: 700;
            font-size: 2.2rem;
            color: var(--accent-brown);
            margin: 0;
        }
        .notebook-header .subhead {
            font-family: var(--font-serif);
            font-style: italic;
            color: var(--text-muted);
            font-size: 0.95rem;
            margin-top: 2px;
        }

        .tag-chip {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 2px 9px;
            border-radius: 999px;
            font-size: 0.72rem;
            color: #fff;
            user-select: none;
            letter-spacing: 0.02em;
            box-shadow: inset 0 0 0 1px rgba(255,255,255,0.12);
        }
        .tag-filter-chip {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 5px 14px;
            border-radius: 999px;
            font-size: 0.85rem;
            color: #fff;
            cursor: pointer;
            opacity: 0.55;
            border: 2px solid transparent;
            user-select: none;
            transition: opacity 0.15s ease, border-color 0.15s ease, transform 0.08s ease;
        }
        .tag-filter-chip:hover { opacity: 0.8; }
        .tag-filter-chip.active {
            opacity: 1;
            border-color: var(--accent-brown);
            transform: translateY(-1px);
        }

        /* Notebook entry layout */
        .notebook-list {
            display: flex;
            flex-direction: column;
            gap: 14px;
        }
        .page-entry {
            background: var(--bg-card);
            border: 1px solid var(--border-warm);
            border-radius: var(--radius-lg);
            padding: 16px 20px;
            display: flex;
            align-items: center;
            gap: 20px;
            text-decoration: none;
            color: var(--text-dark);
            box-shadow: var(--shadow-soft);
            transition: transform 0.12s ease, box-shadow 0.12s ease, border-color 0.12s ease;
            position: relative;
        }
        .page-entry::before {
            /* Left-edge "binding" stripe for a notebook feel */
            content: "";
            position: absolute;
            left: 0;
            top: 10px;
            bottom: 10px;
            width: 3px;
            border-radius: 3px;
            background: linear-gradient(to bottom, var(--accent-gold), transparent);
            opacity: 0.7;
        }
        .page-entry:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-hover);
            color: var(--text-dark);
            border-color: var(--border-warm-strong);
        }
        .page-entry .entry-main {
            flex: 1 1 auto;
            min-width: 0;
        }
        .page-entry .entry-date {
            font-family: var(--font-serif);
            font-size: 1.15rem;
            font-weight: 600;
            color: var(--accent-brown);
            letter-spacing: 0.01em;
        }
        .page-entry .entry-meta {
            font-size: 0.85rem;
            color: var(--text-muted);
            margin-top: 3px;
            font-style: italic;
        }
        .page-entry .entry-tags {
            margin-top: 8px;
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
        }
        .page-entry .entry-order {
            font-family: var(--font-serif);
            font-size: 0.85rem;
            color: var(--text-light);
            min-width: 36px;
            text-align: right;
            font-variant-numeric: tabular-nums;
            font-style: italic;
        }

        /* Thumbnail — mini page with a "tape" corner for tactility */
        .page-thumb {
            flex: 0 0 auto;
            width: 58px;
            height: 82px;
            border: 1px solid var(--border-warm-strong);
            border-radius: 3px;
            background: #fffdf7;
            position: relative;
            overflow: hidden;
            box-shadow:
                0 1px 0 rgba(92,64,51,0.04),
                1px 2px 5px rgba(92,64,51,0.10);
            transform: rotate(-1.2deg);
        }
        .page-thumb::after {
            /* Tape strip across the top */
            content: "";
            position: absolute;
            top: -4px;
            left: 50%;
            width: 28px;
            height: 10px;
            background: rgba(201,168,76,0.28);
            border: 1px solid rgba(201,168,76,0.35);
            transform: translateX(-50%) rotate(-4deg);
            border-radius: 1px;
        }
        .page-thumb.bg-lined {
            background-image: repeating-linear-gradient(
                to bottom, #fffdf7 0, #fffdf7 10px, #d9c9a8 10px, #d9c9a8 11px);
        }
        .page-thumb.bg-dot_grid {
            background-image: radial-gradient(#c9b892 1px, transparent 1.5px);
            background-size: 10px 10px;
        }
        .page-thumb.bg-graph {
            background-image:
                linear-gradient(to right, #e8d9b8 1px, transparent 1px),
                linear-gradient(to bottom, #e8d9b8 1px, transparent 1px);
            background-size: 10px 10px;
        }
        .page-thumb.bg-daily_calendar::before,
        .page-thumb.bg-time_slot::before {
            content: "";
            position: absolute;
            inset: 8px 6px 6px 6px;
            background-image: repeating-linear-gradient(
                to bottom, #fffdf7 0, #fffdf7 12px, #c9b892 12px, #c9b892 13px);
        }
        .page-thumb.bg-monthly_calendar::before {
            content: "";
            position: absolute;
            inset: 8px 6px 6px 6px;
            background-image:
                linear-gradient(to right, #c9b892 1px, transparent 1px),
                linear-gradient(to bottom, #c9b892 1px, transparent 1px);
            background-size: 9px 14px;
        }
        .page-thumb .closed-badge {
            position: absolute;
            bottom: 2px;
            right: 2px;
            background: rgba(92,64,51,0.85);
            color: #fff;
            font-size: 0.55rem;
            padding: 1px 4px;
            border-radius: 2px;
            letter-spacing: 0.04em;
        }

        /* Reorder mode */
        body.reorder-mode .page-entry {
            cursor: grab;
            border-style: dashed;
            border-color: var(--border-warm-strong);
        }
        body.reorder-mode .page-entry .entry-main {
            pointer-events: none;
        }
        body.reorder-mode .page-entry.drag-over {
            border-color: var(--accent-gold);
            background: rgba(201,168,76,0.12);
        }
        body.reorder-mode .page-entry.dragging {
            opacity: 0.45;
        }
        .reorder-active .tag-filter-bar {
            opacity: 0.45;
            pointer-events: none;
        }

        /* Filter bar */
        .tag-filter-bar .small {
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.9rem;
        }

        /* Delete (X) button that appears on hover over a custom template row */
        .list-group-item .delete-template-btn {
            background: transparent;
            border: 0;
            color: var(--text-muted);
            padding: 2px 8px;
            border-radius: var(--radius-sm);
            opacity: 0.6;
            transition: opacity 0.15s ease, color 0.15s ease, background 0.15s ease;
        }
        .list-group-item .delete-template-btn:hover {
            opacity: 1;
            color: var(--accent-burgundy);
            background: rgba(124, 50, 56, 0.08);
        }

        /* Custom template creation form inside the modal */
        .custom-template-section {
            margin-top: 20px;
            padding-top: 18px;
            border-top: 1px solid var(--border-warm);
        }
        .custom-template-section h6 {
            font-family: var(--font-serif);
            font-weight: 600;
            color: var(--accent-brown);
            font-size: 1.05rem;
            margin-bottom: 4px;
        }
        .custom-template-section .hint {
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.85rem;
            color: var(--text-muted);
            margin-bottom: 14px;
        }
        .custom-template-section label {
            font-size: 0.85rem;
            color: var(--text-muted);
            margin-bottom: 4px;
            display: block;
        }
        .custom-template-section .drop-zone {
            position: relative;
            border: 1px dashed var(--border-warm-strong);
            border-radius: var(--radius-md);
            padding: 14px;
            text-align: center;
            background: rgba(201, 168, 76, 0.05);
            transition: background 0.15s ease, border-color 0.15s ease;
        }
        .custom-template-section .drop-zone:hover {
            background: rgba(201, 168, 76, 0.10);
            border-color: var(--accent-gold);
        }
        .custom-template-section .drop-zone input[type="file"] {
            position: absolute;
            inset: 0;
            opacity: 0;
            cursor: pointer;
        }
        .custom-template-section .drop-zone-label {
            color: var(--text-muted);
            font-size: 0.85rem;
            font-style: italic;
            pointer-events: none;
        }
        .custom-template-section .preview-wrap {
            margin-top: 12px;
            display: none;
            text-align: center;
        }
        .custom-template-section .preview-wrap.visible { display: block; }
        .custom-template-section .preview-wrap img {
            max-width: 140px;
            max-height: 200px;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-sm);
            box-shadow: var(--shadow-soft);
            background: #fff;
        }
        .custom-template-section .preview-wrap .preview-meta {
            margin-top: 6px;
            font-size: 0.75rem;
            color: var(--text-muted);
            font-style: italic;
        }
        .custom-template-section .form-check-label {
            color: var(--text-dark);
            font-size: 0.9rem;
        }
        .custom-template-section .form-check-input:checked {
            background-color: var(--accent-brown);
            border-color: var(--accent-brown);
        }
        .custom-template-section .error-msg {
            display: none;
            color: var(--accent-burgundy);
            font-size: 0.85rem;
            margin-top: 6px;
        }
        .custom-template-section .error-msg.visible { display: block; }

        .template-alert {
            display: none;
            padding: 10px 14px;
            margin-bottom: 14px;
            border-radius: var(--radius-md);
            background: rgba(124, 50, 56, 0.08);
            border: 1px solid rgba(124, 50, 56, 0.25);
            color: var(--accent-burgundy-dark);
            font-size: 0.9rem;
            line-height: 1.4;
            position: relative;
        }
        .template-alert.visible { display: block; }
        .template-alert .alert-close {
            position: absolute;
            top: 6px;
            right: 8px;
            background: transparent;
            border: 0;
            color: var(--accent-burgundy);
            font-size: 1rem;
            line-height: 1;
            cursor: pointer;
            opacity: 0.7;
            padding: 2px 6px;
        }
        .template-alert .alert-close:hover { opacity: 1; }

        /* -------------------------------------------------------------- */
        /* View toggle */
        /* -------------------------------------------------------------- */
        .view-toggle {
            display: inline-flex;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-md);
            overflow: hidden;
            background: var(--bg-card);
        }
        .view-toggle .view-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 44px;
            min-height: 40px;
            padding: 0 12px;
            color: var(--text-muted);
            background: transparent;
            text-decoration: none;
            font-size: 1.1rem;
            border: 0;
            border-right: 1px solid var(--border-warm);
            transition: background 0.15s ease, color 0.15s ease;
        }
        .view-toggle .view-btn:last-child { border-right: 0; }
        .view-toggle .view-btn:hover {
            background: var(--bg-cream-dark);
            color: var(--accent-brown);
        }
        .view-toggle .view-btn.active {
            background: var(--accent-brown);
            color: #fff;
        }

        /* -------------------------------------------------------------- */
        /* Book view */
        /* -------------------------------------------------------------- */
        .book-stage {
            background:
                radial-gradient(circle at 50% 40%, #6b4a30 0%, #4a3221 60%, #2f1f13 100%);
            border-radius: var(--radius-lg);
            padding: 40px 24px;
            box-shadow:
                inset 0 2px 12px rgba(0,0,0,0.4),
                0 2px 8px rgba(92,64,51,0.15);
            position: relative;
            overflow: hidden;
            min-height: 560px;
        }
        .book-stage::before {
            /* Faint wood grain */
            content: "";
            position: absolute;
            inset: 0;
            background-image:
                repeating-linear-gradient(90deg,
                    transparent 0, transparent 80px,
                    rgba(0,0,0,0.06) 80px, rgba(0,0,0,0.06) 81px,
                    transparent 81px, transparent 160px,
                    rgba(255,255,255,0.03) 160px, rgba(255,255,255,0.03) 161px);
            pointer-events: none;
            opacity: 0.5;
        }

        .book-shell {
            position: relative;
            max-width: 900px;
            margin: 0 auto;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 16px;
        }

        .book {
            position: relative;
            display: flex;
            flex: 1 1 auto;
            max-width: 760px;
            aspect-ratio: 296 / 210;
            background: transparent;
            filter: drop-shadow(0 18px 30px rgba(0,0,0,0.45));
            transition: max-width 0.25s ease;
        }
        /* Cover-only state: show just the cover, centered, single-page sized */
        .book.cover-only {
            aspect-ratio: 148 / 210;
            max-width: 340px;
            margin: 0 auto;
        }
        .book.cover-only .left-page {
            display: none !important;
        }
        .book.cover-only .book-spine {
            display: none;
        }
        .book.cover-only .right-page.cover-page {
            border-radius: 4px;
            box-shadow:
                inset 0 0 40px rgba(0,0,0,0.35),
                inset 0 0 0 1px rgba(0,0,0,0.2);
        }
        .book-page {
            flex: 1 1 50%;
            background: #fffdf7;
            position: relative;
            padding: 14px 14px 42px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: flex-start;
            box-sizing: border-box;
            overflow: hidden;
        }
        .book-page.left-page {
            border-radius: 4px 0 0 4px;
            box-shadow:
                inset -10px 0 20px -10px rgba(92,64,51,0.25),
                inset 2px 2px 4px rgba(255,255,255,0.5);
        }
        .book-page.right-page {
            border-radius: 0 4px 4px 0;
            box-shadow:
                inset 10px 0 20px -10px rgba(92,64,51,0.25),
                inset -2px 2px 4px rgba(255,255,255,0.5);
        }
        .book-page.blank-page {
            background: #fffdf7;
        }
        .book-page.blank-page::after {
            content: "";
            position: absolute;
            inset: 20% 30%;
            border: 1px dashed rgba(201,168,76,0.25);
            border-radius: 2px;
        }

        /* "Add Page" placeholder — faded cream page, centered + icon */
        .book-page.add-page {
            background:
                repeating-linear-gradient(
                    to bottom,
                    #fffaf0 0, #fffaf0 18px,
                    rgba(201,168,76,0.05) 18px, rgba(201,168,76,0.05) 19px
                );
            cursor: pointer;
            justify-content: center;
            align-items: center;
            color: var(--accent-brown);
            transition: background 0.15s ease, transform 0.08s ease;
        }
        .book-page.add-page:hover {
            background:
                repeating-linear-gradient(
                    to bottom,
                    #fffdf7 0, #fffdf7 18px,
                    rgba(201,168,76,0.10) 18px, rgba(201,168,76,0.10) 19px
                );
        }
        .book-page.add-page::before {
            content: "";
            position: absolute;
            inset: 26px;
            border: 2px dashed rgba(92,64,51,0.28);
            border-radius: 4px;
            pointer-events: none;
            transition: border-color 0.15s ease;
        }
        .book-page.add-page:hover::before {
            border-color: rgba(92,64,51,0.45);
        }
        .book-page.add-page .add-page-inner {
            position: relative;
            text-align: center;
            padding: 20px;
        }
        .book-page.add-page .add-page-plus {
            width: 84px;
            height: 84px;
            border-radius: 50%;
            background: rgba(92,64,51,0.06);
            border: 2px solid rgba(92,64,51,0.30);
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 18px;
            font-size: 2.6rem;
            color: var(--accent-brown);
            transition: background 0.15s ease, transform 0.1s ease;
        }
        .book-page.add-page:hover .add-page-plus {
            background: rgba(92,64,51,0.12);
            transform: scale(1.04);
        }
        .book-page.add-page .add-page-label {
            font-family: var(--font-serif);
            font-size: 1.4rem;
            font-weight: 600;
            color: var(--accent-brown);
            letter-spacing: 0.02em;
            margin-bottom: 4px;
        }
        .book-page.add-page .add-page-hint {
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.85rem;
            color: var(--text-muted);
        }
        .book-spine {
            position: absolute;
            top: 0;
            bottom: 0;
            left: 50%;
            width: 4px;
            transform: translateX(-50%);
            background: linear-gradient(to right,
                rgba(92,64,51,0.35),
                rgba(0,0,0,0.5),
                rgba(92,64,51,0.35));
            pointer-events: none;
            z-index: 2;
            box-shadow: 0 0 4px rgba(0,0,0,0.25);
        }

        .book-page .page-canvas-wrap {
            flex: 1 1 auto;
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 0;
        }
        .book-page canvas.page-canvas {
            width: 100%;
            height: 100%;
            object-fit: contain;
            display: block;
        }
        .book-page .page-meta {
            flex: 0 0 auto;
            width: 100%;
            margin-top: 6px;
            text-align: center;
            font-family: var(--font-serif);
            color: var(--text-muted);
            font-size: 0.78rem;
            font-style: italic;
        }
        .book-page .page-tags {
            display: flex;
            flex-wrap: wrap;
            gap: 4px;
            justify-content: center;
            margin-top: 4px;
        }
        .book-page .page-tags .tag-chip {
            font-size: 0.6rem;
            padding: 1px 6px;
        }
        .book-page .loading {
            color: var(--text-light);
            font-style: italic;
            font-size: 0.8rem;
        }
        .book-page.page-link { cursor: pointer; }
        .book-page.page-link:hover::before {
            content: "";
            position: absolute;
            inset: 0;
            background: rgba(92,64,51,0.06);
            pointer-events: none;
        }

        /* Cover */
        .book-page.cover-page {
            background:
                radial-gradient(circle at 30% 20%, #8b5a3c 0%, #5c3a22 60%, #3e2716 100%);
            color: #f0d8a8;
            justify-content: center;
            align-items: center;
            padding: 40px 24px;
            border-radius: 0 4px 4px 0;
            box-shadow:
                inset 10px 0 24px -10px rgba(0,0,0,0.6),
                inset -4px 0 0 rgba(0,0,0,0.3),
                inset 0 0 40px rgba(0,0,0,0.3);
        }
        .book-page.cover-page::before {
            content: "";
            position: absolute;
            inset: 22px;
            border: 2px double rgba(201,168,76,0.7);
            border-radius: 2px;
            pointer-events: none;
        }
        .book-page.cover-page .cover-title {
            font-family: var(--font-serif);
            font-size: 2.4rem;
            font-weight: 700;
            text-align: center;
            letter-spacing: 0.04em;
            color: #f0d8a8;
            text-shadow: 0 1px 0 rgba(0,0,0,0.4);
            margin-bottom: 12px;
        }
        .book-page.cover-page .cover-flourish {
            color: rgba(201,168,76,0.7);
            font-size: 1.4rem;
            letter-spacing: 0.4em;
        }
        .book-page.cover-page .cover-subtitle {
            margin-top: 14px;
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.9rem;
            color: rgba(240,216,168,0.75);
        }

        /* Nav arrows */
        .book-nav-btn {
            flex: 0 0 auto;
            min-width: 52px;
            min-height: 52px;
            border-radius: 50%;
            background: rgba(255,253,247,0.9);
            border: 1px solid rgba(92,64,51,0.3);
            color: var(--accent-brown);
            font-size: 1.5rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            box-shadow: 0 2px 6px rgba(0,0,0,0.3);
            transition: transform 0.1s ease, background 0.15s ease;
            user-select: none;
        }
        .book-nav-btn:hover {
            background: #fff;
            transform: scale(1.05);
        }
        .book-nav-btn:disabled,
        .book-nav-btn.disabled {
            opacity: 0.3;
            pointer-events: none;
        }

        .book-status {
            text-align: center;
            margin-top: 18px;
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.9rem;
            color: rgba(255,253,247,0.65);
        }
        .book-empty {
            text-align: center;
            padding: 80px 20px;
            color: rgba(255,253,247,0.85);
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 1.05rem;
        }

        /* Mobile/narrow: single page at a time */
        @media (max-width: 720px) {
            .book-stage { padding: 24px 8px; }
            .book-shell { gap: 6px; }
            .book {
                aspect-ratio: 148 / 210;
                max-width: 320px;
            }
            .book-page.left-page {
                display: none !important;
            }
            .book-page.right-page {
                border-radius: 4px;
                box-shadow: inset 2px 2px 4px rgba(255,255,255,0.5);
            }
            .book-spine { display: none; }
            .book-nav-btn {
                min-width: 44px;
                min-height: 44px;
                font-size: 1.2rem;
            }
            .book-page.cover-page {
                border-radius: 4px;
            }
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <div class="container">
            <a class="navbar-brand" href="${pageContext.request.contextPath}/app/dashboard">JotPage</a>
            <div class="d-flex align-items-center ms-auto">
                <img src="${sessionScope.user.avatarUrl}"
                     alt="Avatar"
                     class="rounded-circle me-2"
                     width="36" height="36">
                <span class="me-3">Welcome, ${sessionScope.user.displayName}</span>
                <a class="btn btn-outline-secondary btn-sm"
                   href="${pageContext.request.contextPath}/logout">Logout</a>
            </div>
        </div>
    </nav>

    <main class="container py-5">
        <div class="notebook-header d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
            <div>
                <h1 class="mb-0">My Notebook</h1>
                <div class="subhead">A quiet place for your pages</div>
            </div>
            <div class="d-flex gap-2 align-items-center flex-wrap">
                <div class="view-toggle" role="group" aria-label="View mode">
                    <a href="${bookViewUrl}"
                       class="view-btn ${viewMode == 'book' ? 'active' : ''}"
                       title="Book view">
                        <i class="bi bi-book"></i>
                    </a>
                    <a href="${listViewUrl}"
                       class="view-btn ${viewMode == 'list' ? 'active' : ''}"
                       title="List view">
                        <i class="bi bi-list-ul"></i>
                    </a>
                </div>
                <c:if test="${viewMode == 'list'}">
                    <button type="button" id="reorderToggle" class="btn btn-outline-secondary">
                        <i class="bi bi-arrows-move"></i> Reorder
                    </button>
                </c:if>
                <a href="${pageContext.request.contextPath}/app/voice-record"
                   class="btn btn-outline-primary">
                    <i class="bi bi-mic-fill"></i> Voice Entry
                </a>
                <button type="button" class="btn btn-primary"
                        data-bs-toggle="modal" data-bs-target="#newPageModal">
                    <i class="bi bi-plus-lg"></i> New Page
                </button>
            </div>
        </div>

        <c:if test="${not empty allTags}">
            <div class="tag-filter-bar mb-4 d-flex flex-wrap align-items-center gap-2">
                <span class="text-muted small me-1">Filter:</span>
                <c:forEach var="t" items="${allTags}">
                    <span class="tag-filter-chip" data-tag-id="${t.id}"
                          style="background: <c:out value='${t.color}'/>">
                        <c:out value="${t.name}"/>
                    </span>
                </c:forEach>
                <button type="button" id="clearTagFilter" class="btn btn-link btn-sm text-muted">Clear</button>
                <span id="filterStatus" class="text-muted small ms-2"></span>
            </div>
        </c:if>

        <c:if test="${viewMode == 'book'}">
            <div class="book-stage" id="bookStage">
                <div class="book-shell">
                    <button type="button" id="bookPrev" class="book-nav-btn" title="Previous">
                        <i class="bi bi-chevron-left"></i>
                    </button>
                    <div class="book" id="book">
                        <div class="book-page left-page" id="bookLeftPage"></div>
                        <div class="book-spine"></div>
                        <div class="book-page right-page" id="bookRightPage"></div>
                    </div>
                    <button type="button" id="bookNext" class="book-nav-btn" title="Next">
                        <i class="bi bi-chevron-right"></i>
                    </button>
                </div>
                <div class="book-status" id="bookStatus">&nbsp;</div>
            </div>
        </c:if>

        <c:if test="${viewMode == 'list'}">
        <c:choose>
            <c:when test="${empty pages}">
                <div class="text-muted">No pages yet. Start your notebook with the New Page button.</div>
            </c:when>
            <c:otherwise>
                <div id="pageList" class="notebook-list">
                    <c:forEach var="p" items="${pages}" varStatus="s">
                        <a class="page-entry"
                           data-page-id="${p.id}"
                           data-tag-ids="<c:forEach var='tid' items='${p.tagIds}' varStatus='ts'>${tid}<c:if test='${not ts.last}'>,</c:if></c:forEach>"
                           data-base-href="${pageContext.request.contextPath}/app/page/${p.id}"
                           draggable="false"
                           href="${pageContext.request.contextPath}/app/page/${p.id}">
                            <div class="page-thumb bg-${p.backgroundType}">
                                <c:if test="${p.closed}">
                                    <span class="closed-badge">Closed</span>
                                </c:if>
                            </div>
                            <div class="entry-main">
                                <div class="entry-date"><c:out value="${p.createdAt}"/></div>
                                <div class="entry-meta"><c:out value="${p.typeName}"/></div>
                                <c:if test="${not empty p.tags}">
                                    <div class="entry-tags">
                                        <c:forEach var="t" items="${p.tags}">
                                            <span class="tag-chip" style="background: <c:out value='${t.color}'/>">
                                                <c:out value="${t.name}"/>
                                            </span>
                                        </c:forEach>
                                    </div>
                                </c:if>
                            </div>
                            <div class="entry-order">#${s.index + 1}</div>
                        </a>
                    </c:forEach>
                </div>
            </c:otherwise>
        </c:choose>
        </c:if>
    </main>

    <div class="modal fade" id="newPageModal" tabindex="-1" aria-labelledby="newPageModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="newPageModalLabel">Choose a page template</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <div id="templateAlert" class="template-alert" role="alert">
                        <button type="button" class="alert-close" id="templateAlertClose" aria-label="Dismiss">&times;</button>
                        <span id="templateAlertMsg"></span>
                    </div>

                    <div id="pageTypesList" class="list-group">
                        <div class="text-muted small">Loading templates...</div>
                    </div>

                    <div class="custom-template-section">
                        <h6>Create a custom template</h6>
                        <div class="hint">Upload a PNG to use as the page background.</div>

                        <form id="customTemplateForm" novalidate>
                            <div class="mb-2">
                                <label for="ct-name">Template name</label>
                                <input type="text"
                                       id="ct-name"
                                       class="form-control"
                                       maxlength="100"
                                       placeholder="e.g. My Bullet Journal">
                            </div>

                            <div class="mb-2">
                                <label>Background image (PNG, max 5&nbsp;MB)</label>
                                <div class="drop-zone" id="ct-drop-zone">
                                    <div class="drop-zone-label" id="ct-drop-label">
                                        Click to choose a PNG file
                                    </div>
                                    <input type="file" id="ct-file" accept=".png,image/png">
                                </div>
                                <div class="preview-wrap" id="ct-preview-wrap">
                                    <img id="ct-preview-img" alt="Preview">
                                    <div class="preview-meta" id="ct-preview-meta"></div>
                                </div>
                            </div>

                            <div class="form-check mb-3">
                                <input type="checkbox" class="form-check-input" id="ct-immutable">
                                <label class="form-check-label" for="ct-immutable">
                                    Lock pages on close
                                </label>
                            </div>

                            <div class="d-flex align-items-center gap-2">
                                <button type="submit" id="ct-submit" class="btn btn-primary">
                                    Create Template
                                </button>
                                <span class="error-msg" id="ct-error"></span>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        window.CONTEXT_PATH = '${pageContext.request.contextPath}';
        window.JOTPAGE_VIEW_MODE = '${viewMode}';
        window.BOOK_PAGES = ${pagesJson};
    </script>
    <c:if test="${viewMode == 'book'}">
        <script src="${pageContext.request.contextPath}/js/book-view.js"></script>
    </c:if>
    <script>
        (function () {
            var ctx = '${pageContext.request.contextPath}';
            var modal = document.getElementById('newPageModal');
            var listEl = document.getElementById('pageTypesList');
            var templatesLoaded = false;

            var alertEl = document.getElementById('templateAlert');
            var alertMsg = document.getElementById('templateAlertMsg');
            var alertClose = document.getElementById('templateAlertClose');

            function showTemplateAlert(msg) {
                alertMsg.textContent = msg;
                alertEl.classList.add('visible');
            }
            function hideTemplateAlert() {
                alertEl.classList.remove('visible');
                alertMsg.textContent = '';
            }
            if (alertClose) alertClose.addEventListener('click', hideTemplateAlert);
            modal.addEventListener('hidden.bs.modal', hideTemplateAlert);

            function renderTemplates(types) {
                listEl.innerHTML = '';
                if (!types || types.length === 0) {
                    listEl.innerHTML = '<div class="text-muted small">No templates available.</div>';
                    return;
                }
                types.forEach(function (t) {
                    var row = document.createElement('div');
                    row.className = 'list-group-item d-flex justify-content-between align-items-center';

                    var link = document.createElement('a');
                    link.className = 'flex-grow-1 text-decoration-none text-reset';
                    link.href = ctx + '/app/page/new?typeId=' + t.id;
                    link.innerHTML =
                        '<strong>' + escapeHtml(t.name) + '</strong>' +
                        '<br><small class="text-muted">' + escapeHtml(t.backgroundType) + '</small>';
                    row.appendChild(link);

                    if (t.immutableOnClose) {
                        var badge = document.createElement('span');
                        badge.className = 'badge bg-warning text-dark me-2';
                        badge.textContent = 'Locks on close';
                        row.appendChild(badge);
                    }

                    // Delete button for user-owned templates only (never system)
                    if (t.system === false && t.userId != null) {
                        var del = document.createElement('button');
                        del.type = 'button';
                        del.className = 'delete-template-btn';
                        del.title = 'Delete template';
                        del.innerHTML = '<i class="bi bi-x-lg"></i>';
                        del.addEventListener('click', function (e) {
                            e.preventDefault();
                            e.stopPropagation();
                            hideTemplateAlert();
                            if (!confirm('Delete this template? Pages that already use it will remain but you can no longer create new ones with it.')) return;
                            fetch(ctx + '/app/api/pagetypes/' + t.id, {
                                method: 'DELETE',
                                credentials: 'same-origin'
                            }).then(function (r) {
                                if (r.ok || r.status === 204) {
                                    refreshTemplates();
                                    return;
                                }
                                if (r.status === 409) {
                                    return r.json().then(function (body) {
                                        showTemplateAlert(body && body.error
                                            ? body.error
                                            : 'This template is still in use.');
                                    }).catch(function () {
                                        showTemplateAlert('This template is still in use.');
                                    });
                                }
                                showTemplateAlert('Failed to delete template (' + r.status + ').');
                            }).catch(function (err) {
                                showTemplateAlert('Network error: ' + err.message);
                            });
                        });
                        row.appendChild(del);
                    }

                    listEl.appendChild(row);
                });
            }

            function refreshTemplates() {
                return fetch(ctx + '/app/api/pagetypes', { credentials: 'same-origin' })
                    .then(function (r) { return r.json(); })
                    .then(function (types) {
                        templatesLoaded = true;
                        renderTemplates(types);
                    })
                    .catch(function () {
                        listEl.innerHTML = '<div class="text-danger small">Failed to load templates.</div>';
                    });
            }

            modal.addEventListener('show.bs.modal', function () {
                if (!templatesLoaded) refreshTemplates();
            });

            // -------- Custom template creation --------
            var ctForm = document.getElementById('customTemplateForm');
            var ctName = document.getElementById('ct-name');
            var ctFile = document.getElementById('ct-file');
            var ctDropLabel = document.getElementById('ct-drop-label');
            var ctPreviewWrap = document.getElementById('ct-preview-wrap');
            var ctPreviewImg = document.getElementById('ct-preview-img');
            var ctPreviewMeta = document.getElementById('ct-preview-meta');
            var ctImmutable = document.getElementById('ct-immutable');
            var ctSubmit = document.getElementById('ct-submit');
            var ctError = document.getElementById('ct-error');

            var MAX_BYTES = 5 * 1024 * 1024;

            function showError(msg) {
                ctError.textContent = msg;
                ctError.classList.add('visible');
            }
            function clearError() {
                ctError.textContent = '';
                ctError.classList.remove('visible');
            }

            ctFile.addEventListener('change', function () {
                clearError();
                var file = ctFile.files && ctFile.files[0];
                if (!file) {
                    ctPreviewWrap.classList.remove('visible');
                    ctDropLabel.textContent = 'Click to choose a PNG file';
                    return;
                }
                if (!/\.png$/i.test(file.name) && file.type !== 'image/png') {
                    showError('File must be a PNG.');
                    ctFile.value = '';
                    ctPreviewWrap.classList.remove('visible');
                    return;
                }
                if (file.size > MAX_BYTES) {
                    showError('File is ' + (file.size / 1024 / 1024).toFixed(1)
                        + ' MB. Max is 5 MB.');
                    ctFile.value = '';
                    ctPreviewWrap.classList.remove('visible');
                    return;
                }
                var reader = new FileReader();
                reader.onload = function (e) {
                    ctPreviewImg.src = e.target.result;
                    ctPreviewMeta.textContent = file.name + ' (' + (file.size / 1024).toFixed(0) + ' KB)';
                    ctPreviewWrap.classList.add('visible');
                    ctDropLabel.textContent = 'Click to choose a different file';
                };
                reader.readAsDataURL(file);
            });

            ctForm.addEventListener('submit', function (e) {
                e.preventDefault();
                clearError();

                var name = (ctName.value || '').trim();
                if (!name) {
                    showError('Please enter a template name.');
                    ctName.focus();
                    return;
                }
                var file = ctFile.files && ctFile.files[0];
                if (!file) {
                    showError('Please choose a PNG file.');
                    return;
                }
                if (!/\.png$/i.test(file.name) && file.type !== 'image/png') {
                    showError('File must be a PNG.');
                    return;
                }
                if (file.size > MAX_BYTES) {
                    showError('File too large (max 5 MB).');
                    return;
                }

                var fd = new FormData();
                fd.append('name', name);
                fd.append('immutableOnClose', ctImmutable.checked ? 'true' : 'false');
                fd.append('backgroundImage', file);

                ctSubmit.disabled = true;
                ctSubmit.textContent = 'Uploading…';
                fetch(ctx + '/app/api/pagetypes', {
                    method: 'POST',
                    credentials: 'same-origin',
                    body: fd
                }).then(function (r) {
                    ctSubmit.disabled = false;
                    ctSubmit.textContent = 'Create Template';
                    if (r.ok || r.status === 201) {
                        ctForm.reset();
                        ctPreviewWrap.classList.remove('visible');
                        ctDropLabel.textContent = 'Click to choose a PNG file';
                        refreshTemplates();
                    } else {
                        return r.text().then(function (t) {
                            showError('Upload failed: ' + (t || r.statusText));
                        });
                    }
                }).catch(function (err) {
                    ctSubmit.disabled = false;
                    ctSubmit.textContent = 'Create Template';
                    showError('Upload failed: ' + err.message);
                });
            });

            function escapeHtml(s) {
                return (s == null ? '' : String(s))
                    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
            }

            // ------------------------------------------------------------------
            // Tag filter (UNION / OR)
            // ------------------------------------------------------------------
            var activeTagIds = [];
            var filterChips = document.querySelectorAll('.tag-filter-chip');
            var entries = document.querySelectorAll('.page-entry');
            var clearBtn = document.getElementById('clearTagFilter');
            var filterStatus = document.getElementById('filterStatus');

            function currentTagSuffix() {
                return activeTagIds.length ? '?tags=' + activeTagIds.join(',') : '';
            }

            function updateEntryHrefs() {
                var suffix = currentTagSuffix();
                entries.forEach(function (card) {
                    var base = card.getAttribute('data-base-href');
                    if (base) card.setAttribute('href', base + suffix);
                });
            }

            function applyFilter() {
                if (entries.length > 0) {
                    var shown = 0;
                    var total = entries.length;
                    entries.forEach(function (card) {
                        if (activeTagIds.length === 0) {
                            card.style.display = '';
                            shown++;
                            return;
                        }
                        var raw = card.getAttribute('data-tag-ids') || '';
                        var ids = raw ? raw.split(',').filter(Boolean) : [];
                        var hasAny = activeTagIds.some(function (tid) {
                            return ids.indexOf(String(tid)) !== -1;
                        });
                        if (hasAny) {
                            card.style.display = '';
                            shown++;
                        } else {
                            card.style.display = 'none';
                        }
                    });
                    updateEntryHrefs();
                    if (filterStatus) {
                        filterStatus.textContent = activeTagIds.length
                            ? 'Showing ' + shown + ' of ' + total + ' pages'
                            : '';
                    }
                }

                // Book view responds to the same filter state
                if (window.bookView && typeof window.bookView.setFilter === 'function') {
                    var count = window.bookView.setFilter(activeTagIds.slice());
                    if (filterStatus && entries.length === 0) {
                        filterStatus.textContent = activeTagIds.length
                            ? 'Showing ' + count.shown + ' of ' + count.total + ' pages'
                            : '';
                    }
                }
            }

            filterChips.forEach(function (chip) {
                chip.addEventListener('click', function () {
                    var tid = chip.getAttribute('data-tag-id');
                    var idx = activeTagIds.indexOf(tid);
                    if (idx >= 0) {
                        activeTagIds.splice(idx, 1);
                        chip.classList.remove('active');
                    } else {
                        activeTagIds.push(tid);
                        chip.classList.add('active');
                    }
                    applyFilter();
                });
            });

            if (clearBtn) {
                clearBtn.addEventListener('click', function () {
                    activeTagIds = [];
                    filterChips.forEach(function (c) { c.classList.remove('active'); });
                    applyFilter();
                });
            }

            // Restore filter state from ?tags=... in the URL (e.g. returning
            // from the editor with a filter preserved).
            (function initFilterFromUrl() {
                var params = new URLSearchParams(window.location.search);
                var raw = params.get('tags');
                if (!raw) {
                    updateEntryHrefs();
                    return;
                }
                var wanted = raw.split(',').map(function (s) { return s.trim(); }).filter(Boolean);
                var valid = {};
                filterChips.forEach(function (c) { valid[c.getAttribute('data-tag-id')] = c; });
                wanted.forEach(function (tid) {
                    if (valid[tid] && activeTagIds.indexOf(tid) === -1) {
                        activeTagIds.push(tid);
                        valid[tid].classList.add('active');
                    }
                });
                applyFilter();
            })();

            // ------------------------------------------------------------------
            // Reorder mode (list view only)
            // ------------------------------------------------------------------
            var reorderToggle = document.getElementById('reorderToggle');
            var pageList = document.getElementById('pageList');
            var reordering = false;
            var draggingEl = null;

            function setReordering(on) {
                reordering = on;
                document.body.classList.toggle('reorder-mode', on);
                document.body.classList.toggle('reorder-active', on);
                if (reorderToggle) {
                    reorderToggle.classList.toggle('btn-outline-secondary', !on);
                    reorderToggle.classList.toggle('btn-warning', on);
                    reorderToggle.innerHTML = on
                        ? '<i class="bi bi-check-lg"></i> Done'
                        : '<i class="bi bi-arrows-move"></i> Reorder';
                }
                entries.forEach(function (e) {
                    e.setAttribute('draggable', on ? 'true' : 'false');
                });
            }

            if (reorderToggle) {
                reorderToggle.addEventListener('click', function () {
                    setReordering(!reordering);
                });
            }

            // Prevent nav when in reorder mode so drag/click doesn't open the page
            entries.forEach(function (entry) {
                entry.addEventListener('click', function (e) {
                    if (reordering) e.preventDefault();
                });

                entry.addEventListener('dragstart', function (e) {
                    if (!reordering) { e.preventDefault(); return; }
                    draggingEl = entry;
                    entry.classList.add('dragging');
                    if (e.dataTransfer) {
                        e.dataTransfer.effectAllowed = 'move';
                        e.dataTransfer.setData('text/plain', entry.getAttribute('data-page-id'));
                    }
                });

                entry.addEventListener('dragend', function () {
                    if (draggingEl) draggingEl.classList.remove('dragging');
                    draggingEl = null;
                    entries.forEach(function (e) { e.classList.remove('drag-over'); });
                });

                entry.addEventListener('dragover', function (e) {
                    if (!reordering || !draggingEl || entry === draggingEl) return;
                    e.preventDefault();
                    if (e.dataTransfer) e.dataTransfer.dropEffect = 'move';
                    entry.classList.add('drag-over');
                });

                entry.addEventListener('dragleave', function () {
                    entry.classList.remove('drag-over');
                });

                entry.addEventListener('drop', function (e) {
                    if (!reordering || !draggingEl) return;
                    e.preventDefault();
                    entry.classList.remove('drag-over');
                    if (draggingEl === entry) return;
                    // Insert draggingEl before the target
                    var rect = entry.getBoundingClientRect();
                    var isBelow = (e.clientY - rect.top) > rect.height / 2;
                    if (isBelow) {
                        pageList.insertBefore(draggingEl, entry.nextSibling);
                    } else {
                        pageList.insertBefore(draggingEl, entry);
                    }
                    persistOrder();
                });
            });

            function persistOrder() {
                var ids = Array.prototype.map.call(
                    pageList.querySelectorAll('.page-entry'),
                    function (el) { return parseInt(el.getAttribute('data-page-id'), 10); }
                );
                // Update the "#n" labels immediately
                Array.prototype.forEach.call(
                    pageList.querySelectorAll('.entry-order'),
                    function (el, idx) { el.textContent = '#' + (idx + 1); }
                );
                fetch(ctx + '/app/page/reorder', {
                    method: 'PUT',
                    credentials: 'same-origin',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ pageIds: ids })
                }).catch(function (err) {
                    console.error('[dashboard] reorder failed', err);
                });
            }
        })();
    </script>
</body>
</html>
