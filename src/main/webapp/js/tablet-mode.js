/*
 * Jyrnyl — tablet immersive mode
 *
 * Purely presentational layer on top of ink-engine.js. Does not modify any
 * drawing logic; only reparents existing DOM nodes between their desktop
 * positions and a slide-out panel, drives a floating toolbar, provides a
 * FAB + auto-save, and suppresses browser gestures.
 *
 * Activation:
 *   - Automatically on devices matching
 *     (pointer: coarse) and (min-width: 768px)
 *   - Via the #immersive-toggle button on any device
 *   - Via a ?immersive=1 query param on the URL — used by prev/next
 *     navigation so flipping to a new page preserves immersive state.
 */
(function () {
    'use strict';

    var MQ = '(pointer: coarse) and (min-width: 768px)';
    var AUTO_SAVE_INTERVAL_MS = 30 * 1000;
    var TOOLBAR_HIDE_DELAY_MS = 5 * 1000;
    var SWIPE_THRESHOLD_PX = 50;

    // ------------------------------------------------------------------
    // Element references
    // ------------------------------------------------------------------
    var body = document.body;
    var navbarEl = document.querySelector('.editor-navbar');
    var tagBarEl = document.getElementById('tag-bar');
    var canvasStage = document.getElementById('canvas-stage');
    var toolbarEl = document.getElementById('toolbar');
    var canvasEl = document.getElementById('ink-canvas');
    var textLayerEl = document.getElementById('text-layer');

    var fab = document.getElementById('tabletFab');
    var panel = document.getElementById('tabletPanel');
    var panelBody = document.getElementById('tpBody');
    var panelBackdrop = document.getElementById('tpBackdrop');
    var panelClose = document.getElementById('tpCloseBtn');
    var flashEl = document.getElementById('tabletFlash');
    var hotEdgeEl = document.getElementById('toolbarHotEdge');
    var toggleBtn = document.getElementById('immersive-toggle');

    var firstBtnEl = document.getElementById('first-btn');
    var prevBtnEl = document.getElementById('prev-btn');
    var nextBtnEl = document.getElementById('next-btn');
    var lastBtnEl = document.getElementById('last-btn');

    var saveBtn = document.getElementById('save-btn');
    var saveStatus = document.getElementById('save-status');

    if (!navbarEl || !tagBarEl || !panel || !panelBody || !fab) {
        // Editor page shape changed? Bail out rather than crashing.
        return;
    }

    // Remember where the navbar / tag-bar live in the desktop DOM so we can
    // restore them on exit.
    var navbarHome = { parent: navbarEl.parentNode, next: navbarEl.nextSibling };
    var tagBarHome = { parent: tagBarEl.parentNode, next: tagBarEl.nextSibling };

    var active = false;
    var dirty = false;
    var autoSaveTimer = null;
    var toolbarHideTimer = null;
    var drawingNow = false;
    var savedFlashTimer = null;
    var savedStatusObserver = null;

    // Original nav hrefs captured before we append ?immersive=1.
    // Restored on exit so navigating away from immersive mode doesn't carry
    // the param back into the normal editor.
    var originalFirstHref = null;
    var originalPrevHref = null;
    var originalNextHref = null;
    var originalLastHref = null;

    // Two-finger swipe state
    var swipeStart = null;

    // ------------------------------------------------------------------
    // Enter / exit immersive
    // ------------------------------------------------------------------
    function enterTablet() {
        if (active) return;
        active = true;
        body.classList.add('tablet-immersive');

        // Move navbar + tag bar into the panel
        navbarEl.classList.add('in-tablet-panel');
        tagBarEl.classList.add('in-tablet-panel');
        panelBody.appendChild(navbarEl);
        panelBody.appendChild(tagBarEl);

        // Rewrite prev/next hrefs so navigating to an adjacent page
        // preserves immersive state via a URL param.
        rewriteNavHrefs(true);

        // Start background state tracking
        startDirtyTracking();
        startAutoSave();
        startToolbarAutoHide();
        observeSaveStatus();
        preventBrowserGestures(true);

        // Toggle button icon on desktop navbar (if present in new position)
        if (toggleBtn) {
            var icon = toggleBtn.querySelector('i');
            if (icon) icon.className = 'bi bi-fullscreen-exit';
        }

        // Nudge the canvas size so ink-engine's fitCanvas reflows
        window.dispatchEvent(new Event('resize'));
    }

    function exitTablet() {
        if (!active) return;
        active = false;
        closePanel();

        // Restore prev/next hrefs to their server-rendered originals
        rewriteNavHrefs(false);

        // Move navbar + tag bar back to their original slots
        navbarEl.classList.remove('in-tablet-panel');
        tagBarEl.classList.remove('in-tablet-panel');
        if (navbarHome.parent) {
            if (navbarHome.next && navbarHome.next.parentNode === navbarHome.parent) {
                navbarHome.parent.insertBefore(navbarEl, navbarHome.next);
            } else {
                navbarHome.parent.insertBefore(navbarEl, navbarHome.parent.firstChild);
            }
        }
        if (tagBarHome.parent) {
            if (tagBarHome.next && tagBarHome.next.parentNode === tagBarHome.parent) {
                tagBarHome.parent.insertBefore(tagBarEl, tagBarHome.next);
            } else {
                tagBarHome.parent.appendChild(tagBarEl);
            }
        }

        body.classList.remove('tablet-immersive');

        stopAutoSave();
        stopToolbarAutoHide();
        preventBrowserGestures(false);
        if (savedStatusObserver) {
            savedStatusObserver.disconnect();
            savedStatusObserver = null;
        }
        if (toolbarEl) toolbarEl.classList.remove('toolbar-hidden');

        if (toggleBtn) {
            var icon = toggleBtn.querySelector('i');
            if (icon) icon.className = 'bi bi-fullscreen';
        }

        swipeStart = null;
        window.dispatchEvent(new Event('resize'));
    }

    // ------------------------------------------------------------------
    // Nav href rewriting — preserve immersive mode across prev/next
    // ------------------------------------------------------------------
    function appendImmersiveParam(href) {
        if (!href) return href;
        // '#' is the disabled placeholder; leave it alone
        if (href === '#' || href.charAt(href.length - 1) === '#') return href;
        // Don't double-add
        if (/[?&]immersive=1(?:&|$)/.test(href)) return href;
        var sep = href.indexOf('?') >= 0 ? '&' : '?';
        return href + sep + 'immersive=1';
    }

    function rewriteNavHrefs(enabling) {
        if (enabling) {
            if (firstBtnEl) {
                originalFirstHref = firstBtnEl.getAttribute('href');
                firstBtnEl.setAttribute('href', appendImmersiveParam(originalFirstHref));
            }
            if (prevBtnEl) {
                originalPrevHref = prevBtnEl.getAttribute('href');
                prevBtnEl.setAttribute('href', appendImmersiveParam(originalPrevHref));
            }
            if (nextBtnEl) {
                originalNextHref = nextBtnEl.getAttribute('href');
                nextBtnEl.setAttribute('href', appendImmersiveParam(originalNextHref));
            }
            if (lastBtnEl) {
                originalLastHref = lastBtnEl.getAttribute('href');
                lastBtnEl.setAttribute('href', appendImmersiveParam(originalLastHref));
            }
        } else {
            if (firstBtnEl && originalFirstHref !== null) {
                firstBtnEl.setAttribute('href', originalFirstHref);
                originalFirstHref = null;
            }
            if (prevBtnEl && originalPrevHref !== null) {
                prevBtnEl.setAttribute('href', originalPrevHref);
                originalPrevHref = null;
            }
            if (nextBtnEl && originalNextHref !== null) {
                nextBtnEl.setAttribute('href', originalNextHref);
                originalNextHref = null;
            }
            if (lastBtnEl && originalLastHref !== null) {
                lastBtnEl.setAttribute('href', originalLastHref);
                originalLastHref = null;
            }
        }
    }

    function navigateAnchor(btn) {
        if (!btn) return;
        if (btn.classList && btn.classList.contains('disabled')) return;
        var href = btn.getAttribute('href');
        if (!href || href === '#') return;
        window.location.href = href;
    }
    function navigatePrev() { navigateAnchor(prevBtnEl); }
    function navigateNext() { navigateAnchor(nextBtnEl); }

    // ------------------------------------------------------------------
    // Panel open/close
    // ------------------------------------------------------------------
    function openPanel() {
        panel.setAttribute('aria-hidden', 'false');
        // Opening the panel is a natural save point
        triggerSaveIfDirty();
    }
    function closePanel() {
        panel.setAttribute('aria-hidden', 'true');
    }
    function isPanelOpen() {
        return panel.getAttribute('aria-hidden') === 'false';
    }

    fab.addEventListener('click', function (e) {
        e.preventDefault();
        if (isPanelOpen()) closePanel(); else openPanel();
    });
    if (panelBackdrop) {
        panelBackdrop.addEventListener('click', closePanel);
    }
    if (panelClose) {
        panelClose.addEventListener('click', closePanel);
    }
    // Escape closes panel
    document.addEventListener('keydown', function (e) {
        if (active && e.key === 'Escape' && isPanelOpen()) {
            closePanel();
        }
    });

    // ------------------------------------------------------------------
    // Dirty flag — track when the user has drawn/edited something
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
    // "Saved" flash — observe the existing #save-status span that
    // ink-engine.js already writes into, and surface it near the FAB
    // ------------------------------------------------------------------
    function showFlash(text) {
        if (!flashEl) return;
        flashEl.textContent = text;
        flashEl.classList.add('visible');
        if (savedFlashTimer) clearTimeout(savedFlashTimer);
        savedFlashTimer = setTimeout(function () {
            flashEl.classList.remove('visible');
        }, 1800);
    }

    function observeSaveStatus() {
        if (!saveStatus || !window.MutationObserver) return;
        savedStatusObserver = new MutationObserver(function () {
            var t = (saveStatus.textContent || '').trim();
            if (!t) return;
            if (/^saved$/i.test(t)) {
                showFlash('Saved');
            } else if (/^locked$/i.test(t)) {
                showFlash('Locked');
            } else if (/^error/i.test(t)) {
                showFlash(t);
            }
        });
        savedStatusObserver.observe(saveStatus, {
            childList: true,
            characterData: true,
            subtree: true
        });
    }

    // ------------------------------------------------------------------
    // Floating toolbar auto-hide
    // Hide while actively drawing; reappear on pen lift or tap on the
    // hot edge at the bottom of the screen.
    // ------------------------------------------------------------------
    function showToolbar() {
        if (!toolbarEl) return;
        toolbarEl.classList.remove('toolbar-hidden');
    }
    function hideToolbar() {
        if (!toolbarEl) return;
        toolbarEl.classList.add('toolbar-hidden');
    }

    function onCanvasDown() {
        drawingNow = true;
        showToolbar();
        if (toolbarHideTimer) clearTimeout(toolbarHideTimer);
    }
    function onCanvasUp() {
        drawingNow = false;
        showToolbar();
        scheduleToolbarHide();
    }
    function scheduleToolbarHide() {
        if (!active) return;
        if (toolbarHideTimer) clearTimeout(toolbarHideTimer);
        toolbarHideTimer = setTimeout(function () {
            if (!drawingNow && active && !isPanelOpen()) hideToolbar();
        }, TOOLBAR_HIDE_DELAY_MS);
    }

    function startToolbarAutoHide() {
        if (canvasEl) {
            canvasEl.addEventListener('pointerdown', onCanvasDown);
            canvasEl.addEventListener('pointerup', onCanvasUp);
            canvasEl.addEventListener('pointercancel', onCanvasUp);
        }
        if (hotEdgeEl) {
            hotEdgeEl.addEventListener('pointerdown', function () {
                showToolbar();
                scheduleToolbarHide();
            });
        }
        scheduleToolbarHide();
    }
    function stopToolbarAutoHide() {
        if (canvasEl) {
            canvasEl.removeEventListener('pointerdown', onCanvasDown);
            canvasEl.removeEventListener('pointerup', onCanvasUp);
            canvasEl.removeEventListener('pointercancel', onCanvasUp);
        }
        if (toolbarHideTimer) {
            clearTimeout(toolbarHideTimer);
            toolbarHideTimer = null;
        }
    }

    // ------------------------------------------------------------------
    // Browser gesture prevention (tablet only)
    // ------------------------------------------------------------------
    // Targets that SHOULD receive native touch handling (they're our UI)
    function isUIChromeTarget(el) {
        if (!el) return false;
        var walk = el;
        while (walk && walk !== document.body) {
            if (walk === fab) return true;
            if (walk === panel) return true;
            if (walk === toolbarEl) return true;
            if (walk === hotEdgeEl) return true;
            if (walk === canvasStage) return false; // handled elsewhere
            walk = walk.parentNode;
        }
        return false;
    }

    function onDocTouchMove(e) {
        if (!active) return;
        // Let the canvas / text layer manage their own touch handling
        // (ink-engine.js already calls preventDefault on its own listeners)
        if (isUIChromeTarget(e.target)) return;
        // Block everything else — no pull-to-refresh, no scroll bounce.
        if (e.cancelable) e.preventDefault();
    }
    // Long-press context menu
    function onContextMenu(e) {
        if (!active) return;
        if (isUIChromeTarget(e.target)) return;
        e.preventDefault();
    }
    // Double-tap zoom (some browsers fire gesturestart)
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
    // Two-finger swipe navigation (tablet only)
    //
    // A single-finger touch is "drawing" — it belongs to ink-engine. A
    // two-finger horizontal swipe is "flip page". To distinguish cleanly:
    //
    //   - On touchstart with >=2 touches, we record the midpoint and tell
    //     ink-engine to cancel any stroke-in-progress (the first finger
    //     will have already started one a few ms earlier).
    //   - On touchmove with >=2 touches, we track the midpoint delta.
    //   - On touchend, if the net horizontal delta is > SWIPE_THRESHOLD_PX
    //     and dominates the vertical delta, we navigate.
    //
    // Listeners are attached once at module load and gated on `active`.
    // ------------------------------------------------------------------
    if (canvasStage) {
        canvasStage.addEventListener('touchstart', function (e) {
            if (!active) return;
            if (e.touches.length >= 2) {
                // Kill any stroke the first finger started before the second
                // finger arrived, so a 2-finger swipe never leaves a stray
                // mark on the page.
                if (window.inkEngine && typeof window.inkEngine.cancelStroke === 'function') {
                    window.inkEngine.cancelStroke();
                }
                var t1 = e.touches[0];
                var t2 = e.touches[1];
                var midX = (t1.clientX + t2.clientX) / 2;
                var midY = (t1.clientY + t2.clientY) / 2;
                swipeStart = {
                    x: midX, y: midY,
                    lastX: midX, lastY: midY
                };
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
                if (dx < 0) navigateNext();   // swipe left → next page
                else        navigatePrev();   // swipe right → prev page
            }
        };
        // Fire the decision once fingers start lifting. Use both touchend and
        // touchcancel because mobile browsers fire either depending on what
        // caused the sequence to end.
        canvasStage.addEventListener('touchend', function (e) {
            if (!active || !swipeStart) return;
            if (e.touches.length < 2) onSwipeEnd();
        }, { passive: true });
        canvasStage.addEventListener('touchcancel', function () {
            swipeStart = null;
        }, { passive: true });
    }

    // ------------------------------------------------------------------
    // Toggle button
    // ------------------------------------------------------------------
    if (toggleBtn) {
        toggleBtn.addEventListener('click', function (e) {
            e.preventDefault();
            if (active) exitTablet(); else enterTablet();
        });
    }

    // ------------------------------------------------------------------
    // Initial detection
    // ------------------------------------------------------------------
    function urlHasImmersiveParam() {
        try {
            var params = new URLSearchParams(window.location.search);
            return params.get('immersive') === '1';
        } catch (e) {
            return false;
        }
    }

    var forceImmersive = urlHasImmersiveParam();
    try {
        if (forceImmersive || (window.matchMedia && window.matchMedia(MQ).matches)) {
            enterTablet();
        }
    } catch (err) { /* no matchMedia — leave desktop */ }

    // If the device orientation changes between tablet/desktop thresholds,
    // respect the new media query but DON'T clobber a manual toggle or a URL
    // param: once the user has chosen a mode, we respect that choice.
    var userTouchedToggle = forceImmersive;
    if (toggleBtn) {
        toggleBtn.addEventListener('click', function () { userTouchedToggle = true; });
    }
    try {
        var mql = window.matchMedia(MQ);
        var listener = function (ev) {
            if (userTouchedToggle) return;
            if (ev.matches && !active) enterTablet();
            else if (!ev.matches && active) exitTablet();
        };
        if (mql.addEventListener) mql.addEventListener('change', listener);
        else if (mql.addListener) mql.addListener(listener);
    } catch (err) { /* ignore */ }
})();
