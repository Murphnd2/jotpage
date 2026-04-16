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
    // Position state — free { x, y } (top-left of bubble in viewport coords)
    // rather than the previous edge+offset model. Users asked for the menu
    // to be drop-able anywhere on screen; the radial fan logic now adapts
    // to whatever position the bubble is in.
    // ------------------------------------------------------------------
    var state = loadPosition();
    applyPosition();

    function viewport() {
        return { w: window.innerWidth, h: window.innerHeight };
    }

    function clampToViewport(p) {
        var v = viewport();
        var margin = 8;
        var maxX = Math.max(margin, v.w - BUBBLE_SIZE - margin);
        var maxY = Math.max(margin, v.h - BUBBLE_SIZE - margin);
        return {
            x: Math.min(Math.max(margin, p.x), maxX),
            y: Math.min(Math.max(margin, p.y), maxY)
        };
    }

    function loadPosition() {
        try {
            var raw = window.localStorage.getItem(STORAGE_KEY);
            if (!raw) return defaultPosition();
            var p = JSON.parse(raw);
            if (!p || typeof p !== 'object') return defaultPosition();
            // Schema v2: { x, y } numeric in viewport coords. Anything else
            // (the old { edge, offset } schema, or missing keys) falls
            // through to the default.
            if (typeof p.x !== 'number' || typeof p.y !== 'number') {
                return defaultPosition();
            }
            return clampToViewport({ x: p.x, y: p.y });
        } catch (err) { return defaultPosition(); }
    }

    function savePosition() {
        try { window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); }
        catch (err) { /* ignore */ }
    }

    function defaultPosition() {
        var v = viewport();
        return clampToViewport({
            x: v.w - BUBBLE_SIZE - 14,
            y: Math.max(14, v.h * 0.35 - BUBBLE_SIZE / 2)
        });
    }

    function applyPosition() {
        bubble.style.transform = 'translate(' + state.x + 'px, ' + state.y + 'px)';
        layoutRadial();
    }

    // `cx, cy` is the finger position. Convert to bubble top-left and clamp.
    function setPositionFromXY(cx, cy) {
        var half = BUBBLE_SIZE / 2;
        state = clampToViewport({ x: cx - half, y: cy - half });
        savePosition();
        applyPosition();
    }

    // ------------------------------------------------------------------
    // Radial layout
    //
    // Preferred layout is a 180° FAN whose center angle points from the
    // button toward the viewport center. That gives a natural "bloom into
    // open space" behavior as the button moves:
    //   - middle-left-edge → fan aims right
    //   - middle-top-edge → fan aims down
    //   - middle of screen → any direction (degenerate but valid)
    //
    // When the bubble is close enough to a corner or an edge that the 180°
    // fan can't fit without its outer items getting clamped onto the
    // viewport border, we fall back to a straight COLUMN of items — down
    // from the button if there's more room below, up if more above. This
    // preserves the item spacing and eliminates the overlap that the old
    // "compress to fit" behavior produced.
    //
    // The decision is geometric, not zone-based: we lay out the fan, clamp
    // it to the viewport, and if any item's clamped position differs from
    // its intended position we switch to column layout.
    // ------------------------------------------------------------------
    var COLUMN_GAP = 10;

    function layoutRadial() {
        if (!itemEls.length) return;
        var v = viewport();
        var bcx = state.x + BUBBLE_SIZE / 2;
        var bcy = state.y + BUBBLE_SIZE / 2;
        var n = itemEls.length;
        var cx = (BUBBLE_SIZE - ITEM_SIZE) / 2;
        var cy = cx;

        var margin = 8;
        var minDX = margin - state.x - cx;
        var maxDX = v.w - ITEM_SIZE - margin - state.x - cx;
        var minDY = margin - state.y - cy;
        var maxDY = v.h - ITEM_SIZE - margin - state.y - cy;

        // --- Try fan-toward-center first ---
        var targetDx = v.w / 2 - bcx;
        var targetDy = v.h / 2 - bcy;
        // Math.atan2(0, 0) returns 0 (degenerate but harmless when button
        // sits at the exact viewport center — any direction is fine).
        var centerAngleDeg = Math.atan2(targetDy, targetDx) * 180 / Math.PI;
        var sweep = Math.min(180, n * 34);
        var start = centerAngleDeg - sweep / 2;
        var step = n > 1 ? sweep / (n - 1) : 0;
        var fanPositions = [];
        for (var i = 0; i < n; i++) {
            var angle = (start + step * i) * Math.PI / 180;
            fanPositions.push({
                dx: Math.cos(angle) * RADIAL_RADIUS,
                dy: Math.sin(angle) * RADIAL_RADIUS
            });
        }

        // Does the fan fit within the viewport clamp? If any item would be
        // clamped by more than ~2px (epsilon for floating-point noise), the
        // fan doesn't fit → fall back to column layout.
        var FIT_EPSILON = 2;
        var fanFits = true;
        for (var j = 0; j < n; j++) {
            var p = fanPositions[j];
            var clampedX = Math.min(Math.max(minDX, p.dx), maxDX);
            var clampedY = Math.min(Math.max(minDY, p.dy), maxDY);
            if (Math.abs(clampedX - p.dx) > FIT_EPSILON ||
                Math.abs(clampedY - p.dy) > FIT_EPSILON) {
                fanFits = false;
                break;
            }
        }

        var positions;
        if (fanFits) {
            positions = fanPositions;
        } else {
            // Column layout. Direction = whichever of up/down has more room
            // from the button's center. The column extends away from the
            // button (item 1 just past the button, item 2 past item 1, etc.)
            var roomDown = v.h - bcy;
            var roomUp = bcy;
            var dir = roomDown >= roomUp ? 1 : -1;
            var spacing = ITEM_SIZE + COLUMN_GAP;
            positions = [];
            for (var k = 0; k < n; k++) {
                positions.push({ dx: 0, dy: dir * spacing * (k + 1) });
            }
        }

        itemEls.forEach(function (el, idx) {
            var p = positions[idx];
            var dx = p.dx, dy = p.dy;
            // Final clamp — cheap insurance if the column itself runs past
            // the viewport edge (can happen if viewport is shorter than
            // n items × spacing).
            if (dx < minDX) dx = minDX;
            if (dx > maxDX) dx = maxDX;
            if (dy < minDY) dy = minDY;
            if (dy > maxDY) dy = maxDY;

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
    //
    // Radial items are gated by `awaitingFreshPointer` while the menu is
    // being opened. The finger that opened the menu must lift and a brand
    // new pointerdown must land before any radial item can fire. This is
    // what stops the "tap ☰ → radial item slides under the finger → errant
    // pointerup/click on Logout fires" class of bug.
    //
    // The flag flips on in expand() (which runs at the opening pointerup).
    // From that moment the opening gesture has already dispatched its
    // pointerdown, so every subsequent pointerdown is by definition a NEW
    // press from the user — we clear the flag on the next one.
    var awaitingFreshPointer = false;

    function expand() {
        if (bubble.classList.contains('expanded')) return;
        bubble.classList.add('expanded');
        trigger.setAttribute('aria-expanded', 'true');
        radial.setAttribute('aria-hidden', 'false');
        scrim.classList.add('visible');
        scrim.setAttribute('aria-hidden', 'false');
        awaitingFreshPointer = true;
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
        awaitingFreshPointer = false;
    }

    function toggle() {
        if (bubble.classList.contains('expanded')) collapse(); else expand();
    }

    // Any pointerdown that lands after expand() is by definition the user
    // consciously choosing an item — the opening gesture's pointerdown
    // already fired before the radial existed. Clear the gate on the first
    // one so that tap can proceed normally to the radial item handler.
    document.addEventListener('pointerdown', function () {
        if (awaitingFreshPointer) awaitingFreshPointer = false;
    }, true);

    function gateRadialEvent(e) {
        if (!awaitingFreshPointer) return;
        // Block residual pointerup/click from the opening gesture if they
        // happen to target a radial item (can happen if the finger drifted
        // onto one as it slid in under the fingertip).
        if (radial.contains(e.target)) {
            e.preventDefault();
            e.stopPropagation();
            if (e.stopImmediatePropagation) e.stopImmediatePropagation();
        }
    }
    // Capture-phase so we win before the item's own handler fires.
    document.addEventListener('click', gateRadialEvent, true);
    document.addEventListener('pointerup', gateRadialEvent, true);

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
