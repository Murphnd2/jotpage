/*
 * Jyrnyl — floating menu button (☰)
 *
 * A draggable, edge-snapping floating action button that expands into a
 * radial burst of 5 universal actions available on every page:
 *   1. New track   2. Sort pages   3. Filter by tag
 *   4. Voice booth  5. Logout
 *
 * Position is persisted to localStorage under 'jyrnyl.menu.pos'.
 *
 * Events dispatched:
 *   - 'jyrnyl:open-new-page-modal' — host page opens the template modal
 *   - 'jyrnyl:open-tag-filter'     — host page opens the tag filter popover
 */
(function () {
    'use strict';

    var STORAGE_KEY = 'jyrnyl.menu.pos';
    var DRAG_SLOP_PX = 6;
    var RADIAL_RADIUS = 84;
    var BUBBLE_SIZE = 56;
    var ITEM_SIZE = 44;

    var bubble = document.getElementById('bubbleMenu');
    var trigger = document.getElementById('bubbleMenuTrigger');
    var radial = document.getElementById('bubbleMenuRadial');
    var tooltip = document.getElementById('bubbleMenuTooltip');
    var scrim = document.getElementById('bubbleMenuScrim');
    if (!bubble || !trigger || !radial || !scrim) return;

    var body = document.body;
    var ctx = window.CONTEXT_PATH || '';
    var page = body.getAttribute('data-page') || 'dashboard';

    // ------------------------------------------------------------------
    // 5 universal actions
    // ------------------------------------------------------------------
    var actions = [
        { id: 'new-track', icon: 'bi-plus-lg',         label: 'New track',     run: openNewPageModal },
        { id: 'sort',      icon: 'bi-sort-down',       label: 'Sort pages',    run: goToSortPages },
        { id: 'filter',    icon: 'bi-funnel',          label: 'Filter by tag', run: openTagFilter },
        { id: 'voice',     icon: 'bi-mic',             label: 'Voice booth',   run: goToVoiceBooth },
        { id: 'logout',    icon: 'bi-box-arrow-right', label: 'Logout',        run: goToLogout }
    ];

    // ------------------------------------------------------------------
    // Build radial items
    // ------------------------------------------------------------------
    var itemEls = [];
    actions.forEach(function (a) {
        var btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'bubble-menu-item';
        btn.setAttribute('data-action-id', a.id);
        btn.setAttribute('aria-label', a.label);
        btn.innerHTML = '<i class="bi ' + a.icon + '" aria-hidden="true"></i>';
        btn.addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            collapse();
            try { a.run(); }
            catch (err) { console.error('[bubble-menu] action failed', a.id, err); }
        });
        btn.addEventListener('mouseenter', function () { showTooltip(btn, a.label); });
        btn.addEventListener('mouseleave', hideTooltip);
        btn.addEventListener('focus', function () { showTooltip(btn, a.label); });
        btn.addEventListener('blur', hideTooltip);
        radial.appendChild(btn);
        itemEls.push(btn);
    });

    // ------------------------------------------------------------------
    // Position state
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
        return { edge: 'right', offset: 0.35 };
    }

    function viewport() {
        return { w: window.innerWidth, h: window.innerHeight };
    }

    function clamp01(n) { return Math.max(0, Math.min(1, n)); }

    function applyPosition() {
        var v = viewport();
        var margin = 14;
        var x = 0, y = 0, available;
        switch (state.edge) {
            case 'left':
                x = margin;
                available = v.h - BUBBLE_SIZE - margin * 2;
                y = margin + clamp01(state.offset) * available;
                break;
            case 'right':
                x = v.w - BUBBLE_SIZE - margin;
                available = v.h - BUBBLE_SIZE - margin * 2;
                y = margin + clamp01(state.offset) * available;
                break;
            case 'top':
                y = margin;
                available = v.w - BUBBLE_SIZE - margin * 2;
                x = margin + clamp01(state.offset) * available;
                break;
            case 'bottom':
                y = v.h - BUBBLE_SIZE - margin;
                available = v.w - BUBBLE_SIZE - margin * 2;
                x = margin + clamp01(state.offset) * available;
                break;
        }
        bubble.style.transform = 'translate(' + x + 'px, ' + y + 'px)';
        bubble.setAttribute('data-edge', state.edge);
        layoutRadial();
    }

    function setPositionFromXY(cx, cy) {
        var v = viewport();
        var halfSize = BUBBLE_SIZE / 2;
        var distLeft = cx, distRight = v.w - cx;
        var distTop = cy, distBottom = v.h - cy;
        var min = Math.min(distLeft, distRight, distTop, distBottom);
        var edge = min === distLeft ? 'left'
                 : min === distRight ? 'right'
                 : min === distTop ? 'top' : 'bottom';
        var offset, margin = 14;
        if (edge === 'left' || edge === 'right') {
            var availY = v.h - BUBBLE_SIZE - margin * 2;
            offset = availY > 0 ? (cy - halfSize - margin) / availY : 0.5;
        } else {
            var availX = v.w - BUBBLE_SIZE - margin * 2;
            offset = availX > 0 ? (cx - halfSize - margin) / availX : 0.5;
        }
        state.edge = edge;
        state.offset = clamp01(offset);
        savePosition();
        applyPosition();
    }

    // ------------------------------------------------------------------
    // Radial layout
    // ------------------------------------------------------------------
    function layoutRadial() {
        if (!itemEls.length) return;
        var centerAngle = { left: 0, right: 180, top: 90, bottom: 270 }[state.edge] || 180;
        var n = itemEls.length;
        var sweep = Math.min(180, n * 34);
        var start = centerAngle - sweep / 2;
        var step = n > 1 ? sweep / (n - 1) : 0;
        var cx = (BUBBLE_SIZE - ITEM_SIZE) / 2;
        var cy = cx;

        itemEls.forEach(function (el, i) {
            var angle = (start + step * i) * Math.PI / 180;
            var dx = Math.cos(angle) * RADIAL_RADIUS;
            var dy = Math.sin(angle) * RADIAL_RADIUS;
            el.style.left = cx + 'px';
            el.style.top = cy + 'px';
            el.style.setProperty('--bm-dx', dx + 'px');
            el.style.setProperty('--bm-dy', dy + 'px');
            if (bubble.classList.contains('expanded')) {
                el.style.transform = 'translate(' + dx + 'px, ' + dy + 'px) scale(1)';
            } else {
                el.style.transform = 'translate(0, 0) scale(0.6)';
            }
        });
    }

    // ------------------------------------------------------------------
    // Expand / collapse
    // ------------------------------------------------------------------
    function expand() {
        if (bubble.classList.contains('expanded')) return;
        bubble.classList.add('expanded');
        trigger.setAttribute('aria-expanded', 'true');
        radial.setAttribute('aria-hidden', 'false');
        scrim.classList.add('visible');
        scrim.setAttribute('aria-hidden', 'false');
        layoutRadial();
        itemEls.forEach(function (el, i) {
            setTimeout(function () {
                el.style.transform = 'translate(var(--bm-dx), var(--bm-dy)) scale(1)';
            }, i * 22);
        });
    }

    function collapse() {
        if (!bubble.classList.contains('expanded')) return;
        bubble.classList.remove('expanded');
        trigger.setAttribute('aria-expanded', 'false');
        radial.setAttribute('aria-hidden', 'true');
        scrim.classList.remove('visible');
        scrim.setAttribute('aria-hidden', 'true');
        itemEls.forEach(function (el) {
            el.style.transform = 'translate(0, 0) scale(0.6)';
        });
        hideTooltip();
    }

    function toggle() {
        if (bubble.classList.contains('expanded')) collapse(); else expand();
    }

    scrim.addEventListener('click', collapse);
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && bubble.classList.contains('expanded')) collapse();
    });

    // ------------------------------------------------------------------
    // Tooltip
    // ------------------------------------------------------------------
    function showTooltip(anchor, text) {
        if (!tooltip) return;
        tooltip.textContent = text;
        tooltip.classList.add('visible');
        var rect = anchor.getBoundingClientRect();
        var bubbleRect = bubble.getBoundingClientRect();
        var left = rect.left - bubbleRect.left + rect.width / 2;
        var top = rect.top - bubbleRect.top - 28;
        tooltip.style.left = (left - tooltip.offsetWidth / 2) + 'px';
        tooltip.style.top = top + 'px';
    }
    function hideTooltip() {
        if (!tooltip) return;
        tooltip.classList.remove('visible');
    }

    // ------------------------------------------------------------------
    // Drag + tap
    // ------------------------------------------------------------------
    var pointerId = null, pointerStart = null, pointerLast = null;
    var dragOffset = null, dragged = false;

    trigger.addEventListener('pointerdown', function (e) {
        if (e.button !== undefined && e.button !== 0) return;
        pointerId = e.pointerId;
        pointerStart = { x: e.clientX, y: e.clientY };
        pointerLast = { x: e.clientX, y: e.clientY };
        dragged = false;
        try { trigger.setPointerCapture(pointerId); } catch (err) { /* */ }
        e.preventDefault();
    });

    trigger.addEventListener('pointermove', function (e) {
        if (pointerId !== e.pointerId || !pointerStart) return;
        var dx = e.clientX - pointerStart.x;
        var dy = e.clientY - pointerStart.y;
        if (!dragged && (Math.abs(dx) > DRAG_SLOP_PX || Math.abs(dy) > DRAG_SLOP_PX)) {
            dragged = true;
            bubble.classList.add('dragging');
            if (bubble.classList.contains('expanded')) collapse();
        }
        if (dragged) {
            pointerLast = { x: e.clientX, y: e.clientY };
            var v = viewport();
            var half = BUBBLE_SIZE / 2;
            var cx = Math.max(half, Math.min(v.w - half, e.clientX));
            var cy = Math.max(half, Math.min(v.h - half, e.clientY));
            bubble.style.transform = 'translate(' + (cx - half) + 'px, ' + (cy - half) + 'px)';
        }
    });

    function endDrag(e) {
        if (pointerId !== e.pointerId) return;
        try { trigger.releasePointerCapture(pointerId); } catch (err) { /* */ }
        pointerId = null;
        bubble.classList.remove('dragging');
        if (dragged && pointerLast) {
            setPositionFromXY(pointerLast.x, pointerLast.y);
            dragged = false;
            pointerStart = null;
            pointerLast = null;
            return;
        }
        pointerStart = null;
        pointerLast = null;
        toggle();
    }
    trigger.addEventListener('pointerup', endDrag);
    trigger.addEventListener('pointercancel', function (e) {
        if (pointerId !== e.pointerId) return;
        try { trigger.releasePointerCapture(pointerId); } catch (err) { /* */ }
        pointerId = null;
        pointerStart = null;
        pointerLast = null;
        bubble.classList.remove('dragging');
        dragged = false;
    });

    // Resize
    var resizeTimer = null;
    window.addEventListener('resize', function () {
        if (resizeTimer) clearTimeout(resizeTimer);
        resizeTimer = setTimeout(applyPosition, 100);
    });

    // ------------------------------------------------------------------
    // Action handlers
    // ------------------------------------------------------------------
    function openNewPageModal() {
        if (page === 'editor') {
            window.location.href = ctx + '/app/dashboard?new=1';
            return;
        }
        document.dispatchEvent(new CustomEvent('jyrnyl:open-new-page-modal'));
    }

    function goToSortPages() {
        window.location.href = ctx + '/app/dashboard?view=list&sort=1';
    }

    function openTagFilter() {
        if (page === 'editor') {
            window.location.href = ctx + '/app/dashboard?filter=1';
            return;
        }
        document.dispatchEvent(new CustomEvent('jyrnyl:open-tag-filter'));
    }

    function goToVoiceBooth() {
        window.location.href = ctx + '/app/voice-record';
    }

    function goToLogout() {
        window.location.href = ctx + '/logout';
    }

    // ------------------------------------------------------------------
    // Public API
    // ------------------------------------------------------------------
    window.bubbleMenu = {
        expand: expand,
        collapse: collapse,
        toggle: toggle
    };
})();
