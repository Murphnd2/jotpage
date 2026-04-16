/*
 * Jyrnyl — book view
 *
 * Renders the user's notebook as a two-page spread you can flip through.
 * Ink data for each page is lazy-fetched via /app/api/page-thumbnail/{id}
 * and cached in memory. The current spread and one spread on either side
 * are prefetched so navigation feels instant.
 *
 * Landing behavior (Phase 3): on initial load the user sees only the cover,
 * centered and scaled up on the leather desk background. Tapping the cover
 * or swiping left "opens" the book — navigating to the first data spread.
 * The bubble-menu is the only visible chrome until the book is opened.
 *
 * Exposes window.bookView = { setFilter(ids) -> {shown,total}, refresh() }
 * so dashboard.jsp can drive it from the shared tag-filter handler.
 */
(function () {
    'use strict';

    var CANVAS_W = 1480;
    var CANVAS_H = 2100;
    var THUMB_W = 296;
    var THUMB_H = 420;

    var ctx = window.CONTEXT_PATH || '';
    var logoUrl = window.LOGO_URL || (ctx + '/images/jyrnyl-logo-square.svg');
    var bookUser = window.BOOK_USER || {};
    var allPages = Array.isArray(window.BOOK_PAGES) ? window.BOOK_PAGES.slice() : [];
    var filteredPages = allPages.slice();
    var activeTagIds = [];
    var currentSpread = 0;
    var inkCache = {};
    var inFlight = {};
    var coverLanding = true;   // true until the user "opens" the book

    var bookEl = document.getElementById('book');
    var leftPageEl = document.getElementById('bookLeftPage');
    var rightPageEl = document.getElementById('bookRightPage');
    var firstBtn = document.getElementById('bookFirst');
    var prevBtn = document.getElementById('bookPrev');
    var nextBtn = document.getElementById('bookNext');
    var lastBtn = document.getElementById('bookLast');
    var statusEl = document.getElementById('bookStatus');
    var stageEl = document.getElementById('bookStage');
    var tapHintEl = document.getElementById('coverTapHint');

    if (!bookEl || !leftPageEl || !rightPageEl) return;

    // ------------------------------------------------------------------
    // Layout maths
    // ------------------------------------------------------------------
    function isMobile() {
        return window.innerWidth < 720;
    }

    function spreadCount() {
        var n = filteredPages.length;
        if (isMobile()) return n + 2;
        return 1 + Math.ceil((n + 2) / 2);
    }

    function slotsForSpread(idx) {
        if (idx === 0) return { cover: true };
        var n = filteredPages.length;
        if (isMobile()) {
            if (idx - 1 >= n) return { mobile: true, rightAdd: true };
            return { mobile: true, rightPageIdx: idx - 1 };
        }
        var slotLeft = 2 * (idx - 1);
        var slotRight = slotLeft + 1;
        return {
            leftPageIdx: slotLeft === 0 ? -1 : slotLeft - 1,
            rightPageIdx: slotRight - 1,
            leftAdd: slotLeft === n + 1,
            rightAdd: slotRight === n + 1
        };
    }

    /**
     * Post-cover starting spread. Used after the user opens the book from
     * the cover landing; lands on the newest real page.
     */
    function lastRealSpreadIndex() {
        var n = filteredPages.length;
        if (n === 0) return 1; // first blank/add spread
        if (isMobile()) return n;
        return Math.floor(n / 2) + 1;
    }

    // ------------------------------------------------------------------
    // Fetching
    // ------------------------------------------------------------------
    function fetchPage(pageId) {
        if (inkCache[pageId]) return Promise.resolve(inkCache[pageId]);
        if (inFlight[pageId]) return inFlight[pageId];
        var p = fetch(ctx + '/app/api/page-thumbnail/' + pageId, {
            credentials: 'same-origin'
        }).then(function (r) {
            if (!r.ok) throw new Error('thumbnail ' + r.status);
            return r.json();
        }).then(function (data) {
            inkCache[pageId] = data;
            delete inFlight[pageId];
            return data;
        }).catch(function (err) {
            delete inFlight[pageId];
            throw err;
        });
        inFlight[pageId] = p;
        return p;
    }

    function prefetchAround(spreadIdx) {
        var toFetch = new Set();
        [spreadIdx - 1, spreadIdx, spreadIdx + 1].forEach(function (s) {
            if (s < 1 || s >= spreadCount()) return;
            var slots = slotsForSpread(s);
            if (slots.mobile) {
                if (slots.rightAdd) return;
                var mp = filteredPages[slots.rightPageIdx];
                if (mp) toFetch.add(mp.id);
            } else {
                if (!slots.leftAdd && slots.leftPageIdx >= 0) {
                    var lp = filteredPages[slots.leftPageIdx];
                    if (lp) toFetch.add(lp.id);
                }
                if (!slots.rightAdd && slots.rightPageIdx >= 0
                        && slots.rightPageIdx < filteredPages.length) {
                    var rp = filteredPages[slots.rightPageIdx];
                    if (rp) toFetch.add(rp.id);
                }
            }
        });
        toFetch.forEach(function (id) { fetchPage(id).catch(function () {}); });
    }

    // ------------------------------------------------------------------
    // Cover render — gold-stamped vinyl emblem + user footer
    // ------------------------------------------------------------------
    function renderCover(pageEl, side) {
        pageEl.innerHTML = '';
        pageEl.className = 'book-page ' + side + ' cover-page';

        var emblem = document.createElement('div');
        emblem.className = 'cover-emblem';
        var img = document.createElement('img');
        img.src = logoUrl;
        img.alt = 'Jyrnyl — Record your life.';
        img.draggable = false;
        emblem.appendChild(img);
        pageEl.appendChild(emblem);

        var footer = document.createElement('div');
        footer.className = 'cover-footer';

        if (bookUser.avatarUrl) {
            var avatar = document.createElement('img');
            avatar.className = 'cover-avatar';
            avatar.src = bookUser.avatarUrl;
            avatar.alt = '';
            avatar.referrerPolicy = 'no-referrer';
            avatar.draggable = false;
            footer.appendChild(avatar);
        }
        if (bookUser.displayName) {
            var name = document.createElement('span');
            name.className = 'cover-name';
            name.textContent = bookUser.displayName;
            footer.appendChild(name);
        }
        var count = document.createElement('span');
        count.className = 'cover-count';
        var n = typeof bookUser.pageCount === 'number'
            ? bookUser.pageCount : allPages.length;
        count.textContent = '\u00b7 ' + n + (n === 1 ? ' track' : ' tracks');
        footer.appendChild(count);

        pageEl.appendChild(footer);
    }

    function renderBlank(pageEl, side) {
        pageEl.innerHTML = '';
        pageEl.className = 'book-page ' + side + ' blank-page';
        pageEl.onclick = null;
    }

    function openNewPageModal() {
        // The bubble menu owns this modal now; dispatch the shared event.
        document.dispatchEvent(new CustomEvent('jyrnyl:open-new-page-modal'));
        var modalEl = document.getElementById('newPageModal');
        if (modalEl && window.bootstrap && window.bootstrap.Modal) {
            window.bootstrap.Modal.getOrCreateInstance(modalEl).show();
        }
    }

    function renderAddPage(pageEl, side) {
        pageEl.innerHTML = '';
        pageEl.className = 'book-page ' + side + ' add-page';
        var inner = document.createElement('div');
        inner.className = 'add-page-inner';

        var plus = document.createElement('div');
        plus.className = 'add-page-plus';
        plus.innerHTML = '<i class="bi bi-plus-lg"></i>';

        var label = document.createElement('div');
        label.className = 'add-page-label';
        label.textContent = 'Drop a new track';

        var hint = document.createElement('div');
        hint.className = 'add-page-hint';
        hint.textContent = 'Start your next entry';

        inner.appendChild(plus);
        inner.appendChild(label);
        inner.appendChild(hint);
        pageEl.appendChild(inner);

        pageEl.onclick = function (e) {
            e.preventDefault();
            openNewPageModal();
        };
    }

    function renderEmpty(pageEl, side, msg) {
        pageEl.innerHTML = '';
        pageEl.className = 'book-page ' + side + ' blank-page';
        var span = document.createElement('div');
        span.className = 'loading';
        span.textContent = msg;
        span.style.margin = 'auto';
        pageEl.appendChild(span);
    }

    function renderLoading(pageEl, side) {
        pageEl.innerHTML = '';
        pageEl.className = 'book-page ' + side;
        var wrap = document.createElement('div');
        wrap.className = 'page-canvas-wrap';
        var span = document.createElement('div');
        span.className = 'loading';
        span.textContent = 'Loading…';
        wrap.appendChild(span);
        pageEl.appendChild(wrap);
    }

    function renderPage(pageEl, side, meta) {
        if (!meta) {
            renderBlank(pageEl, side);
            return;
        }
        fetchPage(meta.id).then(function (data) {
            try {
                paintPage(pageEl, side, meta, data);
            } catch (err) {
                console.error('[book-view] paint failed for page', meta.id, err);
                renderEmpty(pageEl, side, 'Unable to render');
            }
        }).catch(function (err) {
            console.error('[book-view] fetch failed for page', meta.id, err);
            renderEmpty(pageEl, side, 'Unable to load');
        });
        renderLoading(pageEl, side);
    }

    function paintPage(pageEl, side, meta, data) {
        pageEl.innerHTML = '';
        pageEl.className = 'book-page ' + side + ' page-link';
        pageEl.onclick = function () {
            var href = ctx + '/app/page/' + meta.id
                + (activeTagIds.length ? '?tags=' + activeTagIds.join(',') : '');
            window.location.href = href;
        };

        var wrap = document.createElement('div');
        wrap.className = 'page-canvas-wrap';
        var canvas = document.createElement('canvas');
        canvas.className = 'page-canvas';
        canvas.width = THUMB_W;
        canvas.height = THUMB_H;
        wrap.appendChild(canvas);
        pageEl.appendChild(wrap);

        var metaEl = document.createElement('div');
        metaEl.className = 'page-meta';
        metaEl.textContent = (meta.createdAt || '') + '  \u00b7  ' + (meta.typeName || '');
        pageEl.appendChild(metaEl);

        if (meta.tags && meta.tags.length) {
            var tagsEl = document.createElement('div');
            tagsEl.className = 'page-tags';
            meta.tags.forEach(function (t) {
                var chip = document.createElement('span');
                chip.className = 'tag-chip';
                chip.style.background = t.color || '#8b6e4e';
                chip.textContent = t.name;
                tagsEl.appendChild(chip);
            });
            pageEl.appendChild(tagsEl);
        }

        drawThumbnail(canvas, data);
    }

    // ------------------------------------------------------------------
    // Miniature canvas renderer
    // ------------------------------------------------------------------
    var imageCache = {};
    function loadCustomBg(dataUrl, onReady) {
        var entry = imageCache[dataUrl];
        if (entry) {
            if (!entry.ready && typeof onReady === 'function') {
                entry.listeners.push(onReady);
            }
            return entry.img;
        }
        var img = new Image();
        entry = { img: img, ready: false, listeners: [] };
        if (typeof onReady === 'function') entry.listeners.push(onReady);
        imageCache[dataUrl] = entry;
        img.onload = function () {
            entry.ready = true;
            var cbs = entry.listeners;
            entry.listeners = [];
            cbs.forEach(function (cb) {
                try { cb(); } catch (err) {
                    console.error('[book-view] bg onload cb failed', err);
                }
            });
        };
        img.onerror = function () {
            console.error('[book-view] failed to load custom background',
                    (dataUrl || '').slice(0, 40) + '...');
            entry.listeners = [];
        };
        img.src = dataUrl;
        return img;
    }

    function drawThumbnail(canvas, data) {
        var c = canvas.getContext('2d');
        var scaleX = canvas.width / CANVAS_W;
        var scaleY = canvas.height / CANVAS_H;

        c.save();
        c.fillStyle = '#fffdf7';
        c.fillRect(0, 0, canvas.width, canvas.height);

        c.save();
        c.scale(scaleX, scaleY);
        drawBackground(c, data.backgroundType, data.backgroundData, function () {
            drawThumbnail(canvas, data);
        });
        if (Array.isArray(data.imageLayers)) {
            data.imageLayers.forEach(function (il) {
                if (!il.src) return;
                var key = il.id || il.src.substr(0, 60);
                if (!imageCache[key]) {
                    var img = new Image();
                    img.onload = function () { drawThumbnail(canvas, data); };
                    img.src = il.src;
                    imageCache[key] = img;
                }
                var cached = imageCache[key];
                if (cached.complete && cached.naturalWidth > 0) {
                    c.drawImage(cached, il.x, il.y, il.width, il.height);
                }
            });
        }
        var ink = data.inkData;
        if (ink && Array.isArray(ink.strokes)) {
            ink.strokes.forEach(function (stroke) { drawStroke(c, stroke); });
        }
        c.restore();

        var layers = data.textLayers;
        if (Array.isArray(layers) && layers.length) {
            c.save();
            layers.forEach(function (tb) {
                if (!tb || typeof tb.x !== 'number') return;
                var x = tb.x * scaleX;
                var y = tb.y * scaleY;
                var w = Math.max(4, (tb.width || 1380) * scaleX);
                var storedFont = (typeof tb.fontSize === 'number' && tb.fontSize > 0)
                        ? tb.fontSize : 160;
                if (storedFont < 20) storedFont *= 10;
                var fontPx = Math.max(5, storedFont * scaleY);
                var lineHeight = fontPx * 1.25;
                var blockH = (typeof tb.height === 'number' && tb.height > 0)
                        ? tb.height * scaleY
                        : Math.max(lineHeight, canvas.height - y - 2);
                var maxY = y + blockH;
                var color = (typeof tb.color === 'string' && tb.color) ? tb.color : '#2e2420';
                var rawText = (tb.text == null ? '' : String(tb.text)).replace(/\r/g, '');

                if (!rawText.trim() || fontPx < 6) {
                    drawTextSkeleton(c, x, y, w, blockH, Math.max(lineHeight, 8));
                    return;
                }

                c.fillStyle = color;
                c.font = fontPx + 'px "Source Sans 3", "Helvetica Neue", Arial, sans-serif';
                c.textBaseline = 'top';

                var cursorY = y;
                var rendered = false;
                var rawLines = rawText.split('\n');
                outer: for (var li = 0; li < rawLines.length; li++) {
                    if (cursorY + lineHeight > maxY) break;
                    var raw = rawLines[li];
                    if (!raw) {
                        cursorY += lineHeight * 0.6;
                        continue;
                    }
                    var words = raw.split(/\s+/);
                    var currentLine = '';
                    for (var wi = 0; wi < words.length; wi++) {
                        var word = words[wi];
                        if (!word) continue;
                        var candidate = currentLine ? currentLine + ' ' + word : word;
                        if (c.measureText(candidate).width > w && currentLine) {
                            c.fillText(currentLine, x, cursorY);
                            rendered = true;
                            cursorY += lineHeight;
                            if (cursorY + lineHeight > maxY) break outer;
                            currentLine = word;
                        } else {
                            currentLine = candidate;
                        }
                    }
                    if (currentLine && cursorY + lineHeight <= maxY) {
                        c.fillText(currentLine, x, cursorY);
                        rendered = true;
                        cursorY += lineHeight;
                    }
                }
                if (!rendered) {
                    drawTextSkeleton(c, x, y, w, blockH, Math.max(lineHeight, 8));
                }
            });
            c.restore();
        }
        c.restore();
    }

    function drawTextSkeleton(c, x, y, w, h, lineHeight) {
        if (w <= 0 || h <= 0) return;
        var rowH = Math.max(3, lineHeight * 0.38);
        var gap = Math.max(2, lineHeight * 0.42);
        var stride = rowH + gap;
        var widths = [0.96, 0.88, 0.72, 0.94, 0.6, 0.9, 0.82, 0.78];
        c.save();
        c.fillStyle = '#c4b5a6';
        var cursorY = y + gap;
        var idx = 0;
        while (cursorY + rowH <= y + h) {
            var lw = w * widths[idx % widths.length];
            c.fillRect(x, cursorY, Math.max(3, lw), rowH);
            cursorY += stride;
            idx++;
            if (idx > 60) break;
        }
        c.restore();
    }

    function drawStroke(c, stroke) {
        var pts = stroke && stroke.points;
        if (!pts || pts.length === 0) return;
        c.strokeStyle = stroke.color || '#000000';
        c.fillStyle = stroke.color || '#000000';
        c.lineWidth = Math.max(1, stroke.thickness || 3);
        c.lineCap = 'round';
        c.lineJoin = 'round';
        if (pts.length === 1) {
            c.beginPath();
            c.arc(pts[0].x, pts[0].y, (stroke.thickness || 3) / 2, 0, Math.PI * 2);
            c.fill();
            return;
        }
        c.beginPath();
        c.moveTo(pts[0].x, pts[0].y);
        for (var i = 1; i < pts.length; i++) c.lineTo(pts[i].x, pts[i].y);
        c.stroke();
    }

    function drawBackground(c, type, customData, onAsyncReady) {
        switch (type) {
            case 'custom':
                if (customData) {
                    var src = 'data:image/png;base64,' + customData;
                    var img = loadCustomBg(src, onAsyncReady);
                    if (img && img.complete && img.naturalWidth > 0) {
                        c.drawImage(img, 0, 0, CANVAS_W, CANVAS_H);
                    }
                }
                break;
            case 'lined':
                c.strokeStyle = '#d9c9a8';
                c.lineWidth = 2;
                for (var y = 80; y < CANVAS_H; y += 80) {
                    c.beginPath();
                    c.moveTo(60, y);
                    c.lineTo(CANVAS_W - 60, y);
                    c.stroke();
                }
                break;
            case 'dot_grid':
                c.fillStyle = '#c9b892';
                for (var dy = 60; dy < CANVAS_H; dy += 60) {
                    for (var dx = 60; dx < CANVAS_W; dx += 60) {
                        c.beginPath();
                        c.arc(dx, dy, 3, 0, Math.PI * 2);
                        c.fill();
                    }
                }
                break;
            case 'graph':
                c.strokeStyle = '#e8d9b8';
                c.lineWidth = 1;
                for (var gx = 60; gx < CANVAS_W; gx += 60) {
                    c.beginPath();
                    c.moveTo(gx, 0);
                    c.lineTo(gx, CANVAS_H);
                    c.stroke();
                }
                for (var gy = 60; gy < CANVAS_H; gy += 60) {
                    c.beginPath();
                    c.moveTo(0, gy);
                    c.lineTo(CANVAS_W, gy);
                    c.stroke();
                }
                break;
            case 'daily_calendar':
            case 'time_slot':
                c.strokeStyle = '#c9b892';
                c.lineWidth = 2;
                for (var hour = 6; hour <= 22; hour++) {
                    var hy = 160 + (hour - 6) * 95;
                    c.beginPath();
                    c.moveTo(180, hy);
                    c.lineTo(CANVAS_W - 60, hy);
                    c.stroke();
                }
                break;
            case 'monthly_calendar':
                c.strokeStyle = '#c9b892';
                c.lineWidth = 2;
                var gl = 60, gr = CANVAS_W - 60, gt = 200, gb = CANVAS_H - 60;
                var cols = 7, rows = 6;
                var cellW = (gr - gl) / cols, cellH = (gb - gt) / rows;
                for (var r = 0; r <= rows; r++) {
                    c.beginPath();
                    c.moveTo(gl, gt + r * cellH);
                    c.lineTo(gr, gt + r * cellH);
                    c.stroke();
                }
                for (var cc = 0; cc <= cols; cc++) {
                    c.beginPath();
                    c.moveTo(gl + cc * cellW, gt);
                    c.lineTo(gl + cc * cellW, gb);
                    c.stroke();
                }
                break;
            default: break;
        }
    }

    // ------------------------------------------------------------------
    // Spread rendering
    // ------------------------------------------------------------------
    function renderCurrentSpread() {
        currentSpread = Math.max(0, Math.min(currentSpread, spreadCount() - 1));

        if (filteredPages.length === 0 && activeTagIds.length > 0) {
            if (bookEl) bookEl.classList.remove('cover-only');
            renderBlank(leftPageEl, 'left-page');
            renderEmpty(rightPageEl, 'right-page',
                'No pages match the filter.');
            updateNavAndStatus();
            return;
        }

        var slots = slotsForSpread(currentSpread);

        if (slots.cover) {
            if (bookEl) bookEl.classList.add('cover-only');
            renderCover(rightPageEl, 'right-page');
            // Wire up "tap the cover to open"
            rightPageEl.onclick = function (e) {
                e.preventDefault();
                openBook();
            };
            updateNavAndStatus();
            return;
        }

        if (bookEl) bookEl.classList.remove('cover-only');

        if (slots.mobile) {
            renderBlank(leftPageEl, 'left-page');
            if (slots.rightAdd) {
                renderAddPage(rightPageEl, 'right-page');
            } else {
                var page = filteredPages[slots.rightPageIdx];
                renderPage(rightPageEl, 'right-page', page);
            }
            updateNavAndStatus();
            prefetchAround(currentSpread);
            return;
        }

        if (slots.leftAdd) {
            renderAddPage(leftPageEl, 'left-page');
        } else if (slots.leftPageIdx < 0) {
            renderBlank(leftPageEl, 'left-page');
        } else if (slots.leftPageIdx >= filteredPages.length) {
            renderBlank(leftPageEl, 'left-page');
        } else {
            renderPage(leftPageEl, 'left-page', filteredPages[slots.leftPageIdx]);
        }

        if (slots.rightAdd) {
            renderAddPage(rightPageEl, 'right-page');
        } else if (slots.rightPageIdx >= filteredPages.length) {
            renderBlank(rightPageEl, 'right-page');
        } else {
            renderPage(rightPageEl, 'right-page', filteredPages[slots.rightPageIdx]);
        }

        updateNavAndStatus();
        prefetchAround(currentSpread);
    }

    function updateNavAndStatus() {
        var total = spreadCount();
        if (firstBtn) firstBtn.disabled = (currentSpread <= 0);
        if (prevBtn) prevBtn.disabled = (currentSpread <= 0);
        if (nextBtn) nextBtn.disabled = (currentSpread >= total - 1);
        if (lastBtn) lastBtn.disabled = (currentSpread >= total - 1);
        if (!statusEl) return;

        if (currentSpread === 0) {
            statusEl.textContent = filteredPages.length === 0 && activeTagIds.length === 0
                ? 'Your journal is empty \u2014 tap to start.'
                : '';
            return;
        }
        if (filteredPages.length === 0) {
            statusEl.textContent = '';
            return;
        }

        var slots = slotsForSpread(currentSpread);
        var n = filteredPages.length;

        if (slots.mobile && slots.rightAdd) {
            statusEl.textContent = 'Start a new page';
            return;
        }
        if (!slots.mobile) {
            var leftHasPage = !slots.leftAdd && slots.leftPageIdx >= 0
                    && slots.leftPageIdx < n;
            var rightHasPage = !slots.rightAdd && slots.rightPageIdx >= 0
                    && slots.rightPageIdx < n;
            if (!leftHasPage && !rightHasPage) {
                statusEl.textContent = 'Start a new page';
                return;
            }
        }

        var shown;
        if (slots.mobile) {
            shown = 'Page ' + (slots.rightPageIdx + 1);
        } else if (slots.leftAdd || slots.leftPageIdx < 0
                || slots.leftPageIdx >= n) {
            shown = 'Page ' + (slots.rightPageIdx + 1);
        } else if (slots.rightAdd || slots.rightPageIdx >= n) {
            shown = 'Page ' + (slots.leftPageIdx + 1);
        } else {
            shown = 'Pages ' + (slots.leftPageIdx + 1)
                + ' \u2013 ' + (slots.rightPageIdx + 1);
        }
        statusEl.textContent = shown + ' of ' + n;
    }

    // ------------------------------------------------------------------
    // Navigation + cover landing
    // ------------------------------------------------------------------
    function exitCoverLanding() {
        if (!coverLanding) return;
        coverLanding = false;
        document.body.classList.remove('cover-landing-state');
        if (stageEl) stageEl.classList.remove('cover-landing');
    }

    function openBook() {
        if (!coverLanding) return;
        exitCoverLanding();
        currentSpread = lastRealSpreadIndex();
        renderCurrentSpread();
    }

    function goFirst() {
        if (coverLanding) {
            // The cover IS the "first" state — tapping first from here is a no-op
            return;
        }
        if (currentSpread > 0) {
            currentSpread = 0;
            // Returning to cover means re-entering the landing feel
            coverLanding = true;
            document.body.classList.add('cover-landing-state');
            if (stageEl) stageEl.classList.add('cover-landing');
            renderCurrentSpread();
        }
    }
    function goPrev() {
        if (coverLanding) return;
        if (currentSpread > 1) {
            currentSpread--;
            renderCurrentSpread();
        } else if (currentSpread === 1) {
            // Back past the first spread returns to the cover landing
            currentSpread = 0;
            coverLanding = true;
            document.body.classList.add('cover-landing-state');
            if (stageEl) stageEl.classList.add('cover-landing');
            renderCurrentSpread();
        }
    }
    function goNext() {
        if (coverLanding) {
            openBook();
            return;
        }
        if (currentSpread < spreadCount() - 1) {
            currentSpread++;
            renderCurrentSpread();
        }
    }
    function goLast() {
        var last = spreadCount() - 1;
        if (coverLanding) exitCoverLanding();
        if (currentSpread < last) {
            currentSpread = last;
            renderCurrentSpread();
        }
    }

    if (firstBtn) firstBtn.addEventListener('click', goFirst);
    if (prevBtn) prevBtn.addEventListener('click', goPrev);
    if (nextBtn) nextBtn.addEventListener('click', goNext);
    if (lastBtn) lastBtn.addEventListener('click', goLast);

    document.addEventListener('keydown', function (e) {
        if (window.JOTPAGE_VIEW_MODE !== 'book') return;
        var tag = (e.target && e.target.tagName) || '';
        if (tag === 'INPUT' || tag === 'TEXTAREA') return;
        if (e.key === 'Home') { goFirst(); e.preventDefault(); }
        else if (e.key === 'ArrowLeft') { goPrev(); e.preventDefault(); }
        else if (e.key === 'ArrowRight') { goNext(); e.preventDefault(); }
        else if (e.key === 'End') { goLast(); e.preventDefault(); }
        else if ((e.key === ' ' || e.key === 'Enter') && coverLanding) {
            openBook();
            e.preventDefault();
        }
    });

    // Touch swipe — swiping left on the cover also opens the book
    (function () {
        if (!stageEl) return;
        var startX = 0, startY = 0, tracking = false;
        stageEl.addEventListener('touchstart', function (e) {
            if (!e.touches || e.touches.length !== 1) return;
            startX = e.touches[0].clientX;
            startY = e.touches[0].clientY;
            tracking = true;
        }, { passive: true });
        stageEl.addEventListener('touchend', function (e) {
            if (!tracking) return;
            tracking = false;
            var t = e.changedTouches && e.changedTouches[0];
            if (!t) return;
            var dx = t.clientX - startX;
            var dy = t.clientY - startY;
            if (Math.abs(dx) > 48 && Math.abs(dx) > Math.abs(dy)) {
                if (dx < 0) goNext(); else goPrev();
            }
        });
    })();

    // ------------------------------------------------------------------
    // Filter integration
    // ------------------------------------------------------------------
    function filterPages() {
        if (activeTagIds.length === 0) {
            filteredPages = allPages.slice();
            return;
        }
        filteredPages = allPages.filter(function (p) {
            if (!p.tagIds || !p.tagIds.length) return false;
            return activeTagIds.some(function (tid) {
                var n = parseInt(tid, 10);
                return p.tagIds.indexOf(n) !== -1;
            });
        });
    }

    function setFilter(ids) {
        activeTagIds = Array.isArray(ids) ? ids.slice() : [];
        filterPages();
        // When filtering, leave cover landing and jump to most recent match.
        if (coverLanding && activeTagIds.length > 0) exitCoverLanding();
        if (!coverLanding) {
            currentSpread = lastRealSpreadIndex();
        }
        renderCurrentSpread();
        return { shown: filteredPages.length, total: allPages.length };
    }

    // ------------------------------------------------------------------
    // Init + resize
    // ------------------------------------------------------------------
    function init() {
        try {
            var params = new URLSearchParams(window.location.search);
            var raw = params.get('tags');
            if (raw) {
                activeTagIds = raw.split(',').map(function (s) { return s.trim(); })
                                 .filter(Boolean);
            }
        } catch (err) { /* ignore */ }
        filterPages();

        // If the user arrived with a tag filter already applied, skip the
        // cover landing and drop them on matching pages.
        if (activeTagIds.length > 0 || allPages.length === 0) {
            coverLanding = activeTagIds.length > 0 ? false : true;
        }

        if (coverLanding) {
            document.body.classList.add('cover-landing-state');
            if (stageEl) stageEl.classList.add('cover-landing');
            currentSpread = 0;
        } else {
            currentSpread = lastRealSpreadIndex();
        }
        renderCurrentSpread();
    }

    var resizeTimer = null;
    window.addEventListener('resize', function () {
        if (resizeTimer) clearTimeout(resizeTimer);
        resizeTimer = setTimeout(function () {
            currentSpread = Math.min(currentSpread, spreadCount() - 1);
            renderCurrentSpread();
        }, 120);
    });

    window.bookView = {
        setFilter: setFilter,
        refresh: function () { renderCurrentSpread(); },
        openBook: openBook
    };

    init();
})();
