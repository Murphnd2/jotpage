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

        /* Hidden save controls — still needed so ink-engine.js can bind Ctrl+S
           and the bubble menu can trigger saves programmatically. */
        .hidden-io {
            position: absolute !important;
            width: 1px;
            height: 1px;
            padding: 0;
            margin: -1px;
            overflow: hidden;
            clip: rect(0, 0, 0, 0);
            border: 0;
        }

        /* Page header label: shown as a subtle top banner only when the
           bubble menu is collapsed (so the user can still see which page
           they're on). */
        /* Saved/error toast */
        .save-toast {
            position: fixed;
            top: 16px;
            left: 50%;
            transform: translate(-50%, -6px);
            background: rgba(61, 42, 34, 0.92);
            color: rgba(255,253,247,0.95);
            padding: 8px 16px;
            border-radius: 999px;
            font-family: var(--font-serif);
            font-style: italic;
            font-size: 0.9rem;
            box-shadow: 0 4px 12px rgba(0,0,0,0.35);
            opacity: 0;
            transition: opacity 0.2s ease, transform 0.2s ease;
            pointer-events: none;
            z-index: 65;
        }
        .save-toast.visible {
            opacity: 1;
            transform: translate(-50%, 0);
        }
        .save-toast.error { background: rgba(122, 58, 26, 0.95); }

        /* Canvas stage */
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
        #image-layer {
            position: absolute;
            inset: 0;
            pointer-events: none;
            z-index: 1;
        }
        #image-layer.image-mode { pointer-events: auto; }
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
        .image-handle.selected { border-color: var(--accent-brown); }
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

        /* -------------------------------------------------------------- */
        /* Floating toolbar pill (always at bottom)                       */
        /* -------------------------------------------------------------- */
        .toolbar {
            position: fixed;
            left: 50%;
            bottom: 16px;
            transform: translateX(-50%);
            background: rgba(61, 42, 34, 0.88);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            padding: 6px 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            border-radius: 999px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.4);
            z-index: 30;
            max-width: calc(100vw - 80px);
            overflow-x: auto;
            transition: opacity 0.2s ease;
        }
        .toolbar.toolbar-hidden {
            opacity: 0;
            pointer-events: none;
        }
        .toolbar button,
        .toolbar label {
            min-height: 42px;
            min-width: 42px;
            border: 1px solid rgba(255,253,247,0.15);
            background: rgba(255,253,247,0.08);
            border-radius: 999px;
            font-size: 1.15rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 12px;
            cursor: pointer;
            color: rgba(255,253,247,0.9);
            transition: background 0.15s ease, color 0.15s ease, border-color 0.15s ease;
        }
        .toolbar button:hover {
            background: rgba(255,253,247,0.18);
            color: #fff;
        }
        .toolbar button:disabled { opacity: 0.35; cursor: not-allowed; }
        .toolbar button.active {
            background: var(--accent-gold);
            border-color: var(--accent-gold);
            color: var(--accent-brown-dark);
        }
        .toolbar input[type="color"] {
            width: 42px;
            height: 42px;
            border: 1px solid rgba(255,253,247,0.15);
            border-radius: 999px;
            padding: 3px;
            background: transparent;
            cursor: pointer;
        }
        .toolbar .thickness-wrap {
            display: flex;
            align-items: center;
            gap: 8px;
            min-height: 42px;
            padding: 0 12px;
            border: 1px solid rgba(255,253,247,0.15);
            border-radius: 999px;
            background: rgba(255,253,247,0.08);
            color: rgba(255,253,247,0.9);
        }
        .toolbar input[type="range"] {
            width: 110px;
            accent-color: var(--accent-gold);
        }
        .toolbar .thickness-value {
            font-variant-numeric: tabular-nums;
            min-width: 22px;
            text-align: right;
            font-size: 0.85rem;
            color: rgba(255,253,247,0.7);
        }
        .toolbar select.font-size-select {
            min-height: 42px;
            border: 1px solid rgba(255,253,247,0.15);
            border-radius: 999px;
            padding: 0 14px;
            background: rgba(255,253,247,0.08);
            font-size: 0.95rem;
            color: rgba(255,253,247,0.9);
        }
        .toolbar select.font-size-select option {
            background: #3d2a22;
            color: #faf6f0;
        }
        .toolbar .font-size-wrap {
            display: none;
            align-items: center;
            gap: 8px;
            color: rgba(255,253,247,0.75);
            font-size: 0.9rem;
            font-family: var(--font-serif);
            font-style: italic;
        }
        .toolbar .font-size-wrap.visible { display: inline-flex; }

        /* -------------------------------------------------------------- */
        /* Page tag editor (modal opened from bubble menu)                */
        /* -------------------------------------------------------------- */
        .page-tag-modal .tag-badges-row {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            min-height: 44px;
            padding: 8px 0 12px;
            border-bottom: 1px solid var(--border-warm);
            margin-bottom: 12px;
        }
        .page-tag-modal .tag-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 12px;
            border-radius: 999px;
            font-size: 0.85rem;
            color: #fff;
            box-shadow: inset 0 0 0 1px rgba(255,255,255,0.12);
        }
        .page-tag-modal .tag-badge .tag-remove {
            background: transparent;
            border: none;
            color: inherit;
            font-size: 1rem;
            line-height: 1;
            cursor: pointer;
            opacity: 0.8;
        }
        .page-tag-modal .tag-badge .tag-remove:hover { opacity: 1; }
        .page-tag-modal .existing-tags {
            display: flex;
            flex-direction: column;
            gap: 4px;
            max-height: 240px;
            overflow-y: auto;
            margin-bottom: 12px;
        }
        .page-tag-modal .tag-option {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 8px 10px;
            border-radius: var(--radius-sm);
            cursor: pointer;
            font-size: 0.95rem;
            color: var(--text-dark);
            border: 1px solid var(--border-warm);
        }
        .page-tag-modal .tag-option:hover {
            background: rgba(201, 168, 76, 0.10);
            border-color: var(--border-warm-strong);
        }
        .page-tag-modal .tag-option .swatch {
            width: 14px;
            height: 14px;
            border-radius: 50%;
            flex: 0 0 auto;
            box-shadow: inset 0 0 0 1px rgba(255,255,255,0.2);
        }
        .page-tag-modal .new-tag-form {
            border-top: 1px solid var(--border-warm);
            padding-top: 12px;
            display: flex;
            gap: 8px;
            align-items: center;
        }
        .page-tag-modal .new-tag-form input[type="text"] {
            flex: 1 1 auto;
            min-width: 0;
        }
        .page-tag-modal .new-tag-form input[type="color"] {
            width: 38px;
            height: 38px;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-sm);
            padding: 2px;
            background: var(--bg-card);
        }

        /* -------------------------------------------------------------- */
        /* Tablet immersive (the body class lingers only to drive         */
        /* browser-gesture prevention; visual chrome no longer depends    */
        /* on it since we've unified the floating-toolbar look).          */
        /* -------------------------------------------------------------- */
        body.tablet-immersive {
            background:
                radial-gradient(circle at 30% 20%, rgba(212,148,58,0.08), transparent 50%),
                radial-gradient(circle at 75% 85%, rgba(160,82,45,0.06), transparent 55%),
                #3e2716;
            touch-action: none;
            overscroll-behavior: none;
            -webkit-touch-callout: none;
            -webkit-tap-highlight-color: transparent;
        }
    </style>
</head>
<body data-page="editor"
      data-writable="true"
      data-is-pro="${isPro}"
      data-back-href="${backHref}"
      data-first-href="${empty firstHref ? '' : firstHref}"
      data-prev-href="${empty prevHref ? '' : prevHref}"
      data-next-href="${empty nextHref ? '' : nextHref}"
      data-last-href="${empty lastHref ? '' : lastHref}">

    <%-- Save/error toast --%>
    <div id="saveToast" class="save-toast" aria-live="polite"></div>

    <%-- Hidden save controls for ink-engine Ctrl+S + programmatic saves --%>
    <button id="save-btn" class="hidden-io" type="button">Save</button>
    <span id="save-status" class="hidden-io"></span>

    <%-- Hidden navigation anchors so ink-engine/tablet-mode can inspect them --%>
    <a id="first-btn" class="hidden-io" href="${empty firstHref ? '#' : firstHref}">First</a>
    <a id="prev-btn"  class="hidden-io" href="${empty prevHref  ? '#' : prevHref}">Prev</a>
    <a id="next-btn"  class="hidden-io" href="${empty nextHref  ? '#' : nextHref}">Next</a>
    <a id="last-btn"  class="hidden-io" href="${empty lastHref  ? '#' : lastHref}">Last</a>

    <div id="canvas-stage">
        <div id="canvas-wrap">
            <canvas id="ink-canvas" width="1480" height="2100"></canvas>
            <div id="image-layer"></div>
            <div id="text-layer"></div>
        </div>
    </div>

    <%-- Floating toolbar (Phase 5 keeps this; bubble menu toggles visibility) --%>
    <div class="toolbar toolbar-hidden" id="toolbar">
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
                <option value="4" selected>4</option>
                <option value="6">6</option>
                <option value="8">8</option>
                <option value="10">10</option>
                <option value="12">12</option>
                <option value="14">14</option>
                <option value="16">16</option>
                <option value="18">18</option>
                <option value="24">24</option>
                <option value="32">32</option>
                <option value="48">48</option>
                <option value="64">64</option>
            </select>
        </span>
        <input id="tool-color" type="color" value="#000000" title="Color">
        <div class="thickness-wrap">
            <i class="bi bi-circle-fill" style="font-size: 0.65rem;"></i>
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

    <%-- Bubble menu (5 universal actions) --%>
    <%@ include file="/WEB-INF/jspf/bubble-menu.jspf" %>

    <%-- Pen button (gold, toggles toolbar) --%>
    <%@ include file="/WEB-INF/jspf/pen-button.jspf" %>

    <%-- Edge tabs: left/right page nav + top center delete/tag --%>
    <%@ include file="/WEB-INF/jspf/edge-tabs.jspf" %>

    <%-- Page tag editor modal (opened via bubble menu) --%>
    <div class="modal fade page-tag-modal" id="pageTagsModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Tag this page</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <div id="tag-badges" class="tag-badges-row">
                        <span class="text-muted small">No tags</span>
                    </div>
                    <div class="existing-tags" id="existing-tags">
                        <div class="text-muted small">Loading...</div>
                    </div>
                    <form class="new-tag-form" id="new-tag-form">
                        <input type="text" id="new-tag-name" class="form-control form-control-sm"
                               placeholder="New tag name" maxlength="100">
                        <input type="color" id="new-tag-color" value="#6c757d">
                        <button type="submit" class="btn btn-primary btn-sm">Create</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <%-- Delete page confirmation modal --%>
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
        window.CONTEXT_PATH = CONTEXT_PATH;
        console.log('[editor.jsp] pageData set to', pageData);
    </script>
    <script src="${pageContext.request.contextPath}/js/ink-engine.js?v=5"></script>
    <script src="${pageContext.request.contextPath}/js/tablet-mode.js?v=5"></script>
    <script src="${pageContext.request.contextPath}/js/bubble-menu.js?v=5"></script>
    <script src="${pageContext.request.contextPath}/js/pen-button.js?v=5"></script>
    <script src="${pageContext.request.contextPath}/js/edge-tabs.js?v=5"></script>

    <script>
        (function () {
            'use strict';
            var ctx = CONTEXT_PATH;
            var pageId = pageData && pageData.id;
            if (!pageId) return;

            var saveBtn = document.getElementById('save-btn');
            var saveStatus = document.getElementById('save-status');
            var toastEl = document.getElementById('saveToast');
            var toolbar = document.getElementById('toolbar');
            var canvas = document.getElementById('ink-canvas');

            // ------------------------------------------------------------------
            // Auto-save: every 10s if dirty, plus on page hide / beforeunload
            // ------------------------------------------------------------------
            var dirty = false;
            var textLayer = document.getElementById('text-layer');
            function markDirty() { dirty = true; }
            if (canvas) {
                canvas.addEventListener('pointerup', markDirty);
                canvas.addEventListener('pointercancel', markDirty);
            }
            if (textLayer) {
                textLayer.addEventListener('pointerup', markDirty);
                textLayer.addEventListener('input', markDirty, true);
                textLayer.addEventListener('keyup', markDirty, true);
            }
            function autoSave() {
                if (!dirty || !saveBtn) return;
                saveBtn.click();
                dirty = false;
            }
            setInterval(autoSave, 10000);
            document.addEventListener('visibilitychange', function () {
                if (document.visibilityState === 'hidden') autoSave();
            });
            window.addEventListener('beforeunload', function () {
                autoSave();
            });

            // ------------------------------------------------------------------
            // Toast feedback — mirrors #save-status textContent mutations
            // ------------------------------------------------------------------
            var toastTimer = null;
            function showToast(text, isError) {
                if (!toastEl) return;
                toastEl.textContent = text;
                toastEl.classList.remove('error');
                if (isError) toastEl.classList.add('error');
                toastEl.classList.add('visible');
                if (toastTimer) clearTimeout(toastTimer);
                toastTimer = setTimeout(function () {
                    toastEl.classList.remove('visible');
                }, 1800);
            }
            if (saveStatus && window.MutationObserver) {
                new MutationObserver(function () {
                    var t = (saveStatus.textContent || '').trim();
                    if (!t) return;
                    if (/^saved$/i.test(t)) showToast('Saved', false);
                    else if (/^locked$/i.test(t)) showToast('Locked', true);
                    else if (/^error/i.test(t)) showToast(t, true);
                }).observe(saveStatus, { childList: true, characterData: true, subtree: true });
            }

            // ------------------------------------------------------------------
            // Toolbar show / hide (tapped open from bubble "Pen tools", auto-hides)
            // ------------------------------------------------------------------
            var toolbarHideTimer = null;
            var TOOLBAR_HIDE_MS = 5000;
            var drawingNow = false;

            function showToolbar() {
                if (!toolbar) return;
                toolbar.classList.remove('toolbar-hidden');
                scheduleToolbarHide();
            }
            function hideToolbar() {
                if (toolbar) toolbar.classList.add('toolbar-hidden');
            }
            function scheduleToolbarHide() {
                if (toolbarHideTimer) clearTimeout(toolbarHideTimer);
                toolbarHideTimer = setTimeout(function () {
                    if (!drawingNow) hideToolbar();
                }, TOOLBAR_HIDE_MS);
            }

            document.addEventListener('jyrnyl:toggle-toolbar', function () {
                if (toolbar.classList.contains('toolbar-hidden')) {
                    showToolbar();
                } else {
                    hideToolbar();
                }
            });

            if (canvas) {
                canvas.addEventListener('pointerdown', function () {
                    drawingNow = true;
                    hideToolbar();
                });
                canvas.addEventListener('pointerup', function () {
                    drawingNow = false;
                });
                canvas.addEventListener('pointercancel', function () {
                    drawingNow = false;
                });
            }

            // ------------------------------------------------------------------
            // Page tag editor — opened from edge-tab "Tag this page"
            // ------------------------------------------------------------------
            var badgesEl = document.getElementById('tag-badges');
            var existingEl = document.getElementById('existing-tags');
            var newForm = document.getElementById('new-tag-form');
            var newName = document.getElementById('new-tag-name');
            var newColor = document.getElementById('new-tag-color');
            var pageTagsModalEl = document.getElementById('pageTagsModal');

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
                    empty.textContent = 'No tags on this page yet.';
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
                }).then(renderExistingTags)
                  .catch(function (err) { console.error('[tags] add failed', err); });
            }

            function removeTagFromPage(tagId) {
                fetch(ctx + '/app/api/page-tags/' + pageId + '/' + tagId, {
                    method: 'DELETE',
                    credentials: 'same-origin'
                }).then(function (r) {
                    if (!r.ok && r.status !== 204) throw new Error('remove failed');
                    return loadPageTags();
                }).then(renderExistingTags)
                  .catch(function (err) { console.error('[tags] remove failed', err); });
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

            if (newForm) {
                newForm.addEventListener('submit', function (e) {
                    e.preventDefault();
                    var name = (newName.value || '').trim();
                    if (!name) return;
                    createAndAttachTag(name, newColor.value);
                    newName.value = '';
                });
            }

            var tagModalInstance = null;
            function openTagModal() {
                if (!pageTagsModalEl) return;
                if (!tagModalInstance) {
                    tagModalInstance = new bootstrap.Modal(pageTagsModalEl);
                }
                Promise.all([loadAllTags(), loadPageTags()])
                    .then(renderExistingTags)
                    .catch(function () { /* ignore */ });
                tagModalInstance.show();
            }
            document.addEventListener('jyrnyl:open-tag-editor', openTagModal);

            // Prime tag data so renderBadges has something to show if needed elsewhere.
            loadPageTags();

            // ------------------------------------------------------------------
            // Delete page (bubble menu → this flow)
            // ------------------------------------------------------------------
            var deleteModalEl = document.getElementById('deletePageModal');
            var deleteLockedWrap = document.getElementById('deleteLockedWrap');
            var deleteConfirmInput = document.getElementById('deleteConfirmInput');
            var deleteConfirmBtn = document.getElementById('deletePageConfirmBtn');
            var bsDeleteModal = deleteModalEl ? new bootstrap.Modal(deleteModalEl) : null;
            var isLocked = pageData && pageData.isClosed && pageData.immutableOnClose;

            function requestDelete() {
                if (!bsDeleteModal) return;
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
            }
            document.addEventListener('jyrnyl:delete-page', requestDelete);

            if (deleteConfirmInput) {
                deleteConfirmInput.addEventListener('input', function () {
                    deleteConfirmBtn.disabled = (deleteConfirmInput.value !== 'DELETE');
                });
            }
            if (deleteModalEl) {
                deleteModalEl.addEventListener('hidden.bs.modal', function () {
                    deleteConfirmInput.value = '';
                    deleteConfirmBtn.disabled = true;
                });
            }
            if (deleteConfirmBtn) {
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

            // Delete is a Pro-tier feature (matches original editor gating).
            // Hide the delete action on the bubble menu for free-tier users.
            var isPro = document.body.getAttribute('data-is-pro') === 'true';
            if (!isPro && window.bubbleMenu) {
                window.bubbleMenu.setActionVisible('delete', false);
            }
        })();
    </script>
    <%@ include file="/WEB-INF/jspf/pwa-register.jspf" %>
</body>
</html>
