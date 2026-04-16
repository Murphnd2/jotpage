/*
 * Jyrnyl — tablet immersive mode (Phase 5 slim edition)
 *
 * The FAB + slide-out panel and the reparenting of navbar/tag-bar that this
 * file used to do are gone — the bubble menu replaces both. What remains
 * here is still valuable for tablet use:
 *
 *   - 30s auto-save while the page is dirty
 *   - "Saved" toast flash on successful save (piggybacks on the editor's
 *     in-page toast via the #save-status mutation observer already wired
 *     up in editor.jsp)
 *   - Browser gesture prevention (no pull-to-refresh, no pinch zoom, no
 *     long-press context menu) while touching the canvas area
 *   - Two-finger horizontal swipe on the canvas flips pages. Unlike the
 *     old implementation, the swipe now dispatches the same
 *     'jyrnyl:save-and-navigate' event the edge-nav chevrons use, so the
 *     current page is always saved before we leave it.
 *
 * Activation is still automatic for (pointer: coarse) AND (min-width: 768px)
 * so touch-first hardware gets the gesture prevention and the auto-save
 * interval without opting in.
 */
(function () {
    'use strict';

    var MQ = '(pointer: coarse) and (min-width: 768px)';
    var AUTO_SAVE_INTERVAL_MS = 30 * 1000;
    var SWIPE_THRESHOLD_PX = 50;

    var body = document.body;
    var canvasStage = document.getElementById('canvas-stage');
    var canvasEl = document.getElementById('ink-canvas');
    var textLayerEl = document.getElementById('text-layer');
    var saveBtn = document.getElementById('save-btn');
    var prevBtn = document.getElementById('prev-btn');
    var nextBtn = document.getElementById('next-btn');

    if (!canvasEl) return;

    var active = false;
    var dirty = false;
    var autoSaveTimer = null;
    var swipeStart = null;

    // ------------------------------------------------------------------
    // Enter / exit
    // ------------------------------------------------------------------
    function enterTablet() {
        if (active) return;
        active = true;
        body.classList.add('tablet-immersive');
        startDirtyTracking();
        startAutoSave();
        preventBrowserGestures(true);
        window.dispatchEvent(new Event('resize'));
    }
    function exitTablet() {
        if (!active) return;
        active = false;
        body.classList.remove('tablet-immersive');
        stopAutoSave();
        preventBrowserGestures(false);
        swipeStart = null;
        window.dispatchEvent(new Event('resize'));
    }

    // ------------------------------------------------------------------
    // Dirty flag tracking
    // ------------------------------------------------------------------
    function markDirty() { dirty = true; }

    function startDirtyTracking() {
        if (canvasEl) {
            canvasEl.addEventListener('pointerup', markDirty);
            canvasEl.addEventListener('pointercancel', markDirty);
        }
        if (textLayerEl) {
            textLayerEl.addEventListener('pointerup', markDirty);
            textLayerEl.addEventListener('input', markDirty, true);
            textLayerEl.addEventListener('keyup', markDirty, true);
        }
    }

    function triggerSaveIfDirty() {
        if (!dirty || !saveBtn) return;
        saveBtn.click();
        dirty = false;
    }

    function startAutoSave() {
        if (autoSaveTimer) clearInterval(autoSaveTimer);
        autoSaveTimer = setInterval(triggerSaveIfDirty, AUTO_SAVE_INTERVAL_MS);
    }
    function stopAutoSave() {
        if (autoSaveTimer) {
            clearInterval(autoSaveTimer);
            autoSaveTimer = null;
        }
    }

    // ------------------------------------------------------------------
    // Browser gesture prevention (only while tablet-immersive is active)
    // ------------------------------------------------------------------
    function isCanvasAreaTarget(el) {
        if (!el || !canvasStage) return false;
        var walk = el;
        while (walk && walk !== document.body) {
            if (walk === canvasStage) return true;
            walk = walk.parentNode;
        }
        return false;
    }

    function onDocTouchMove(e) {
        if (!active) return;
        // The ink engine handles its own gesture handling on the canvas
        // (preventDefault inside pointer listeners). Elsewhere, block so
        // the viewport doesn't bounce / pull-to-refresh.
        if (!isCanvasAreaTarget(e.target)) {
            if (e.cancelable) e.preventDefault();
        }
    }
    function onContextMenu(e) {
        if (!active) return;
        if (isCanvasAreaTarget(e.target)) e.preventDefault();
    }
    function onGestureStart(e) {
        if (active) e.preventDefault();
    }

    function preventBrowserGestures(on) {
        var method = on ? 'addEventListener' : 'removeEventListener';
        document[method]('touchmove', onDocTouchMove, { passive: false });
        document[method]('contextmenu', onContextMenu);
        document[method]('gesturestart', onGestureStart);
    }

    // ------------------------------------------------------------------
    // Two-finger swipe: save, then navigate via the shared bubble event
    // so the behaviour matches the edge-nav chevrons.
    // ------------------------------------------------------------------
    function hrefFor(btn) {
        var h = btn && btn.getAttribute('href');
        return (h && h !== '#') ? h : null;
    }

    function navigatePrev() {
        var href = hrefFor(prevBtn);
        if (!href) return;
        document.dispatchEvent(new CustomEvent('jyrnyl:save-and-navigate',
            { detail: { href: href } }));
    }
    function navigateNext() {
        var href = hrefFor(nextBtn);
        if (!href) return;
        document.dispatchEvent(new CustomEvent('jyrnyl:save-and-navigate',
            { detail: { href: href } }));
    }

    if (canvasStage) {
        canvasStage.addEventListener('touchstart', function (e) {
            if (!active) return;
            if (e.touches.length >= 2) {
                if (window.inkEngine && typeof window.inkEngine.cancelStroke === 'function') {
                    window.inkEngine.cancelStroke();
                }
                var t1 = e.touches[0];
                var t2 = e.touches[1];
                var midX = (t1.clientX + t2.clientX) / 2;
                var midY = (t1.clientY + t2.clientY) / 2;
                swipeStart = { x: midX, y: midY, lastX: midX, lastY: midY };
            }
        }, { passive: true });

        canvasStage.addEventListener('touchmove', function (e) {
            if (!active || !swipeStart) return;
            if (e.touches.length >= 2) {
                var t1 = e.touches[0];
                var t2 = e.touches[1];
                swipeStart.lastX = (t1.clientX + t2.clientX) / 2;
                swipeStart.lastY = (t1.clientY + t2.clientY) / 2;
            }
        }, { passive: true });

        var onSwipeEnd = function () {
            if (!active || !swipeStart) return;
            var dx = swipeStart.lastX - swipeStart.x;
            var dy = swipeStart.lastY - swipeStart.y;
            swipeStart = null;
            if (Math.abs(dx) >= SWIPE_THRESHOLD_PX && Math.abs(dx) > Math.abs(dy)) {
                if (dx < 0) navigateNext();
                else        navigatePrev();
            }
        };
        canvasStage.addEventListener('touchend', function (e) {
            if (!active || !swipeStart) return;
            if (e.touches.length < 2) onSwipeEnd();
        }, { passive: true });
        canvasStage.addEventListener('touchcancel', function () {
            swipeStart = null;
        }, { passive: true });
    }

    // ------------------------------------------------------------------
    // Activation
    // ------------------------------------------------------------------
    function urlHasImmersiveParam() {
        try {
            var params = new URLSearchParams(window.location.search);
            return params.get('immersive') === '1';
        } catch (e) {
            return false;
        }
    }

    try {
        if (urlHasImmersiveParam() || (window.matchMedia && window.matchMedia(MQ).matches)) {
            enterTablet();
        }
    } catch (err) { /* no matchMedia — skip */ }

    try {
        var mql = window.matchMedia(MQ);
        var listener = function (ev) {
            if (ev.matches && !active) enterTablet();
            else if (!ev.matches && active) exitTablet();
        };
        if (mql.addEventListener) mql.addEventListener('change', listener);
        else if (mql.addListener) mql.addListener(listener);
    } catch (err) { /* ignore */ }
})();
