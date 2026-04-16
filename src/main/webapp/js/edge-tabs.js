/*
 * Jyrnyl — edge tabs (editor only)
 *
 * Left tab:  first page (<<) + prev page (<)
 * Right tab: next page (>) + last page (>>)
 * Top tab:   tag this page + delete page
 *
 * Navigation actions auto-save the current page before navigating by
 * reusing the same saveAndNavigate() pattern as the Phase 6 edge arrows:
 * click #save-btn, observe #save-status mutations, navigate on "Saved".
 *
 * Reads target hrefs from body data-first-href, data-prev-href,
 * data-next-href, data-last-href attributes set by the server.
 */
(function () {
    'use strict';

    var body = document.body;
    var leftTab = document.getElementById('edgeTabLeft');
    var rightTab = document.getElementById('edgeTabRight');
    var topTab = document.getElementById('edgeTabTop');
    if (!leftTab && !rightTab && !topTab) return;

    var saveBtn = document.getElementById('save-btn');
    var saveStatus = document.getElementById('save-status');
    var canvas = document.getElementById('ink-canvas');

    // ------------------------------------------------------------------
    // Visibility: hide tabs when no valid target href
    // ------------------------------------------------------------------
    function href(attr) {
        var h = body.getAttribute(attr);
        return (h && h !== '#' && h.length > 0) ? h : null;
    }

    var firstHref = href('data-first-href');
    var prevHref  = href('data-prev-href');
    var nextHref  = href('data-next-href');
    var lastHref  = href('data-last-href');

    if (leftTab) {
        if (!firstHref && !prevHref) leftTab.classList.add('hidden');
        leftTab.querySelector('[data-action="first"]').disabled = !firstHref;
        leftTab.querySelector('[data-action="prev"]').disabled = !prevHref;
    }
    if (rightTab) {
        if (!nextHref && !lastHref) rightTab.classList.add('hidden');
        rightTab.querySelector('[data-action="next"]').disabled = !nextHref;
        rightTab.querySelector('[data-action="last"]').disabled = !lastHref;
    }

    // Top tab: hide if not writable (no page-specific actions make sense)
    var isPro = body.getAttribute('data-is-pro') === 'true';
    if (topTab) {
        var deleteBtn = topTab.querySelector('[data-action="delete"]');
        if (!isPro && deleteBtn) deleteBtn.style.display = 'none';
    }

    // ------------------------------------------------------------------
    // Save-then-navigate helper (same pattern as editor.jsp inline script)
    // ------------------------------------------------------------------
    function saveAndNavigate(targetHref, btnEl) {
        if (!targetHref) return;
        if (!saveBtn || !saveStatus) {
            window.location.href = targetHref;
            return;
        }
        if (btnEl) btnEl.classList.add('loading');
        var parentTab = btnEl ? btnEl.closest('.edge-tab') : null;
        if (parentTab) {
            parentTab.classList.add('flash');
            setTimeout(function () { parentTab.classList.remove('flash'); }, 150);
        }

        var done = false;
        var observer = new MutationObserver(function () {
            if (done) return;
            var t = (saveStatus.textContent || '').trim();
            if (!t) return;
            if (/^saved$/i.test(t) || /^locked$/i.test(t)) {
                done = true;
                observer.disconnect();
                window.location.href = targetHref;
            } else if (/^error/i.test(t)) {
                done = true;
                observer.disconnect();
                if (btnEl) btnEl.classList.remove('loading');
            }
        });
        observer.observe(saveStatus, { childList: true, characterData: true, subtree: true });
        try { saveBtn.click(); }
        catch (err) {
            observer.disconnect();
            window.location.href = targetHref;
            return;
        }

        // Safety timeout: 2s max wait then navigate anyway
        setTimeout(function () {
            if (done) return;
            done = true;
            observer.disconnect();
            if (btnEl) btnEl.classList.remove('loading');
            window.location.href = targetHref;
        }, 2000);
    }

    // Also respond to the event dispatched by tablet-mode.js two-finger swipe
    document.addEventListener('jyrnyl:save-and-navigate', function (e) {
        var h = e && e.detail && e.detail.href;
        if (h) saveAndNavigate(h, null);
    });

    // ------------------------------------------------------------------
    // Wire up navigation button clicks
    // ------------------------------------------------------------------
    function wireNav(tab) {
        if (!tab) return;
        tab.querySelectorAll('.et-btn[data-action]').forEach(function (btn) {
            btn.addEventListener('click', function (e) {
                e.preventDefault();
                var action = btn.getAttribute('data-action');
                var target = null;
                switch (action) {
                    case 'first':  target = firstHref; break;
                    case 'prev':   target = prevHref;  break;
                    case 'next':   target = nextHref;  break;
                    case 'last':   target = lastHref;  break;
                    case 'tag':
                        document.dispatchEvent(new CustomEvent('jyrnyl:open-tag-editor'));
                        return;
                    case 'delete':
                        document.dispatchEvent(new CustomEvent('jyrnyl:delete-page'));
                        return;
                }
                if (target) saveAndNavigate(target, btn);
            });
        });
    }

    wireNav(leftTab);
    wireNav(rightTab);
    wireNav(topTab);

    // ------------------------------------------------------------------
    // Fade edge tabs while actively drawing so they don't obstruct
    // ------------------------------------------------------------------
    if (canvas) {
        canvas.addEventListener('pointerdown', function () {
            body.classList.add('drawing-active');
        });
        canvas.addEventListener('pointerup', function () {
            body.classList.remove('drawing-active');
        });
        canvas.addEventListener('pointercancel', function () {
            body.classList.remove('drawing-active');
        });
    }
})();
