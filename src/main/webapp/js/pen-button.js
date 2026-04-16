/*
 * Jyrnyl — floating pen button (✏️)
 *
 * Editor-only. A draggable, edge-snapping gold button that toggles the
 * drawing toolbar visible/hidden. Dispatches 'jyrnyl:toggle-toolbar' on
 * each tap.
 *
 * Position persisted to localStorage under 'jyrnyl.pen.pos'.
 * Fades out while the user is actively drawing; reappears on pen lift.
 */
(function () {
    'use strict';

    var STORAGE_KEY = 'jyrnyl.pen.pos';
    var DRAG_SLOP_PX = 6;
    var BTN_SIZE = 52;

    var el = document.getElementById('penButton');
    if (!el) return;

    var canvas = document.getElementById('ink-canvas');

    // ------------------------------------------------------------------
    // Position state (same logic as bubble-menu.js, independent key)
    // ------------------------------------------------------------------
    var state = loadPosition();
    applyPosition();

    function loadPosition() {
        try {
            var raw = window.localStorage.getItem(STORAGE_KEY);
            if (!raw) return defaultPosition();
            var parsed = JSON.parse(raw);
            if (!parsed || typeof parsed !== 'object') return defaultPosition();
            if (['left','right','top','bottom'].indexOf(parsed.edge) === -1) return defaultPosition();
            return { edge: parsed.edge, offset: typeof parsed.offset === 'number' ? parsed.offset : 0.5 };
        } catch (err) { return defaultPosition(); }
    }
    function savePosition() {
        try { window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); }
        catch (err) { /* ignore */ }
    }
    function defaultPosition() {
        // Right edge, lower than the menu button so they don't overlap
        return { edge: 'right', offset: 0.78 };
    }

    function viewport() { return { w: window.innerWidth, h: window.innerHeight }; }
    function clamp01(n) { return Math.max(0, Math.min(1, n)); }

    function applyPosition() {
        var v = viewport();
        var margin = 14;
        var x = 0, y = 0, available;
        switch (state.edge) {
            case 'left':
                x = margin;
                available = v.h - BTN_SIZE - margin * 2;
                y = margin + clamp01(state.offset) * available;
                break;
            case 'right':
                x = v.w - BTN_SIZE - margin;
                available = v.h - BTN_SIZE - margin * 2;
                y = margin + clamp01(state.offset) * available;
                break;
            case 'top':
                y = margin;
                available = v.w - BTN_SIZE - margin * 2;
                x = margin + clamp01(state.offset) * available;
                break;
            case 'bottom':
                y = v.h - BTN_SIZE - margin;
                available = v.w - BTN_SIZE - margin * 2;
                x = margin + clamp01(state.offset) * available;
                break;
        }
        el.style.transform = 'translate(' + x + 'px, ' + y + 'px)';
    }

    function setPositionFromXY(cx, cy) {
        var v = viewport();
        var halfSize = BTN_SIZE / 2;
        var distLeft = cx, distRight = v.w - cx;
        var distTop = cy, distBottom = v.h - cy;
        var min = Math.min(distLeft, distRight, distTop, distBottom);
        var edge = min === distLeft ? 'left'
                 : min === distRight ? 'right'
                 : min === distTop ? 'top' : 'bottom';
        var offset, margin = 14;
        if (edge === 'left' || edge === 'right') {
            var availY = v.h - BTN_SIZE - margin * 2;
            offset = availY > 0 ? (cy - halfSize - margin) / availY : 0.5;
        } else {
            var availX = v.w - BTN_SIZE - margin * 2;
            offset = availX > 0 ? (cx - halfSize - margin) / availX : 0.5;
        }
        state.edge = edge;
        state.offset = clamp01(offset);
        savePosition();
        applyPosition();
    }

    // ------------------------------------------------------------------
    // Drag + tap
    // ------------------------------------------------------------------
    var pointerId = null, pointerStart = null, pointerLast = null;
    var dragged = false;

    el.addEventListener('pointerdown', function (e) {
        if (e.button !== undefined && e.button !== 0) return;
        pointerId = e.pointerId;
        pointerStart = { x: e.clientX, y: e.clientY };
        pointerLast  = { x: e.clientX, y: e.clientY };
        dragged = false;
        try { el.setPointerCapture(pointerId); } catch (err) { /* */ }
        e.preventDefault();
    });

    el.addEventListener('pointermove', function (e) {
        if (pointerId !== e.pointerId || !pointerStart) return;
        var dx = e.clientX - pointerStart.x;
        var dy = e.clientY - pointerStart.y;
        if (!dragged && (Math.abs(dx) > DRAG_SLOP_PX || Math.abs(dy) > DRAG_SLOP_PX)) {
            dragged = true;
            el.classList.add('dragging');
        }
        if (dragged) {
            pointerLast = { x: e.clientX, y: e.clientY };
            var v = viewport();
            var half = BTN_SIZE / 2;
            var cx = Math.max(half, Math.min(v.w - half, e.clientX));
            var cy = Math.max(half, Math.min(v.h - half, e.clientY));
            el.style.transform = 'translate(' + (cx - half) + 'px, ' + (cy - half) + 'px)';
        }
    });

    function endDrag(e) {
        if (pointerId !== e.pointerId) return;
        try { el.releasePointerCapture(pointerId); } catch (err) { /* */ }
        pointerId = null;
        el.classList.remove('dragging');
        if (dragged && pointerLast) {
            setPositionFromXY(pointerLast.x, pointerLast.y);
            dragged = false;
            pointerStart = null;
            pointerLast = null;
            return;
        }
        pointerStart = null;
        pointerLast = null;
        // Tap — toggle toolbar
        toggleToolbar();
    }
    el.addEventListener('pointerup', endDrag);
    el.addEventListener('pointercancel', function (e) {
        if (pointerId !== e.pointerId) return;
        try { el.releasePointerCapture(pointerId); } catch (err) { /* */ }
        pointerId = null;
        pointerStart = null;
        pointerLast = null;
        el.classList.remove('dragging');
        dragged = false;
    });

    // Keyboard
    el.addEventListener('keydown', function (e) {
        if (e.key === ' ' || e.key === 'Enter') {
            e.preventDefault();
            toggleToolbar();
        }
    });

    // ------------------------------------------------------------------
    // Toggle toolbar + position it near the pen button
    // ------------------------------------------------------------------
    var toolbar = document.getElementById('toolbar');
    var toolbarVisible = false;

    function positionToolbar() {
        if (!toolbar) return;
        var rect = el.getBoundingClientRect();
        var v = viewport();
        var cx = rect.left + BTN_SIZE / 2;
        var cy = rect.top + BTN_SIZE / 2;
        var gap = 10;

        // Determine which edge the pen button is on and position accordingly
        var tbWidth = toolbar.scrollWidth || 500;
        var tbHeight = toolbar.scrollHeight || 52;
        var x, y;

        if (state.edge === 'right') {
            // Extend leftward from button
            x = rect.left - tbWidth - gap;
            y = cy - tbHeight / 2;
        } else if (state.edge === 'left') {
            // Extend rightward from button
            x = rect.right + gap;
            y = cy - tbHeight / 2;
        } else if (state.edge === 'top') {
            // Extend downward, centered on button X
            x = cx - tbWidth / 2;
            y = rect.bottom + gap;
        } else {
            // Bottom: extend upward, centered on button X
            x = cx - tbWidth / 2;
            y = rect.top - tbHeight - gap;
        }

        // Clamp to viewport
        x = Math.max(8, Math.min(v.w - tbWidth - 8, x));
        y = Math.max(8, Math.min(v.h - tbHeight - 8, y));

        toolbar.style.left = x + 'px';
        toolbar.style.top = y + 'px';
        toolbar.style.bottom = 'auto';
        toolbar.style.transform = 'none';
    }

    function toggleToolbar() {
        toolbarVisible = !toolbarVisible;
        el.classList.toggle('active', toolbarVisible);
        // Dispatch first so the toolbar-hidden class is removed and the
        // toolbar has layout, then position it on the next frame.
        document.dispatchEvent(new CustomEvent('jyrnyl:toggle-toolbar'));
        if (toolbarVisible) {
            requestAnimationFrame(function () { positionToolbar(); });
        }
    }

    // Sync active state when toolbar hides on its own (auto-hide after draw)
    if (toolbar && window.MutationObserver) {
        new MutationObserver(function () {
            var hidden = toolbar.classList.contains('toolbar-hidden');
            if (hidden && toolbarVisible) {
                toolbarVisible = false;
                el.classList.remove('active');
            } else if (!hidden && !toolbarVisible) {
                toolbarVisible = true;
                el.classList.add('active');
            }
        }).observe(toolbar, { attributes: true, attributeFilter: ['class'] });
    }

    // ------------------------------------------------------------------
    // Fade during active drawing
    // ------------------------------------------------------------------
    if (canvas) {
        canvas.addEventListener('pointerdown', function () { el.classList.add('faded'); });
        canvas.addEventListener('pointerup', function () { el.classList.remove('faded'); });
        canvas.addEventListener('pointercancel', function () { el.classList.remove('faded'); });
    }

    // Resize
    var resizeTimer = null;
    window.addEventListener('resize', function () {
        if (resizeTimer) clearTimeout(resizeTimer);
        resizeTimer = setTimeout(applyPosition, 100);
    });
})();
