<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <title>Jyrnyl &mdash; Studio</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/theme.css" rel="stylesheet">
    <%@ include file="/WEB-INF/jspf/pwa-head.jspf" %>
    <style>
        html, body {
            height: 100%;
            margin: 0;
            overflow: hidden;
            background:
                radial-gradient(circle at 30% 20%, rgba(212,148,58,0.05), transparent 45%),
                radial-gradient(circle at 80% 90%, rgba(160,82,45,0.04), transparent 50%),
                var(--bg-cream-dark);
            -webkit-user-select: none;
            user-select: none;
            font-family: var(--font-body);
            color: var(--text-dark);
        }
        body {
            display: flex;
            flex-direction: column;
        }
        .editor-navbar {
            flex: 0 0 auto;
            background: var(--bg-card);
            border-bottom: 1px solid var(--border-warm);
            padding: 10px 16px;
            display: flex;
            align-items: center;
            gap: 12px;
            box-shadow: 0 1px 0 rgba(74,55,40,0.04);
        }
        .editor-navbar .back-btn {
            font-size: 1.4rem;
            line-height: 1;
            color: var(--accent-brown);
            text-decoration: none;
            padding: 8px 12px;
            border-radius: var(--radius-md);
            transition: background 0.15s ease, color 0.15s ease;
        }
        .editor-navbar .back-btn:hover {
            background: var(--bg-cream-dark);
            color: var(--accent-brown-dark);
        }
        .page-header-label {
            flex: 1 1 auto;
            min-width: 0;
            font-family: var(--font-serif);
            font-size: 1.2rem;
            font-weight: 600;
            color: var(--accent-brown);
            padding: 6px 10px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            letter-spacing: 0.01em;
        }
        .nav-btn {
            min-height: 44px;
            min-width: 44px;
            border: 1px solid var(--border-warm-strong);
            background: var(--bg-card);
            border-radius: var(--radius-md);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: var(--accent-brown);
            text-decoration: none;
            font-size: 1.1rem;
            transition: background 0.15s ease, color 0.15s ease, border-color 0.15s ease;
        }
        .nav-btn:hover {
            background: var(--bg-cream-dark);
            color: var(--accent-brown-dark);
            border-color: var(--border-warm-strong);
        }
        .nav-btn.disabled {
            opacity: 0.35;
            pointer-events: none;
        }
        .delete-page-btn:hover {
            color: var(--accent-burgundy);
            border-color: var(--accent-burgundy);
        }
        .save-btn {
            min-height: 44px;
            min-width: 80px;
        }
        .save-status {
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.9rem;
            color: var(--text-muted);
            margin-left: 8px;
            min-width: 80px;
        }

        #canvas-stage {
            flex: 1 1 auto;
            position: relative;
            overflow: hidden;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        #canvas-wrap {
            background: #fffdf7;
            position: relative;
            touch-action: none;
            border-radius: 2px;
            box-shadow:
                0 1px 0 rgba(74,55,40,0.06),
                0 3px 8px rgba(74,55,40,0.12),
                0 12px 28px rgba(74,55,40,0.18),
                0 28px 60px rgba(74,55,40,0.14);
        }
        #canvas-wrap::before {
            /* Faint paper-edge line */
            content: "";
            position: absolute;
            inset: 0;
            pointer-events: none;
            border: 1px solid rgba(74,55,40,0.08);
            border-radius: 2px;
        }
        #ink-canvas {
            display: block;
            width: 100%;
            height: 100%;
            touch-action: none;
        }
        /* Image overlay layer */
        #image-layer {
            position: absolute;
            inset: 0;
            pointer-events: none;
            z-index: 1;
        }
        #image-layer.image-mode {
            pointer-events: auto;
        }
        .image-handle {
            position: absolute;
            border: 2px dashed transparent;
            cursor: move;
            pointer-events: none;
            box-sizing: border-box;
        }
        #image-layer.image-mode .image-handle {
            pointer-events: auto;
            border-color: var(--accent-gold);
        }
        .image-handle.selected {
            border-color: var(--accent-brown);
        }
        .image-handle .ih-delete {
            display: none;
            position: absolute;
            top: -12px;
            right: -12px;
            width: 24px;
            height: 24px;
            border-radius: 50%;
            background: var(--accent-burgundy);
            color: #fff;
            border: none;
            font-size: 0.9rem;
            cursor: pointer;
            align-items: center;
            justify-content: center;
        }
        .image-handle.selected .ih-delete { display: inline-flex; }
        .image-handle .ih-resize {
            display: none;
            position: absolute;
            bottom: -6px;
            right: -6px;
            width: 14px;
            height: 14px;
            background: var(--accent-brown);
            border-radius: 2px;
            cursor: nwse-resize;
        }
        .image-handle.selected .ih-resize { display: block; }

        #text-layer {
            position: absolute;
            inset: 0;
            pointer-events: none;
            z-index: 2;
        }
        #text-layer.text-mode {
            pointer-events: auto;
            cursor: text;
        }
        .text-block {
            position: absolute;
            pointer-events: none;
            box-sizing: border-box;
            padding: 6px 8px;
            border: 1px dashed transparent;
            border-radius: 4px;
            min-width: 40px;
            min-height: 24px;
            line-height: 1.2;
            word-wrap: break-word;
            overflow-wrap: break-word;
            white-space: pre-wrap;
        }
        #text-layer.text-mode .text-block {
            pointer-events: auto;
            cursor: move;
        }
        .text-block.selected {
            border-color: var(--accent-brown);
            background: rgba(74, 55, 40, 0.04);
        }
        .text-block .tb-content {
            outline: none;
            min-height: 1em;
            cursor: text;
        }
        .text-block .tb-handle {
            position: absolute;
            top: -12px;
            left: -12px;
            width: 24px;
            height: 24px;
            border-radius: 50%;
            background: var(--accent-brown);
            color: #fff;
            display: none;
            align-items: center;
            justify-content: center;
            font-size: 0.85rem;
            cursor: grab;
            user-select: none;
            box-shadow: 0 1px 2px rgba(74,55,40,0.2);
        }
        .text-block .tb-delete {
            position: absolute;
            top: -12px;
            right: -12px;
            width: 24px;
            height: 24px;
            border-radius: 50%;
            background: var(--accent-burgundy);
            color: #fff;
            border: none;
            display: none;
            align-items: center;
            justify-content: center;
            font-size: 0.9rem;
            cursor: pointer;
            user-select: none;
            padding: 0;
            box-shadow: 0 1px 2px rgba(74,55,40,0.2);
        }
        .text-block.selected .tb-handle,
        .text-block.selected .tb-delete,
        .text-block.selected .tb-resize {
            display: inline-flex;
        }
        .text-block .tb-resize {
            position: absolute;
            right: -10px;
            bottom: -10px;
            width: 22px;
            height: 22px;
            border-radius: 4px;
            background: var(--accent-gold);
            color: var(--text-dark);
            display: none;
            align-items: center;
            justify-content: center;
            cursor: nwse-resize;
            user-select: none;
            touch-action: none;
            font-size: 0.85rem;
            box-shadow: 0 1px 3px rgba(74,55,40,0.25);
        }

        .toolbar {
            flex: 0 0 auto;
            background: var(--bg-card);
            border-top: 1px solid var(--border-warm);
            padding: 10px 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            flex-wrap: wrap;
            box-shadow: 0 -1px 0 rgba(74,55,40,0.04);
        }
        .toolbar button,
        .toolbar label {
            min-height: 44px;
            min-width: 44px;
            border: 1px solid var(--border-warm-strong);
            background: var(--bg-card);
            border-radius: var(--radius-md);
            font-size: 1.2rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 12px;
            cursor: pointer;
            color: var(--accent-brown);
            transition: background 0.15s ease, color 0.15s ease, border-color 0.15s ease;
        }
        .toolbar button:hover {
            background: var(--bg-cream-dark);
            color: var(--accent-brown-dark);
        }
        .toolbar button:disabled { opacity: 0.35; cursor: not-allowed; }
        .toolbar button.active {
            background: var(--accent-brown);
            color: #fff;
            border-color: var(--accent-brown);
        }
        .toolbar button.active:hover {
            background: var(--accent-brown-dark);
            color: #fff;
        }
        .toolbar input[type="color"] {
            width: 44px;
            height: 44px;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-md);
            padding: 3px;
            background: var(--bg-card);
            cursor: pointer;
        }
        .toolbar .thickness-wrap {
            display: flex;
            align-items: center;
            gap: 8px;
            min-height: 44px;
            padding: 0 10px;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-md);
            background: var(--bg-card);
            color: var(--accent-brown);
        }
        .toolbar input[type="range"] {
            width: 120px;
            accent-color: var(--accent-brown);
        }
        .toolbar .thickness-value {
            font-variant-numeric: tabular-nums;
            min-width: 24px;
            text-align: right;
            font-size: 0.9rem;
            color: var(--text-muted);
        }
        .toolbar select.font-size-select {
            min-height: 44px;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-md);
            padding: 0 10px;
            background: var(--bg-card);
            font-size: 0.95rem;
            color: var(--text-dark);
        }
        .toolbar .font-size-wrap {
            display: none;
            align-items: center;
            gap: 8px;
            color: var(--text-muted);
            font-size: 0.9rem;
            font-family: var(--font-serif);
            font-style: italic;
        }
        .toolbar .font-size-wrap.visible {
            display: inline-flex;
        }

        #tag-bar {
            flex: 0 0 auto;
            background: var(--bg-card);
            border-bottom: 1px solid var(--border-warm);
            padding: 8px 16px;
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
            min-height: 46px;
        }
        #tag-bar .tag-label {
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.9rem;
            color: var(--text-muted);
            white-space: nowrap;
        }
        #tag-bar .tag-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 12px;
            border-radius: 999px;
            font-size: 0.8rem;
            color: #fff;
            user-select: none;
            box-shadow: inset 0 0 0 1px rgba(255,255,255,0.12);
        }
        #tag-bar .tag-badge .tag-remove {
            background: transparent;
            border: none;
            color: inherit;
            font-size: 1rem;
            line-height: 1;
            padding: 0 0 0 2px;
            cursor: pointer;
            opacity: 0.8;
        }
        #tag-bar .tag-badge .tag-remove:hover { opacity: 1; }
        #tag-bar .tag-add-btn {
            border: 1px dashed var(--border-warm-strong);
            background: transparent;
            color: var(--text-muted);
            border-radius: 999px;
            font-size: 0.85rem;
            padding: 5px 14px;
            cursor: pointer;
            font-family: var(--font-body);
            transition: background 0.15s ease, color 0.15s ease, border-color 0.15s ease;
        }
        #tag-bar .tag-add-btn:hover {
            background: var(--bg-cream-dark);
            color: var(--accent-brown);
            border-color: var(--accent-brown);
        }
        #tag-popover {
            position: relative;
        }
        #tag-popover .tag-popover-panel {
            position: absolute;
            top: calc(100% + 6px);
            left: 0;
            background: var(--bg-card);
            border: 1px solid var(--border-warm);
            border-radius: var(--radius-md);
            box-shadow: var(--shadow-paper);
            padding: 12px;
            min-width: 280px;
            z-index: 10;
            display: none;
        }
        #tag-popover.open .tag-popover-panel {
            display: block;
        }
        #tag-popover .tag-popover-panel .existing-tags {
            max-height: 180px;
            overflow-y: auto;
            margin-bottom: 10px;
        }
        #tag-popover .tag-option {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 6px 8px;
            border-radius: var(--radius-sm);
            cursor: pointer;
            font-size: 0.9rem;
            color: var(--text-dark);
        }
        #tag-popover .tag-option:hover {
            background: rgba(201, 168, 76, 0.10);
        }
        #tag-popover .tag-option .swatch {
            width: 14px;
            height: 14px;
            border-radius: 50%;
            flex: 0 0 auto;
            box-shadow: inset 0 0 0 1px rgba(255,255,255,0.2);
        }
        #tag-popover .new-tag-form {
            border-top: 1px solid var(--border-warm);
            padding-top: 10px;
            display: flex;
            gap: 6px;
            align-items: center;
        }
        #tag-popover .new-tag-form input[type="text"] {
            flex: 1 1 auto;
            min-width: 0;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-sm);
            padding: 5px 8px;
            font-size: 0.85rem;
            background: var(--bg-card);
            color: var(--text-dark);
        }
        #tag-popover .new-tag-form input[type="text"]:focus {
            outline: none;
            border-color: var(--accent-brown);
        }
        #tag-popover .new-tag-form input[type="color"] {
            width: 34px;
            height: 34px;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-sm);
            padding: 2px;
            background: var(--bg-card);
        }
        #tag-popover .new-tag-form button {
            font-size: 0.8rem;
            padding: 5px 12px;
        }

        /* ============================================================ */
        /* Tablet immersive mode — hidden on desktop                    */
        /* Toggled either by the fullscreen button or JS-applied class  */
        /* ============================================================ */

        /* These UI elements are hidden on desktop by default */
        .tablet-fab,
        .tablet-panel,
        .tablet-flash {
            display: none;
        }
        .immersive-toggle-btn {
            /* Still visible on desktop so the user can opt in */
        }

        body.tablet-immersive {
            /* Full-bleed canvas, warm desk background */
            background:
                radial-gradient(circle at 30% 20%, rgba(212,148,58,0.08), transparent 50%),
                radial-gradient(circle at 75% 85%, rgba(160,82,45,0.06), transparent 55%),
                #3e2716;
            touch-action: none;
            overscroll-behavior: none;
            -webkit-touch-callout: none;
            -webkit-tap-highlight-color: transparent;
        }

        /* Hide the desktop navbar/tagbar chrome — they get reparented into
           the tablet panel's body, where they're restyled. */
        body.tablet-immersive .editor-navbar,
        body.tablet-immersive #tag-bar {
            /* When inside the panel, they re-inherit these via .tp-drawer-body > * */
        }
        body.tablet-immersive .editor-navbar:not(.in-tablet-panel),
        body.tablet-immersive #tag-bar:not(.in-tablet-panel) {
            display: none !important;
        }

        /* Canvas stage fills the viewport */
        body.tablet-immersive #canvas-stage {
            position: fixed;
            inset: 0;
            padding: 16px;
            z-index: 1;
        }
        body.tablet-immersive #canvas-wrap {
            touch-action: none;
        }
        body.tablet-immersive #ink-canvas {
            touch-action: none;
        }

        /* Floating pill toolbar */
        body.tablet-immersive .toolbar {
            position: fixed;
            left: 50%;
            bottom: 16px;
            transform: translateX(-50%);
            flex-wrap: nowrap;
            border-top: none;
            border-radius: 999px;
            padding: 6px 10px;
            gap: 6px;
            background: rgba(61, 42, 34, 0.85);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            box-shadow: 0 8px 24px rgba(0,0,0,0.4);
            z-index: 30;
            max-width: calc(100vw - 32px);
            overflow-x: auto;
            transition: opacity 0.3s ease, transform 0.3s ease;
        }
        body.tablet-immersive .toolbar.toolbar-hidden {
            opacity: 0;
            transform: translate(-50%, 20px);
            pointer-events: none;
        }
        body.tablet-immersive .toolbar button,
        body.tablet-immersive .toolbar label {
            background: rgba(255,253,247,0.08);
            border: 1px solid rgba(255,253,247,0.15);
            color: rgba(255,253,247,0.9);
            min-height: 42px;
            min-width: 42px;
        }
        body.tablet-immersive .toolbar button:hover {
            background: rgba(255,253,247,0.15);
            color: #fff;
        }
        body.tablet-immersive .toolbar button.active {
            background: var(--accent-gold);
            border-color: var(--accent-gold);
            color: var(--accent-brown-dark);
        }
        body.tablet-immersive .toolbar .thickness-wrap,
        body.tablet-immersive .toolbar .font-size-wrap {
            background: rgba(255,253,247,0.08);
            border: 1px solid rgba(255,253,247,0.15);
            color: rgba(255,253,247,0.9);
        }
        body.tablet-immersive .toolbar select.font-size-select {
            background: transparent;
            color: rgba(255,253,247,0.9);
            border-color: rgba(255,253,247,0.15);
        }
        body.tablet-immersive .toolbar .thickness-value {
            color: rgba(255,253,247,0.7);
        }
        body.tablet-immersive .toolbar input[type="color"] {
            background: transparent;
            border-color: rgba(255,253,247,0.15);
        }

        /* Bottom edge "tap to show toolbar" strip (invisible hit area) */
        body.tablet-immersive .toolbar-hot-edge {
            position: fixed;
            left: 0;
            right: 0;
            bottom: 0;
            height: 32px;
            z-index: 29;
        }
        body:not(.tablet-immersive) .toolbar-hot-edge { display: none; }

        /* Floating action button */
        body.tablet-immersive .tablet-fab {
            display: inline-flex;
            position: fixed;
            top: 16px;
            right: 16px;
            width: 52px;
            height: 52px;
            border-radius: 50%;
            border: 1px solid rgba(255,253,247,0.2);
            background: rgba(74, 55, 40, 0.78);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            color: rgba(255,253,247,0.92);
            font-size: 1.3rem;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            z-index: 40;
            box-shadow: 0 4px 12px rgba(0,0,0,0.4);
            transition: transform 0.12s ease, background 0.15s ease;
        }
        body.tablet-immersive .tablet-fab:hover {
            background: rgba(74, 55, 40, 0.92);
            transform: scale(1.05);
        }

        /* Slide-out panel */
        body.tablet-immersive .tablet-panel {
            display: block;
            position: fixed;
            inset: 0;
            z-index: 50;
            pointer-events: none;
        }
        body.tablet-immersive .tablet-panel[aria-hidden="false"] {
            pointer-events: auto;
        }
        body.tablet-immersive .tablet-panel .tp-backdrop {
            position: absolute;
            inset: 0;
            background: rgba(61, 42, 34, 0.45);
            opacity: 0;
            transition: opacity 0.25s ease;
        }
        body.tablet-immersive .tablet-panel[aria-hidden="false"] .tp-backdrop {
            opacity: 1;
        }
        body.tablet-immersive .tablet-panel .tp-drawer {
            position: absolute;
            top: 0;
            right: 0;
            bottom: 0;
            width: min(380px, 88vw);
            background:
                linear-gradient(to bottom,
                    rgba(255, 253, 247, 0.97),
                    rgba(250, 246, 240, 0.97));
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border-left: 1px solid rgba(74,55,40,0.25);
            box-shadow: -12px 0 40px rgba(0,0,0,0.35);
            transform: translateX(100%);
            transition: transform 0.28s ease;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        body.tablet-immersive .tablet-panel[aria-hidden="false"] .tp-drawer {
            transform: translateX(0);
        }
        body.tablet-immersive .tp-drawer-head {
            flex: 0 0 auto;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 20px;
            border-bottom: 1px solid var(--border-warm);
        }
        body.tablet-immersive .tp-drawer-title {
            font-family: var(--font-serif);
            font-size: 1.25rem;
            font-weight: 600;
            color: var(--accent-brown);
            margin: 0;
        }
        body.tablet-immersive .tp-close {
            min-width: 44px;
            min-height: 44px;
            border-radius: var(--radius-md);
            background: transparent;
            border: 1px solid var(--border-warm-strong);
            color: var(--accent-brown);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 1rem;
            cursor: pointer;
        }
        body.tablet-immersive .tp-close:hover {
            background: var(--bg-cream-dark);
        }
        body.tablet-immersive .tp-drawer-body {
            flex: 1 1 auto;
            overflow-y: auto;
            padding: 16px 20px 24px;
            display: flex;
            flex-direction: column;
            gap: 14px;
        }

        /* Restyle the reparented navbar so it lays out vertically */
        body.tablet-immersive .editor-navbar.in-tablet-panel {
            display: flex;
            flex-direction: column;
            align-items: stretch;
            gap: 10px;
            background: transparent;
            border-bottom: 1px solid var(--border-warm);
            padding: 0 0 14px 0;
            box-shadow: none;
        }
        body.tablet-immersive .editor-navbar.in-tablet-panel .back-btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 14px;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-md);
            background: var(--bg-card);
            min-height: 44px;
            width: 100%;
            font-size: 0.95rem;
        }
        body.tablet-immersive .editor-navbar.in-tablet-panel .back-btn::after {
            content: "Back to your Jyrnyl";
            font-family: var(--font-body);
        }
        body.tablet-immersive .editor-navbar.in-tablet-panel .page-header-label {
            order: -1;
            font-size: 1.1rem;
            text-align: left;
            padding: 0;
            white-space: normal;
        }
        body.tablet-immersive .editor-navbar.in-tablet-panel .nav-btn {
            flex: 1 1 0;
        }
        body.tablet-immersive .editor-navbar.in-tablet-panel .nav-btn i::after {
            content: attr(data-label);
        }
        /* Group prev/next on one row */
        body.tablet-immersive .editor-navbar.in-tablet-panel #prev-btn,
        body.tablet-immersive .editor-navbar.in-tablet-panel #next-btn {
            display: inline-flex;
            gap: 6px;
            padding: 10px 14px;
            min-height: 44px;
        }
        body.tablet-immersive .editor-navbar.in-tablet-panel #prev-btn::after {
            content: "Previous";
            font-family: var(--font-body);
            font-size: 0.9rem;
        }
        body.tablet-immersive .editor-navbar.in-tablet-panel #next-btn::before {
            content: "Next";
            font-family: var(--font-body);
            font-size: 0.9rem;
        }
        body.tablet-immersive .editor-navbar.in-tablet-panel .save-btn {
            width: 100%;
            min-height: 48px;
            font-size: 1rem;
        }
        body.tablet-immersive .editor-navbar.in-tablet-panel .save-status {
            text-align: center;
            min-height: 20px;
        }
        body.tablet-immersive .editor-navbar.in-tablet-panel .immersive-toggle-btn {
            width: 100%;
            min-height: 44px;
        }
        body.tablet-immersive .editor-navbar.in-tablet-panel .immersive-toggle-btn::after {
            content: " Exit immersive";
        }

        /* Restyle the reparented tag bar */
        body.tablet-immersive #tag-bar.in-tablet-panel {
            display: flex;
            flex-direction: column;
            align-items: stretch;
            background: transparent;
            border: none;
            padding: 0;
            min-height: 0;
            gap: 8px;
        }
        body.tablet-immersive #tag-bar.in-tablet-panel .tag-label {
            font-family: var(--font-serif);
            font-size: 0.95rem;
            color: var(--accent-brown);
            font-style: normal;
            font-weight: 600;
        }
        body.tablet-immersive #tag-bar.in-tablet-panel #tag-popover .tag-popover-panel {
            position: static;
            box-shadow: none;
            background: rgba(201, 168, 76, 0.06);
            margin-top: 6px;
        }

        /* "Saved" toast flash near the FAB */
        body.tablet-immersive .tablet-flash {
            display: block;
            position: fixed;
            top: 24px;
            right: 80px;
            background: rgba(61, 42, 34, 0.92);
            color: rgba(255,253,247,0.95);
            padding: 8px 14px;
            border-radius: 999px;
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.9rem;
            box-shadow: 0 4px 12px rgba(0,0,0,0.35);
            opacity: 0;
            transform: translateY(-6px);
            transition: opacity 0.2s ease, transform 0.2s ease;
            pointer-events: none;
            z-index: 45;
        }
        body.tablet-immersive .tablet-flash.visible {
            opacity: 1;
            transform: translateY(0);
        }
    </style>
</head>
<body>
    <div class="editor-navbar">
        <a class="back-btn" href="${backHref}" title="Back to your Jyrnyl">
            <i class="bi bi-arrow-left"></i>
        </a>
        <a id="first-btn"
           class="nav-btn ${empty firstHref ? 'disabled' : ''}"
           title="First page"
           href="${empty firstHref ? '#' : firstHref}">
            <i class="bi bi-chevron-double-left"></i>
        </a>
        <a id="prev-btn"
           class="nav-btn ${empty prevHref ? 'disabled' : ''}"
           title="Previous page"
           href="${empty prevHref ? '#' : prevHref}">
            <i class="bi bi-chevron-left"></i>
        </a>
        <a id="next-btn"
           class="nav-btn ${empty nextHref ? 'disabled' : ''}"
           title="Next page"
           href="${empty nextHref ? '#' : nextHref}">
            <i class="bi bi-chevron-right"></i>
        </a>
        <a id="last-btn"
           class="nav-btn ${empty lastHref ? 'disabled' : ''}"
           title="Last page"
           href="${empty lastHref ? '#' : lastHref}">
            <i class="bi bi-chevron-double-right"></i>
        </a>
        <div class="page-header-label"><c:out value="${pageHeader}" /></div>
        <button id="save-btn" class="btn btn-primary save-btn" type="button">Save</button>
        <span id="save-status" class="save-status"></span>
        <c:if test="${isPro}">
        <button id="delete-page-btn" class="nav-btn delete-page-btn"
                type="button" title="Delete page">
            <i class="bi bi-trash3"></i>
        </button>
        </c:if>
        <button id="immersive-toggle" class="nav-btn immersive-toggle-btn"
                type="button" title="Toggle immersive">
            <i class="bi bi-fullscreen"></i>
        </button>
    </div>

    <!-- ========== Tablet immersive UI ========== -->
    <button id="tabletFab" class="tablet-fab" type="button" aria-label="Menu">
        <i class="bi bi-three-dots"></i>
    </button>
    <div id="tabletPanel" class="tablet-panel" aria-hidden="true">
        <div class="tp-backdrop" id="tpBackdrop"></div>
        <aside class="tp-drawer" aria-label="Editor menu">
            <div class="tp-drawer-head">
                <h3 class="tp-drawer-title">Menu</h3>
                <button id="tpCloseBtn" class="tp-close" type="button" aria-label="Close">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>
            <div class="tp-drawer-body" id="tpBody">
                <!-- Desktop navbar + tag bar get reparented here in tablet mode -->
            </div>
        </aside>
    </div>
    <div id="tabletFlash" class="tablet-flash">Saved</div>
    <div class="toolbar-hot-edge" id="toolbarHotEdge"></div>

    <div id="tag-bar">
        <span class="tag-label">Tags:</span>
        <div id="tag-badges" class="d-flex align-items-center gap-2 flex-wrap"></div>
        <div id="tag-popover">
            <button type="button" id="tag-add-btn" class="tag-add-btn">+ Add tag</button>
            <div class="tag-popover-panel" id="tag-popover-panel">
                <div class="existing-tags" id="existing-tags">
                    <div class="text-muted small">Loading...</div>
                </div>
                <form class="new-tag-form" id="new-tag-form">
                    <input type="text" id="new-tag-name" placeholder="New tag name" maxlength="100">
                    <input type="color" id="new-tag-color" value="#6c757d">
                    <button type="submit" class="btn btn-primary btn-sm">Create</button>
                </form>
            </div>
        </div>
    </div>

    <div id="canvas-stage">
        <div id="canvas-wrap">
            <canvas id="ink-canvas" width="1480" height="2100"></canvas>
            <div id="image-layer"></div>
            <div id="text-layer"></div>
        </div>
    </div>

    <div class="toolbar" id="toolbar">
        <button id="tool-pen" class="active" type="button" title="Pen">
            <i class="bi bi-pen-fill"></i>
        </button>
        <button id="tool-eraser" type="button" title="Eraser">
            <i class="bi bi-eraser-fill"></i>
        </button>
        <button id="tool-text" type="button" title="Text">
            <i class="bi bi-type"></i>
        </button>
        <c:if test="${isPro}">
        <button id="tool-image" type="button" title="Add image overlay">
            <i class="bi bi-image"></i>
        </button>
        </c:if>
        <span id="font-size-wrap" class="font-size-wrap">
            <label for="tool-fontsize">Size</label>
            <select id="tool-fontsize" class="font-size-select">
                <option value="2">2</option>
                <option value="4">4</option>
                <option value="6">6</option>
                <option value="8">8</option>
                <option value="10">10</option>
                <option value="12">12</option>
                <option value="14">14</option>
                <option value="16" selected>16</option>
                <option value="18">18</option>
                <option value="24">24</option>
                <option value="32">32</option>
                <option value="48">48</option>
                <option value="64">64</option>
            </select>
        </span>
        <input id="tool-color" type="color" value="#000000" title="Color">
        <div class="thickness-wrap">
            <i class="bi bi-circle-fill" style="font-size: 0.7rem;"></i>
            <input id="tool-thickness" type="range" min="1" max="20" value="3">
            <span id="tool-thickness-value" class="thickness-value">3</span>
        </div>
        <button id="tool-undo" type="button" title="Undo (Ctrl+Z)">
            <i class="bi bi-arrow-counterclockwise"></i>
        </button>
        <button id="tool-redo" type="button" title="Redo (Ctrl+Y)">
            <i class="bi bi-arrow-clockwise"></i>
        </button>
    </div>

    <!-- Delete page confirmation modal -->
    <div class="modal fade" id="deletePageModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-sm">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Delete this page?</h5>
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
    <script>
        var pageData = ${empty pageDataJson ? 'null' : pageDataJson};
        var CONTEXT_PATH = '${pageContext.request.contextPath}';
        console.log('[editor.jsp] pageData set to', pageData);
    </script>
    <script src="${pageContext.request.contextPath}/js/ink-engine.js"></script>
    <script src="${pageContext.request.contextPath}/js/tablet-mode.js"></script>
    <script>
        (function () {
            var ctx = CONTEXT_PATH;
            var pageId = pageData && pageData.id;
            if (!pageId) return;

            var badgesEl = document.getElementById('tag-badges');
            var popover = document.getElementById('tag-popover');
            var panel = document.getElementById('tag-popover-panel');
            var addBtn = document.getElementById('tag-add-btn');
            var existingEl = document.getElementById('existing-tags');
            var newForm = document.getElementById('new-tag-form');
            var newName = document.getElementById('new-tag-name');
            var newColor = document.getElementById('new-tag-color');

            var pageTags = [];
            var allTags = [];

            function escapeHtml(s) {
                return (s == null ? '' : String(s))
                    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
            }

            function renderBadges() {
                badgesEl.innerHTML = '';
                if (pageTags.length === 0) {
                    var empty = document.createElement('span');
                    empty.className = 'text-muted small';
                    empty.textContent = 'No tags';
                    badgesEl.appendChild(empty);
                    return;
                }
                pageTags.forEach(function (t) {
                    var badge = document.createElement('span');
                    badge.className = 'tag-badge';
                    badge.style.background = t.color || '#6c757d';
                    badge.innerHTML = escapeHtml(t.name)
                        + '<button type="button" class="tag-remove" aria-label="Remove">&times;</button>';
                    badge.querySelector('.tag-remove').addEventListener('click', function () {
                        removeTagFromPage(t.id);
                    });
                    badgesEl.appendChild(badge);
                });
            }

            function renderExistingTags() {
                existingEl.innerHTML = '';
                var currentIds = {};
                pageTags.forEach(function (t) { currentIds[t.id] = true; });
                var available = allTags.filter(function (t) { return !currentIds[t.id]; });
                if (available.length === 0) {
                    existingEl.innerHTML = '<div class="text-muted small">No more tags to add.</div>';
                    return;
                }
                available.forEach(function (t) {
                    var row = document.createElement('div');
                    row.className = 'tag-option';
                    row.innerHTML = '<span class="swatch" style="background:' + escapeHtml(t.color || '#6c757d') + '"></span>'
                        + '<span>' + escapeHtml(t.name) + '</span>';
                    row.addEventListener('click', function () {
                        addTagToPage(t.id);
                    });
                    existingEl.appendChild(row);
                });
            }

            function loadAllTags() {
                return fetch(ctx + '/app/api/tags', { credentials: 'same-origin' })
                    .then(function (r) { return r.json(); })
                    .then(function (data) { allTags = Array.isArray(data) ? data : []; });
            }

            function loadPageTags() {
                return fetch(ctx + '/app/api/page-tags/' + pageId, { credentials: 'same-origin' })
                    .then(function (r) { return r.json(); })
                    .then(function (data) {
                        pageTags = Array.isArray(data) ? data : [];
                        renderBadges();
                    });
            }

            function addTagToPage(tagId) {
                fetch(ctx + '/app/api/page-tags/' + pageId, {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ tagId: tagId })
                }).then(function (r) {
                    if (!r.ok) throw new Error('add failed');
                    return loadPageTags();
                }).then(function () {
                    renderExistingTags();
                }).catch(function (err) {
                    console.error('[tags] add failed', err);
                });
            }

            function removeTagFromPage(tagId) {
                fetch(ctx + '/app/api/page-tags/' + pageId + '/' + tagId, {
                    method: 'DELETE',
                    credentials: 'same-origin'
                }).then(function (r) {
                    if (!r.ok && r.status !== 204) throw new Error('remove failed');
                    return loadPageTags();
                }).then(function () {
                    if (popover.classList.contains('open')) renderExistingTags();
                }).catch(function (err) {
                    console.error('[tags] remove failed', err);
                });
            }

            function createAndAttachTag(name, color) {
                return fetch(ctx + '/app/api/tags', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ name: name, color: color })
                }).then(function (r) {
                    if (!r.ok) throw new Error('create failed');
                    return r.json();
                }).then(function (tag) {
                    allTags.push(tag);
                    addTagToPage(tag.id);
                });
            }

            addBtn.addEventListener('click', function (e) {
                e.stopPropagation();
                var isOpen = popover.classList.toggle('open');
                if (isOpen) {
                    loadAllTags().then(renderExistingTags);
                }
            });

            document.addEventListener('click', function (e) {
                if (!popover.contains(e.target)) {
                    popover.classList.remove('open');
                }
            });
            panel.addEventListener('click', function (e) { e.stopPropagation(); });

            newForm.addEventListener('submit', function (e) {
                e.preventDefault();
                var name = (newName.value || '').trim();
                if (!name) return;
                createAndAttachTag(name, newColor.value);
                newName.value = '';
            });

            loadPageTags();

            // ----------------------------------------------------------
            // Delete page
            // ----------------------------------------------------------
            var deleteBtn = document.getElementById('delete-page-btn');
            var deleteModalEl = document.getElementById('deletePageModal');
            var deleteLockedWrap = document.getElementById('deleteLockedWrap');
            var deleteConfirmInput = document.getElementById('deleteConfirmInput');
            var deleteConfirmBtn = document.getElementById('deletePageConfirmBtn');

            if (deleteBtn && deleteModalEl) {
                var bsDeleteModal = new bootstrap.Modal(deleteModalEl);
                var isLocked = pageData && pageData.isClosed && pageData.immutableOnClose;

                deleteBtn.addEventListener('click', function () {
                    if (isLocked) {
                        document.getElementById('deletePageMsg').textContent =
                            'This is a locked page. Deletion is permanent.';
                        deleteLockedWrap.style.display = '';
                        deleteConfirmInput.value = '';
                        deleteConfirmBtn.disabled = true;
                    } else {
                        document.getElementById('deletePageMsg').textContent =
                            'This page will be permanently deleted.';
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

                deleteModalEl.addEventListener('hidden.bs.modal', function () {
                    deleteConfirmInput.value = '';
                    deleteConfirmBtn.disabled = true;
                });

                deleteConfirmBtn.addEventListener('click', function () {
                    if (isLocked && deleteConfirmInput.value !== 'DELETE') return;

                    deleteConfirmBtn.disabled = true;
                    deleteConfirmBtn.textContent = 'Deleting\u2026';

                    fetch(ctx + '/app/page/' + pageId, {
                        method: 'DELETE',
                        credentials: 'same-origin'
                    }).then(function (r) {
                        if (r.ok || r.status === 204) {
                            window.location.href = '${backHref}';
                        } else {
                            alert('Failed to delete page (' + r.status + ').');
                            deleteConfirmBtn.textContent = 'Yes, delete';
                            deleteConfirmBtn.disabled = false;
                        }
                    }).catch(function (err) {
                        alert('Network error: ' + err.message);
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
