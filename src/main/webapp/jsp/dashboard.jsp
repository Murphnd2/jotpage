<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Jyrnyl — Record your life.</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/theme.css" rel="stylesheet">
    <%@ include file="/WEB-INF/jspf/pwa-head.jspf" %>
    <style>
        html, body { height: 100%; }
        body {
            margin: 0;
            background:
                radial-gradient(circle at 15% 10%, rgba(212,148,58,0.06), transparent 40%),
                radial-gradient(circle at 90% 90%, rgba(160,82,45,0.04), transparent 45%),
                var(--bg-cream);
        }

        /* -------------------------------------------------------------- */
        /* List view top bar: Done button + optional tag filter          */
        /* -------------------------------------------------------------- */
        .list-top-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            padding: 20px 24px 8px;
            max-width: 960px;
            margin: 0 auto;
            flex-wrap: wrap;
        }
        .list-top-bar .list-heading {
            font-family: var(--font-serif);
            font-size: 1.5rem;
            color: var(--accent-brown);
            letter-spacing: 0.01em;
            margin: 0;
        }
        .list-top-bar .list-subhead {
            font-family: var(--font-serif);
            font-style: italic;
            color: var(--text-muted);
            font-size: 0.9rem;
            margin-top: 2px;
        }
        .list-top-bar .done-btn {
            min-height: 44px;
            padding: 0 18px;
            font-family: var(--font-serif);
            font-size: 1rem;
        }

        .list-container {
            max-width: 960px;
            margin: 0 auto;
            padding: 0 24px 80px;
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
        .tag-filter-bar {
            padding: 6px 0 14px;
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 8px;
        }
        .tag-filter-bar .small {
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.9rem;
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
        .page-entry .entry-main { flex: 1 1 auto; min-width: 0; }
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
        .page-entry .delete-page-btn {
            position: absolute;
            top: 6px;
            right: 6px;
            width: 26px;
            height: 26px;
            border-radius: 50%;
            border: none;
            background: transparent;
            color: var(--text-muted);
            font-size: 0.8rem;
            display: flex;
            align-items: center;
            justify-content: center;
            opacity: 0;
            cursor: pointer;
            transition: opacity 0.15s ease, background 0.15s ease, color 0.15s ease;
            z-index: 2;
        }
        .page-entry:hover .delete-page-btn { opacity: 0.6; }
        .page-entry .delete-page-btn:hover {
            opacity: 1;
            background: rgba(160,82,45,0.12);
            color: var(--accent-burgundy);
        }

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
                0 1px 0 rgba(74,55,40,0.04),
                1px 2px 5px rgba(74,55,40,0.10);
            transform: rotate(-1.2deg);
        }
        .page-thumb::after {
            content: "";
            position: absolute;
            top: -4px;
            left: 50%;
            width: 28px;
            height: 10px;
            background: rgba(212,148,58,0.28);
            border: 1px solid rgba(212,148,58,0.35);
            transform: translateX(-50%) rotate(-4deg);
            border-radius: 1px;
        }
        .page-thumb.bg-lined {
            background-image: repeating-linear-gradient(
                to bottom, #fffdf7 0, #fffdf7 10px, #d9c9a8 10px, #d9c9a8 11px);
        }
        .page-thumb.bg-dot_grid {
            background-image: radial-gradient(#c4b088 1px, transparent 1.5px);
            background-size: 10px 10px;
        }
        .page-thumb.bg-graph {
            background-image:
                linear-gradient(to right, #e8d9b8 1px, transparent 1px),
                linear-gradient(to bottom, #e8d9b8 1px, transparent 1px);
            background-size: 10px 10px;
        }
        .page-thumb .closed-badge {
            position: absolute;
            bottom: 2px;
            right: 2px;
            background: rgba(74,55,40,0.85);
            color: #fff;
            font-size: 0.55rem;
            padding: 1px 4px;
            border-radius: 2px;
            letter-spacing: 0.04em;
        }

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
            background: rgba(212,148,58,0.12);
        }
        body.reorder-mode .page-entry.dragging {
            opacity: 0.45;
        }

        /* Template grid */
        .template-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 10px;
        }
        @media (max-width: 400px) {
            .template-grid { grid-template-columns: repeat(2, 1fr); }
        }
        .template-card {
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 14px 10px;
            border: 1px solid var(--border-warm);
            border-radius: var(--radius-md);
            background: var(--bg-card);
            cursor: pointer;
            text-decoration: none;
            color: var(--accent-brown);
            font-family: var(--font-serif);
            font-weight: 600;
            font-size: 0.95rem;
            transition: background 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease;
            position: relative;
            min-height: 56px;
            overflow: hidden;
            word-break: break-word;
            line-height: 1.25;
        }
        .template-card:hover {
            background: var(--bg-cream-dark);
            border-color: var(--accent-gold);
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            color: var(--accent-brown);
        }
        .template-card.dragging { opacity: 0.4; }
        .template-card.drag-over {
            border-color: var(--accent-gold);
            background: rgba(196,164,105,0.12);
        }
        .template-card .delete-template-btn {
            position: absolute;
            top: 2px;
            right: 4px;
            background: transparent;
            border: 0;
            color: var(--text-muted);
            font-size: 0.75rem;
            padding: 2px 5px;
            border-radius: var(--radius-sm);
            opacity: 0;
            transition: opacity 0.15s ease, color 0.15s ease, background 0.15s ease;
            cursor: pointer;
        }
        .template-card:hover .delete-template-btn { opacity: 0.6; }
        .template-card .delete-template-btn:hover {
            opacity: 1;
            color: var(--accent-burgundy);
            background: rgba(124, 50, 56, 0.08);
        }
        .tag-manage-row {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 6px 8px;
            border: 1px solid var(--border-warm);
            border-radius: var(--radius-md);
            background: var(--bg-card);
        }
        .tag-manage-row .tag-color-input {
            width: 28px;
            height: 28px;
            padding: 0;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-sm);
            cursor: pointer;
        }
        .tag-manage-row .tag-name-input {
            flex: 1;
            border: 1px solid transparent;
            background: transparent;
            font-size: 0.9rem;
            padding: 2px 6px;
            border-radius: var(--radius-sm);
            color: var(--text-dark);
        }
        .tag-manage-row .tag-name-input:focus {
            border-color: var(--border-warm-strong);
            background: var(--bg-card-raised);
            outline: none;
        }
        .tag-manage-row .tag-page-count {
            font-size: 0.75rem;
            color: var(--text-muted);
            white-space: nowrap;
        }
        .tag-manage-row .tag-save-btn {
            display: none;
            font-size: 0.75rem;
        }
        .tag-manage-row.dirty .tag-save-btn { display: inline-block; }
        .tag-manage-row .tag-delete-btn {
            background: transparent;
            border: 0;
            color: var(--text-muted);
            font-size: 0.8rem;
            padding: 2px 6px;
            border-radius: var(--radius-sm);
            cursor: pointer;
            opacity: 0.5;
            transition: opacity 0.15s ease, color 0.15s ease;
        }
        .tag-manage-row .tag-delete-btn:hover {
            opacity: 1;
            color: var(--accent-burgundy);
        }
        .template-card-voice {
            border-style: dashed;
            gap: 6px;
        }
        .template-card .lock-icon {
            position: absolute;
            bottom: 3px;
            right: 5px;
            font-size: 0.7rem;
            opacity: 0.45;
            color: var(--accent-brown);
        }

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
        /* Book view — leather desk fills the viewport                   */
        /* -------------------------------------------------------------- */
        .book-stage {
            position: relative;
            background:
                radial-gradient(circle at 50% 40%, #5a3d28 0%, #3e2a1a 60%, #281a0e 100%);
            overflow: hidden;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            width: 100%;
            min-height: 100vh;
            min-height: 100dvh;
            box-sizing: border-box;
            padding: 40px 24px;
        }
        .book-stage::before {
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
        .book-stage.cover-landing {
            padding: 0;
        }

        .book-shell {
            position: relative;
            width: 100%;
            max-width: 900px;
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
            transition: max-width 0.25s ease, aspect-ratio 0.25s ease;
        }
        /* Cover-only / landing: single-page sized, centered, scaled up */
        .book.cover-only {
            aspect-ratio: 148 / 210;
            max-width: min(420px, 72vh);
            margin: 0 auto;
            cursor: pointer;
        }
        .book.cover-only .left-page {
            display: none !important;
        }
        .book.cover-only .book-spine {
            display: none;
        }
        .book.cover-only .right-page.cover-page {
            border-radius: 6px;
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
                inset -10px 0 20px -10px rgba(74,55,40,0.25),
                inset 2px 2px 4px rgba(255,255,255,0.5);
        }
        .book-page.right-page {
            border-radius: 0 4px 4px 0;
            box-shadow:
                inset 10px 0 20px -10px rgba(74,55,40,0.25),
                inset -2px 2px 4px rgba(255,255,255,0.5);
        }
        .book-page.blank-page {
            background: #fffdf7;
        }
        .book-page.blank-page::after {
            content: "";
            position: absolute;
            inset: 20% 30%;
            border: 1px dashed rgba(212,148,58,0.25);
            border-radius: 2px;
        }

        /* "Add Page" placeholder */
        .book-page.add-page {
            background:
                repeating-linear-gradient(
                    to bottom,
                    #fffaf0 0, #fffaf0 18px,
                    rgba(212,148,58,0.05) 18px, rgba(212,148,58,0.05) 19px
                );
            cursor: pointer;
            justify-content: center;
            align-items: center;
            color: var(--accent-brown);
            transition: background 0.15s ease;
        }
        .book-page.add-page:hover {
            background:
                repeating-linear-gradient(
                    to bottom,
                    #fffdf7 0, #fffdf7 18px,
                    rgba(212,148,58,0.10) 18px, rgba(212,148,58,0.10) 19px
                );
        }
        .book-page.add-page::before {
            content: "";
            position: absolute;
            inset: 26px;
            border: 2px dashed rgba(74,55,40,0.28);
            border-radius: 4px;
            pointer-events: none;
            transition: border-color 0.15s ease;
        }
        .book-page.add-page:hover::before { border-color: rgba(74,55,40,0.45); }
        .book-page.add-page .add-page-inner {
            position: relative;
            text-align: center;
            padding: 20px;
        }
        .book-page.add-page .add-page-plus {
            width: 84px;
            height: 84px;
            border-radius: 50%;
            background: rgba(74,55,40,0.06);
            border: 2px solid rgba(74,55,40,0.30);
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 18px;
            font-size: 2.6rem;
            color: var(--accent-brown);
            transition: background 0.15s ease, transform 0.1s ease;
        }
        .book-page.add-page:hover .add-page-plus {
            background: rgba(74,55,40,0.12);
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
                rgba(74,55,40,0.35),
                rgba(0,0,0,0.5),
                rgba(74,55,40,0.35));
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
            background: rgba(74,55,40,0.06);
            pointer-events: none;
        }

        /* -------------------------------------------------------------- */
        /* Cover — gold-stamped vinyl emblem on leather                  */
        /* -------------------------------------------------------------- */
        .book-page.cover-page {
            background:
                radial-gradient(circle at 30% 18%, #7a4e30 0%, #4a3728 58%, #2e2018 100%);
            color: #f0d8a8;
            justify-content: center;
            align-items: center;
            padding: 36px 28px 22px;
            border-radius: 0 4px 4px 0;
            box-shadow:
                inset 10px 0 24px -10px rgba(0,0,0,0.6),
                inset -4px 0 0 rgba(0,0,0,0.3),
                inset 0 0 40px rgba(0,0,0,0.35);
        }
        .book-page.cover-page::before {
            content: "";
            position: absolute;
            inset: 22px;
            border: 1.5px double rgba(212,148,58,0.65);
            border-radius: 3px;
            pointer-events: none;
        }
        .book-page.cover-page::after {
            /* Faint embossed inner frame — bottom pushed up so the footer
               sits between the two border frames without overlapping */
            content: "";
            position: absolute;
            top: 32px;
            left: 32px;
            right: 32px;
            bottom: 56px;
            border: 1px solid rgba(212,148,58,0.18);
            border-radius: 2px;
            pointer-events: none;
        }
        .cover-emblem {
            flex: 0 1 auto;
            max-width: min(70%, 280px);
            margin: auto 0;
            padding: 0;
        }
        .cover-emblem img {
            width: 100%;
            height: auto;
            display: block;
            border-radius: 6px;
            /* Gold-foil stamp effect: sepia tint + screen blend mode makes
               the dark SVG background vanish into the leather and renders
               the light elements (wordmark, record grooves, needle) as
               warm gold tones stamped onto the cover. */
            mix-blend-mode: screen;
            filter:
                sepia(0.6)
                saturate(2.2)
                brightness(0.75)
                contrast(1.1);
            opacity: 0.85;
        }
        .cover-footer {
            flex: 0 0 auto;
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            /* Sit between the outer (22px) and inner (32px) border frames */
            padding: 0 36px;
            margin-top: auto;
            margin-bottom: 2px;
            color: rgba(240,216,168,0.78);
            font-family: var(--font-serif);
            font-size: 0.82rem;
            font-style: italic;
            position: relative;
            z-index: 1;
        }
        .cover-footer .cover-avatar {
            width: 22px;
            height: 22px;
            border-radius: 50%;
            border: 1px solid rgba(212,148,58,0.35);
            background: rgba(0,0,0,0.3);
            object-fit: cover;
            flex: 0 0 auto;
        }
        .cover-footer .cover-name {
            color: rgba(240,216,168,0.85);
            font-style: normal;
            font-weight: 500;
            max-width: 180px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .cover-footer .cover-count {
            color: rgba(240,216,168,0.5);
            font-size: 0.75rem;
        }
        .book.cover-only .cover-emblem {
            max-width: min(72%, 340px);
        }

        /* Nav arrows inside book view (hidden until book is opened) */
        .book-nav-btn {
            flex: 0 0 auto;
            min-width: 52px;
            min-height: 52px;
            border-radius: 50%;
            background: rgba(255,253,247,0.9);
            border: 1px solid rgba(74,55,40,0.3);
            color: var(--accent-brown);
            font-size: 1.5rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            box-shadow: 0 2px 6px rgba(0,0,0,0.3);
            transition: transform 0.1s ease, background 0.15s ease, opacity 0.2s ease;
            user-select: none;
        }
        .book-nav-btn:hover { background: #fff; transform: scale(1.05); }
        .book-nav-btn:disabled,
        .book-nav-btn.disabled {
            opacity: 0.3;
            pointer-events: none;
        }
        body.cover-landing-state .book-nav-btn {
            opacity: 0;
            pointer-events: none;
        }

        .book-status {
            text-align: center;
            margin-top: 18px;
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.9rem;
            color: rgba(255,253,247,0.65);
            min-height: 1.4em;
            transition: opacity 0.2s ease;
        }
        body.cover-landing-state .book-status {
            opacity: 0;
        }
        .book-empty {
            text-align: center;
            padding: 80px 20px;
            color: rgba(255,253,247,0.85);
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 1.05rem;
        }

        /* "Tap to open" hint on the cover landing */
        .cover-tap-hint {
            position: absolute;
            left: 0;
            right: 0;
            bottom: calc(env(safe-area-inset-bottom, 0) + 20px);
            text-align: center;
            color: rgba(240, 216, 168, 0.75);
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.9rem;
            letter-spacing: 0.03em;
            pointer-events: none;
            z-index: 3;
            animation: cover-pulse 2.8s ease-in-out infinite;
        }
        body:not(.cover-landing-state) .cover-tap-hint { display: none; }
        @keyframes cover-pulse {
            0%, 100% { opacity: 0.45; transform: translateY(0); }
            50%      { opacity: 1;    transform: translateY(-3px); }
        }

        @media (max-width: 720px) {
            .book-stage { padding: 24px 8px; }
            .book-shell { gap: 6px; }
            .book {
                aspect-ratio: 148 / 210;
                max-width: 320px;
            }
            .book-page.left-page { display: none !important; }
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
            .book-page.cover-page { border-radius: 4px; }
        }
    </style>
</head>
<body class="${isPro ? 'tier-pro' : 'tier-free'}"
      data-page="dashboard"
      data-view-mode="${viewMode}">

<c:if test="${viewMode == 'book'}">
    <div class="book-stage" id="bookStage">
        <div class="book-shell">
            <button type="button" id="bookFirst" class="book-nav-btn" title="First page">
                <i class="bi bi-chevron-double-left"></i>
            </button>
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
            <button type="button" id="bookLast" class="book-nav-btn" title="Last page">
                <i class="bi bi-chevron-double-right"></i>
            </button>
        </div>
        <div class="book-status" id="bookStatus">&nbsp;</div>
        <div class="cover-tap-hint" id="coverTapHint">Tap the cover to open &middot; swipe to turn the page</div>
    </div>
</c:if>

<c:if test="${viewMode == 'list'}">
    <div class="list-top-bar">
        <div>
            <h1 class="list-heading">Sort your pages</h1>
            <div class="list-subhead">Drag to reorder &middot; tap a page to open it</div>
        </div>
        <div class="d-flex gap-2 align-items-center">
            <button type="button" id="reorderToggle" class="btn btn-outline-secondary">
                <i class="bi bi-arrows-move"></i> Reorder
            </button>
            <a href="${pageContext.request.contextPath}/app/dashboard"
               class="btn btn-primary done-btn">
                <i class="bi bi-journal-bookmark-fill"></i> Done
            </a>
        </div>
    </div>

    <div class="list-container">
        <c:if test="${not empty allTags}">
            <div class="tag-filter-bar">
                <span class="text-muted small me-1">Filter:</span>
                <c:forEach var="t" items="${allTags}">
                    <span class="tag-filter-chip" data-tag-id="${t.id}"
                          style="background: <c:out value='${t.color}'/>">
                        <c:out value="${t.name}"/>
                    </span>
                </c:forEach>
                <button type="button" id="clearTagFilter" class="btn btn-link btn-sm text-muted">Clear</button>
                <button type="button" id="manageTagsBtn" class="btn btn-link btn-sm text-muted"
                        data-bs-toggle="modal" data-bs-target="#manageTagsModal">
                    <i class="bi bi-gear-fill"></i> Manage
                </button>
                <span id="filterStatus" class="text-muted small ms-2"></span>
            </div>
        </c:if>

        <c:choose>
            <c:when test="${empty pages}">
                <div class="text-muted">No pages yet. Drop your first track with the bubble menu.</div>
            </c:when>
            <c:otherwise>
                <div id="pageList" class="notebook-list">
                    <c:forEach var="p" items="${pages}" varStatus="s">
                        <a class="page-entry"
                           data-page-id="${p.id}"
                           data-locked="${p.locked}"
                           data-tag-ids="<c:forEach var='tid' items='${p.tagIds}' varStatus='ts'>${tid}<c:if test='${not ts.last}'>,</c:if></c:forEach>"
                           data-base-href="${pageContext.request.contextPath}/app/page/${p.id}"
                           draggable="false"
                           href="${pageContext.request.contextPath}/app/page/${p.id}">
                            <button type="button" class="delete-page-btn"
                                    title="Delete page"
                                    data-page-id="${p.id}"
                                    data-locked="${p.locked}">
                                <i class="bi bi-trash3"></i>
                            </button>
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
    </div>
</c:if>

<%-- Floating bubble menu (Phase 5) --%>
<%@ include file="/WEB-INF/jspf/bubble-menu.jspf" %>

<%-- New page modal --%>
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
                <div id="pageTypesList" class="template-grid">
                    <div class="text-muted small">Loading templates...</div>
                </div>
                <div class="custom-template-section">
                    <h6>Create a custom template
                        <c:if test="${!isPro}">
                            <span class="text-muted small" style="font-weight:400">(${customTemplateCount} / ${customTemplateLimit})</span>
                        </c:if>
                    </h6>
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
                            <label>Background image (PNG, max 5&nbsp;MB, 1480&times;2100&nbsp;px recommended)</label>
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

<%-- Delete page confirmation modal --%>
<div class="modal fade" id="deletePageModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Delete page?</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <p id="deletePageMsg">This page will be permanently deleted.</p>
                <div id="deleteLockedWrap" style="display:none">
                    <p class="text-danger small mb-2">
                        This page is locked. Type <strong>DELETE</strong> to confirm.
                    </p>
                    <input type="text" id="deleteConfirmInput" class="form-control form-control-sm"
                           placeholder="Type DELETE" autocomplete="off">
                </div>
            </div>
            <div class="modal-footer justify-content-between">
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal" autofocus>No, keep it</button>
                <button type="button" class="btn btn-danger" id="deletePageConfirmBtn" disabled>Yes, delete</button>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<%-- Tag management modal --%>
<div class="modal fade" id="manageTagsModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Manage Tags</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div id="tagManageList" class="d-flex flex-column gap-2">
                    <div class="text-muted small">Loading...</div>
                </div>
                <div id="tagDeleteInUse" class="mt-3 p-3 border rounded" style="display:none; background: var(--bg-cream-dark);">
                    <p class="small mb-2">
                        <strong id="tagDeleteName"></strong> is used on
                        <strong id="tagDeleteCount"></strong> pages.
                    </p>
                    <div class="d-flex flex-column gap-2">
                        <button type="button" id="tagDeleteStrip" class="btn btn-outline-secondary btn-sm">
                            Remove from all pages &amp; delete
                        </button>
                        <div class="d-flex align-items-center gap-2">
                            <span class="small text-muted">Replace with:</span>
                            <select id="tagReplaceSelect" class="form-select form-select-sm" style="max-width:180px"></select>
                            <button type="button" id="tagDeleteReplace" class="btn btn-primary btn-sm">Replace &amp; delete</button>
                        </div>
                        <button type="button" id="tagDeleteCancel" class="btn btn-link btn-sm text-muted p-0">Cancel</button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<%-- Upgrade modal --%>
<div class="modal fade" id="upgradeModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Jyrnyl Pro</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <p id="upgradeMsg">Upgrade to Jyrnyl Pro to unlock this feature.</p>
                <ul class="small text-muted mb-0">
                    <li>Unlimited pages</li>
                    <li>Unlimited custom templates</li>
                    <li>Unlimited AI voice processing</li>
                    <li>Page deletion</li>
                    <li>Export &amp; download</li>
                </ul>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Maybe later</button>
                <button type="button" class="btn btn-primary" disabled>Coming soon</button>
            </div>
        </div>
    </div>
</div>

<script>
    window.CONTEXT_PATH = '${pageContext.request.contextPath}';
    window.JOTPAGE_VIEW_MODE = '${viewMode}';
    window.BOOK_PAGES = ${pagesJson};
    window.BOOK_USER = {
        displayName: '<c:out value="${sessionScope.user.displayName}"/>',
        avatarUrl: '<c:out value="${sessionScope.user.avatarUrl}"/>',
        pageCount: ${empty pages ? 0 : pages.size()}
    };
    window.IS_PRO = ${isPro};
    window.IS_FIRST_MONTH = ${isFirstMonth};
    window.PAGES_THIS_MONTH = ${pagesThisMonth};
    window.MONTHLY_PAGE_LIMIT = ${monthlyPageLimit};
    window.CUSTOM_TEMPLATE_COUNT = ${customTemplateCount};
    window.CUSTOM_TEMPLATE_LIMIT = ${customTemplateLimit};
    window.LOGO_URL = '${pageContext.request.contextPath}/images/jyrnyl-logo-square.svg';
</script>
<c:if test="${viewMode == 'book'}">
    <script src="${pageContext.request.contextPath}/js/book-view.js?v=9"></script>
</c:if>
<script src="${pageContext.request.contextPath}/js/bubble-menu.js?v=9"></script>
<script>
    (function () {
        var ctx = '${pageContext.request.contextPath}';
        var isPro = window.IS_PRO;

        function showUpgrade(msg) {
            var el = document.getElementById('upgradeModal');
            if (!el) return;
            document.getElementById('upgradeMsg').textContent = msg || 'Upgrade to Jyrnyl Pro to unlock this feature.';
            new bootstrap.Modal(el).show();
        }

        var errorParam = '${errorParam}';
        if (errorParam === 'page_limit') {
            showUpgrade('You\u2019ve reached the ' + window.MONTHLY_PAGE_LIMIT + '-page monthly limit. Upgrade to Jyrnyl Pro for unlimited pages.');
            history.replaceState(null, '', location.pathname + location.search.replace(/[?&]error=page_limit/, ''));
        }

        // Auto-open the new-page modal / tag-filter popover when routed from
        // the editor bubble menu (?new=1 / ?filter=1). Strip the param from
        // the URL so refreshing doesn't re-trigger it.
        (function handleBubbleRoutingParams() {
            var params = new URLSearchParams(location.search);
            var autoNew = params.get('new') === '1';
            var autoFilter = params.get('filter') === '1';
            if (!autoNew && !autoFilter) return;
            params.delete('new');
            params.delete('filter');
            var qs = params.toString();
            history.replaceState(null, '',
                location.pathname + (qs ? '?' + qs : ''));
            // Defer to next tick so all the JS below has wired its listeners.
            setTimeout(function () {
                if (autoNew) {
                    document.dispatchEvent(new CustomEvent('jyrnyl:open-new-page-modal'));
                } else if (autoFilter) {
                    document.dispatchEvent(new CustomEvent('jyrnyl:open-tag-filter'));
                }
            }, 0);
        })();

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

        // ----- Template grid rendering -----
        var draggingCard = null;

        function renderTemplates(types) {
            listEl.innerHTML = '';
            if (!types || types.length === 0) {
                listEl.innerHTML = '<div class="text-muted small">No templates available.</div>';
                return;
            }
            types.forEach(function (t) {
                var card = document.createElement('a');
                card.className = 'template-card';
                card.href = ctx + '/app/page/new?typeId=' + t.id;
                card.setAttribute('data-type-id', t.id);
                card.draggable = true;

                var label = document.createElement('span');
                label.textContent = t.name;
                card.appendChild(label);

                if (t.immutableOnClose) {
                    var lock = document.createElement('i');
                    lock.className = 'bi bi-lock-fill lock-icon';
                    lock.title = 'Locks on close';
                    card.appendChild(lock);
                }

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
                    card.appendChild(del);
                }

                card.addEventListener('dragstart', function (e) {
                    draggingCard = card;
                    card.classList.add('dragging');
                    if (e.dataTransfer) {
                        e.dataTransfer.effectAllowed = 'move';
                        e.dataTransfer.setData('text/plain', t.id);
                    }
                });
                card.addEventListener('dragend', function () {
                    if (draggingCard) draggingCard.classList.remove('dragging');
                    draggingCard = null;
                    listEl.querySelectorAll('.template-card').forEach(function (c) {
                        c.classList.remove('drag-over');
                    });
                });
                card.addEventListener('dragover', function (e) {
                    if (!draggingCard || card === draggingCard) return;
                    e.preventDefault();
                    if (e.dataTransfer) e.dataTransfer.dropEffect = 'move';
                    card.classList.add('drag-over');
                });
                card.addEventListener('dragleave', function () {
                    card.classList.remove('drag-over');
                });
                card.addEventListener('drop', function (e) {
                    if (!draggingCard || card === draggingCard) return;
                    e.preventDefault();
                    card.classList.remove('drag-over');
                    var rect = card.getBoundingClientRect();
                    var midX = rect.left + rect.width / 2;
                    if (e.clientX > midX) {
                        listEl.insertBefore(draggingCard, card.nextSibling);
                    } else {
                        listEl.insertBefore(draggingCard, card);
                    }
                    persistTemplateOrder();
                });

                listEl.appendChild(card);
            });

            var voice = document.createElement('a');
            voice.className = 'template-card template-card-voice';
            voice.href = ctx + '/app/voice-record';
            voice.draggable = false;
            voice.innerHTML = '<i class="bi bi-mic-fill"></i> Voice';
            listEl.appendChild(voice);
        }

        function persistTemplateOrder() {
            var ids = Array.prototype.map.call(
                listEl.querySelectorAll('.template-card'),
                function (el) { return parseInt(el.getAttribute('data-type-id'), 10); }
            );
            fetch(ctx + '/app/api/pagetypes/reorder', {
                method: 'PUT',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ typeIds: ids })
            }).catch(function (err) {
                console.error('[dashboard] template reorder failed', err);
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

        // The bubble menu dispatches this when "New track" is chosen.
        document.addEventListener('jyrnyl:open-new-page-modal', function () {
            try {
                bootstrap.Modal.getOrCreateInstance(modal).show();
            } catch (err) {
                console.error('[dashboard] failed to open new page modal', err);
            }
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

        // ------------------------------------------------------------------
        // Tag filter (list view chips + bubble-menu tag popover)
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
            if (window.bookView && typeof window.bookView.setFilter === 'function') {
                var count = window.bookView.setFilter(activeTagIds.slice());
                updateBubbleTagStatus(count.shown, count.total);
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
                syncBubbleFilterChips();
                applyFilter();
            });
        });

        if (clearBtn) {
            clearBtn.addEventListener('click', function () {
                activeTagIds = [];
                filterChips.forEach(function (c) { c.classList.remove('active'); });
                syncBubbleFilterChips();
                applyFilter();
            });
        }

        // Restore filter state from ?tags=... in the URL
        (function initFilterFromUrl() {
            var params = new URLSearchParams(window.location.search);
            var raw = params.get('tags');
            // Phase 4: when entering list view via bubble menu (?sort=1),
            // force-clear the filter so sort order is predictable.
            var sortMode = params.get('sort') === '1';
            if (sortMode) {
                activeTagIds = [];
                filterChips.forEach(function (c) { c.classList.remove('active'); });
                updateEntryHrefs();
                history.replaceState(null, '',
                    location.pathname + '?view=list');
                return;
            }
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
        // Bubble-menu tag filter popover integration
        // ------------------------------------------------------------------
        var btf = document.getElementById('bubbleTagFilter');
        var btfList = document.getElementById('bubbleTagFilterList');
        var btfClose = btf ? btf.querySelector('.btf-close') : null;
        var btfClear = document.getElementById('bubbleTagFilterClear');
        var btfStatus = document.getElementById('bubbleTagFilterStatus');

        // All tags are already on the page as filter chips. Use those as the
        // source of truth for color + name so we don't need a separate fetch.
        var allTagsData = Array.prototype.map.call(
            document.querySelectorAll('.tag-filter-chip'),
            function (chip) {
                return {
                    id: chip.getAttribute('data-tag-id'),
                    name: chip.textContent.trim(),
                    color: chip.style.backgroundColor
                };
            }
        );
        // Fallback: if we're in book view (no chips rendered), fetch them.
        function ensureAllTagsData() {
            if (allTagsData.length > 0) return Promise.resolve(allTagsData);
            return fetch(ctx + '/app/api/tags', { credentials: 'same-origin' })
                .then(function (r) { return r.json(); })
                .then(function (tags) {
                    allTagsData = (tags || []).map(function (t) {
                        return { id: String(t.id), name: t.name, color: t.color };
                    });
                    return allTagsData;
                });
        }

        function renderBubbleTags() {
            if (!btfList) return;
            btfList.innerHTML = '';
            if (!allTagsData.length) {
                btfList.innerHTML = '<div class="text-muted small">No tags yet.</div>';
                return;
            }
            allTagsData.forEach(function (t) {
                var chip = document.createElement('span');
                chip.className = 'btf-chip';
                if (activeTagIds.indexOf(String(t.id)) !== -1) chip.classList.add('active');
                chip.style.background = t.color || '#8b6e4e';
                chip.textContent = t.name;
                chip.setAttribute('data-tag-id', t.id);
                chip.addEventListener('click', function () {
                    var tid = String(t.id);
                    var idx = activeTagIds.indexOf(tid);
                    if (idx >= 0) {
                        activeTagIds.splice(idx, 1);
                        chip.classList.remove('active');
                    } else {
                        activeTagIds.push(tid);
                        chip.classList.add('active');
                    }
                    syncListViewChips();
                    applyFilter();
                });
                btfList.appendChild(chip);
            });
        }

        function syncListViewChips() {
            filterChips.forEach(function (c) {
                var tid = c.getAttribute('data-tag-id');
                c.classList.toggle('active', activeTagIds.indexOf(tid) !== -1);
            });
        }

        function syncBubbleFilterChips() {
            if (!btfList) return;
            btfList.querySelectorAll('.btf-chip').forEach(function (c) {
                var tid = c.getAttribute('data-tag-id');
                c.classList.toggle('active', activeTagIds.indexOf(tid) !== -1);
            });
        }

        function updateBubbleTagStatus(shown, total) {
            if (!btfStatus) return;
            if (activeTagIds.length === 0) {
                btfStatus.textContent = '';
            } else {
                btfStatus.textContent = 'Showing ' + shown + ' of ' + total;
            }
        }

        function openBubbleTagFilter() {
            if (!btf) return;
            ensureAllTagsData().then(function () {
                renderBubbleTags();
                btf.setAttribute('aria-hidden', 'false');
            });
        }
        function closeBubbleTagFilter() {
            if (btf) btf.setAttribute('aria-hidden', 'true');
        }

        document.addEventListener('jyrnyl:open-tag-filter', openBubbleTagFilter);
        if (btfClose) btfClose.addEventListener('click', closeBubbleTagFilter);
        if (btf) {
            btf.addEventListener('click', function (e) {
                if (e.target === btf) closeBubbleTagFilter();
            });
        }
        if (btfClear) {
            btfClear.addEventListener('click', function () {
                activeTagIds = [];
                syncBubbleFilterChips();
                syncListViewChips();
                applyFilter();
            });
        }

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
                    ? '<i class="bi bi-check-lg"></i> Stop reordering'
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

        // ------------------------------------------------------------------
        // Tag management
        // ------------------------------------------------------------------
        var tagManageList = document.getElementById('tagManageList');
        var tagManageModal = document.getElementById('manageTagsModal');
        var tagDeleteInUse = document.getElementById('tagDeleteInUse');
        var tagDeleteName = document.getElementById('tagDeleteName');
        var tagDeleteCount = document.getElementById('tagDeleteCount');
        var tagReplaceSelect = document.getElementById('tagReplaceSelect');
        var tagDeleteStripBtn = document.getElementById('tagDeleteStrip');
        var tagDeleteReplaceBtn = document.getElementById('tagDeleteReplace');
        var tagDeleteCancelBtn = document.getElementById('tagDeleteCancel');
        var pendingDeleteTagId = null;
        var managedTags = [];

        function loadManagedTags() {
            if (!tagManageList) return;
            fetch(ctx + '/app/api/tags', { credentials: 'same-origin' })
                .then(function (r) { return r.json(); })
                .then(function (tags) {
                    managedTags = tags;
                    renderManagedTags(tags);
                })
                .catch(function () {
                    tagManageList.innerHTML = '<div class="text-danger small">Failed to load tags.</div>';
                });
        }

        function renderManagedTags(tags) {
            tagManageList.innerHTML = '';
            tagDeleteInUse.style.display = 'none';
            pendingDeleteTagId = null;
            if (!tags || tags.length === 0) {
                tagManageList.innerHTML = '<div class="text-muted small">No tags yet.</div>';
                return;
            }
            tags.forEach(function (t) {
                var row = document.createElement('div');
                row.className = 'tag-manage-row';
                row.setAttribute('data-tag-id', t.id);

                var colorInput = document.createElement('input');
                colorInput.type = 'color';
                colorInput.className = 'tag-color-input';
                colorInput.value = t.color || '#6c757d';
                row.appendChild(colorInput);

                var nameInput = document.createElement('input');
                nameInput.type = 'text';
                nameInput.className = 'tag-name-input';
                nameInput.value = t.name;
                nameInput.maxLength = 100;
                row.appendChild(nameInput);

                var countLabel = document.createElement('span');
                countLabel.className = 'tag-page-count';
                countLabel.textContent = t.pageCount === 0 ? 'unused' : t.pageCount + ' pg';
                row.appendChild(countLabel);

                var saveBtn = document.createElement('button');
                saveBtn.type = 'button';
                saveBtn.className = 'btn btn-primary btn-sm tag-save-btn';
                saveBtn.textContent = 'Save';
                saveBtn.addEventListener('click', function () {
                    fetch(ctx + '/app/api/tags/' + t.id, {
                        method: 'PUT',
                        credentials: 'same-origin',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ name: nameInput.value.trim(), color: colorInput.value })
                    }).then(function (r) {
                        if (r.ok) {
                            row.classList.remove('dirty');
                            loadManagedTags();
                        } else {
                            alert('Failed to update tag.');
                        }
                    });
                });
                row.appendChild(saveBtn);

                var delBtn = document.createElement('button');
                delBtn.type = 'button';
                delBtn.className = 'tag-delete-btn';
                delBtn.title = 'Delete tag';
                delBtn.innerHTML = '<i class="bi bi-trash3"></i>';
                delBtn.addEventListener('click', function () {
                    if (t.pageCount === 0) {
                        if (!confirm('Delete tag "' + t.name + '"?')) return;
                        fetch(ctx + '/app/api/tags/' + t.id, {
                            method: 'DELETE', credentials: 'same-origin'
                        }).then(function (r) {
                            if (r.ok || r.status === 204) loadManagedTags();
                            else alert('Failed to delete tag.');
                        });
                    } else {
                        showTagDeleteInUse(t);
                    }
                });
                row.appendChild(delBtn);

                function markDirty() { row.classList.add('dirty'); }
                colorInput.addEventListener('input', markDirty);
                nameInput.addEventListener('input', markDirty);

                tagManageList.appendChild(row);
            });
        }

        function showTagDeleteInUse(tag) {
            pendingDeleteTagId = tag.id;
            tagDeleteName.textContent = tag.name;
            tagDeleteCount.textContent = tag.pageCount;
            tagDeleteInUse.style.display = '';
            tagReplaceSelect.innerHTML = '';
            managedTags.forEach(function (t) {
                if (t.id === tag.id) return;
                var opt = document.createElement('option');
                opt.value = t.id;
                opt.textContent = t.name;
                tagReplaceSelect.appendChild(opt);
            });
        }

        if (tagDeleteCancelBtn) {
            tagDeleteCancelBtn.addEventListener('click', function () {
                tagDeleteInUse.style.display = 'none';
                pendingDeleteTagId = null;
            });
        }
        if (tagDeleteStripBtn) {
            tagDeleteStripBtn.addEventListener('click', function () {
                if (!pendingDeleteTagId) return;
                fetch(ctx + '/app/api/tags/' + pendingDeleteTagId, {
                    method: 'DELETE', credentials: 'same-origin'
                }).then(function (r) {
                    if (r.ok || r.status === 204) loadManagedTags();
                    else alert('Failed to delete tag.');
                });
            });
        }
        if (tagDeleteReplaceBtn) {
            tagDeleteReplaceBtn.addEventListener('click', function () {
                if (!pendingDeleteTagId) return;
                var replaceId = tagReplaceSelect.value;
                if (!replaceId) { alert('Select a tag to replace with.'); return; }
                fetch(ctx + '/app/api/tags/' + pendingDeleteTagId + '?replaceWith=' + replaceId, {
                    method: 'DELETE', credentials: 'same-origin'
                }).then(function (r) {
                    if (r.ok || r.status === 204) loadManagedTags();
                    else alert('Failed to replace and delete tag.');
                });
            });
        }
        if (tagManageModal) {
            tagManageModal.addEventListener('show.bs.modal', loadManagedTags);
        }

        // ------------------------------------------------------------------
        // Delete page (list view)
        // ------------------------------------------------------------------
        var deleteModal = document.getElementById('deletePageModal');
        var deleteMsg = document.getElementById('deletePageMsg');
        var deleteLockedWrap = document.getElementById('deleteLockedWrap');
        var deleteConfirmInput = document.getElementById('deleteConfirmInput');
        var deleteConfirmBtn = document.getElementById('deletePageConfirmBtn');
        var pendingDeleteId = null;
        var pendingDeleteLocked = false;

        if (deleteModal) {
            var bsDeleteModal = new bootstrap.Modal(deleteModal);

            document.addEventListener('click', function (e) {
                var btn = e.target.closest('.delete-page-btn');
                if (!btn) return;
                e.preventDefault();
                e.stopPropagation();

                pendingDeleteId = btn.getAttribute('data-page-id');
                pendingDeleteLocked = btn.getAttribute('data-locked') === 'true';

                if (pendingDeleteLocked) {
                    deleteMsg.textContent = 'This is a locked page. Deletion is permanent.';
                    deleteLockedWrap.style.display = '';
                    deleteConfirmInput.value = '';
                    deleteConfirmBtn.disabled = true;
                } else {
                    deleteMsg.textContent = 'This page will be permanently deleted.';
                    deleteLockedWrap.style.display = 'none';
                    deleteConfirmBtn.disabled = false;
                }

                bsDeleteModal.show();
            });

            if (deleteConfirmInput) {
                deleteConfirmInput.addEventListener('input', function () {
                    deleteConfirmBtn.disabled = (deleteConfirmInput.value !== 'DELETE');
                });
            }

            deleteModal.addEventListener('hidden.bs.modal', function () {
                pendingDeleteId = null;
                pendingDeleteLocked = false;
                deleteConfirmInput.value = '';
                deleteConfirmBtn.disabled = true;
            });

            deleteConfirmBtn.addEventListener('click', function () {
                if (!pendingDeleteId) return;
                if (pendingDeleteLocked && deleteConfirmInput.value !== 'DELETE') return;

                var id = pendingDeleteId;
                deleteConfirmBtn.disabled = true;
                deleteConfirmBtn.textContent = 'Deleting\u2026';

                fetch(ctx + '/app/page/' + id, {
                    method: 'DELETE',
                    credentials: 'same-origin'
                }).then(function (r) {
                    if (r.ok || r.status === 204) {
                        var entry = document.querySelector('.page-entry[data-page-id="' + id + '"]');
                        if (entry) entry.remove();
                        bsDeleteModal.hide();
                    } else {
                        alert('Failed to delete page (' + r.status + ').');
                    }
                }).catch(function (err) {
                    alert('Network error: ' + err.message);
                }).finally(function () {
                    deleteConfirmBtn.textContent = 'Yes, delete';
                    deleteConfirmBtn.disabled = false;
                });
            });
        }
    })();
</script>
<%@ include file="/WEB-INF/jspf/pwa-register.jspf" %>
</body>
</html>
