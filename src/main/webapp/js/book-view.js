/*
 * JotPage — book view
 *
 * Renders the user's notebook as a two-page spread you can flip through.
 * Ink data for each page is lazy-fetched via /app/api/page-thumbnail/{id}
 * and cached in memory. The current spread and one spread on either side
 * are prefetched so navigation feels instant.
 *
 * Exposes window.bookView = { setFilter(ids) -> {shown,total}, refresh() }
 * so dashboard.jsp can drive it from the shared tag-filter handler.
 */
(function () {
    'use strict';

    var CANVAS_W = 1480;
    var CANVAS_H = 2100;
    var THUMB_W = 296;   // A5-ratio * 2 for crisp rendering on HiDPI
    var THUMB_H = 420;

    var ctx = window.CONTEXT_PATH || '';
    var allPages = Array.isArray(window.BOOK_PAGES) ? window.BOOK_PAGES.slice() : [];
    var filteredPages = allPages.slice();
    var activeTagIds = [];
    var currentSpread = 0; // will be set to last spread once we know the count
    var inkCache = {};     // pageId -> fetched detail
    var inFlight = {};     // pageId -> Promise to avoid duplicate fetches

    var bookEl = document.getElementById('book');
    var leftPageEl = document.getElementById('bookLeftPage');
    var rightPageEl = document.getElementById('bookRightPage');
    var prevBtn = document.getElementById('bookPrev');
    var nextBtn = document.getElementById('bookNext');
    var statusEl = document.getElementById('bookStatus');
    var stageEl = document.getElementById('bookStage');

    if (!bookEl || !leftPageEl || !rightPageEl) return;

    // ------------------------------------------------------------------
    // Layout maths
    // ------------------------------------------------------------------
    function isMobile() {
        return window.innerWidth < 720;
    }

    /**
     * Desktop (two-up, traditional book):
     *   spread 0 = cover (book closed)
     *   spread 1 = [blank, page 1]               (inside front cover | first page)
     *   spread 2 = [page 2, page 3]
     *   spread 3 = [page 4, page 5]
     *   ...
     *   trailing spread holds an "Add Page" placeholder at slot (N+1),
     *   so the book always ends with a visible "+ New Page" affordance.
     *
     * Mobile (single-up):
     *   spread 0 = cover
     *   spread 1..N = page (k-1)
     *   spread N+1 = Add Page
     */
    function spreadCount() {
        var n = filteredPages.length;
        if (isMobile()) return n + 2;               // cover + N pages + add
        return 1 + Math.ceil((n + 2) / 2);          // cover + data spreads (+ add slot)
    }

    function slotsForSpread(idx) {
        if (idx === 0) return { cover: true };
        var n = filteredPages.length;
        if (isMobile()) {
            if (idx - 1 >= n) return { mobile: true, rightAdd: true };
            return { mobile: true, rightPageIdx: idx - 1 };
        }
        var slotLeft = 2 * (idx - 1);       // 0,2,4,...
        var slotRight = slotLeft + 1;       // 1,3,5,...
        // slot 0 = blank inside front cover
        // slot 1..N = page index 0..N-1
        // slot N+1 = Add Page
        return {
            leftPageIdx: slotLeft === 0 ? -1 : slotLeft - 1,
            rightPageIdx: slotRight - 1,
            leftAdd: slotLeft === n + 1,
            rightAdd: slotRight === n + 1
        };
    }

    /**
     * Start position: the spread that contains the newest real page, so the
     * user lands on their latest entries instead of on the Add Page slot.
     */
    function lastRealSpreadIndex() {
        var n = filteredPages.length;
        if (n === 0) return 0; // just the cover
        if (isMobile()) return n; // cover=0, pages start at 1, newest at n
        // Desktop: newest page index n-1 lives at slot n, which is in spread
        // floor(n / 2) + 1.
        return Math.floor(n / 2) + 1;
    }

    // ------------------------------------------------------------------
    // Fetching page render data
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
    // Rendering a single page (cover, blank, or ink)
    // ------------------------------------------------------------------
    function renderCover(pageEl, side) {
        pageEl.innerHTML = '';
        pageEl.className = 'book-page ' + side + ' cover-page';
        var title = document.createElement('div');
        title.className = 'cover-title';
        title.textContent = 'My Journal';
        var flourish = document.createElement('div');
        flourish.className = 'cover-flourish';
        flourish.textContent = '\u2756 \u2756 \u2756';
        var subtitle = document.createElement('div');
        subtitle.className = 'cover-subtitle';
        subtitle.textContent = 'A quiet place for your pages';
        pageEl.appendChild(title);
        pageEl.appendChild(flourish);
        pageEl.appendChild(subtitle);
    }

    function renderBlank(pageEl, side) {
        pageEl.innerHTML = '';
        pageEl.className = 'book-page ' + side + ' blank-page';
        pageEl.onclick = null;
    }

    function openNewPageModal() {
        var modalEl = document.getElementById('newPageModal');
        if (!modalEl) return;
        if (window.bootstrap && window.bootstrap.Modal) {
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
        label.textContent = 'New Page';

        var hint = document.createElement('div');
        hint.className = 'add-page-hint';
        hint.textContent = 'Begin a fresh entry';

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
        // Schedule the fetch so on-screen pages get populated quickly
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
        // Immediate skeleton while we wait
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
    // dataUrl -> { img, ready, listeners: [fn] }
    // Never call onReady synchronously on a cache hit — the caller of
    // loadCustomBg already checks img.complete and draws in that case, so
    // firing onReady here would cause drawThumbnail → drawBackground →
    // loadCustomBg → onReady → drawThumbnail... infinite recursion.
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
        // Fill white
        c.fillStyle = '#fffdf7';
        c.fillRect(0, 0, canvas.width, canvas.height);

        // Background
        c.save();
        c.scale(scaleX, scaleY);
        drawBackground(c, data.backgroundType, data.backgroundData, function () {
            // Custom bg async re-paint
            drawThumbnail(canvas, data);
        });
        // Strokes
        var ink = data.inkData;
        if (ink && Array.isArray(ink.strokes)) {
            ink.strokes.forEach(function (stroke) {
                drawStroke(c, stroke);
            });
        }
        c.restore();

        // Text layers — render a miniature preview of the actual text
        // content so voice-transcribed pages read as text, not as a gray
        // placeholder. Stored fontSize is in canvas pixels (post-scale-fix),
        // so we convert to thumbnail pixels with scaleY. Pages saved before
        // the scale fix stored the raw UI point size; detect those (fontSize
        // < 20) and scale them up.
        var layers = data.textLayers;
        if (Array.isArray(layers) && layers.length) {
            c.save();
            layers.forEach(function (tb) {
                if (!tb || typeof tb.x !== 'number') return;

                var x = tb.x * scaleX;
                var y = tb.y * scaleY;
                var w = Math.max(4, (tb.width || 1380) * scaleX);

                var storedFont = (typeof tb.fontSize === 'number' && tb.fontSize > 0)
                        ? tb.fontSize
                        : 160;
                if (storedFont < 20) storedFont *= 10; // legacy compat
                var fontPx = Math.max(5, storedFont * scaleY);
                var lineHeight = fontPx * 1.25;

                var blockH = (typeof tb.height === 'number' && tb.height > 0)
                        ? tb.height * scaleY
                        : Math.max(lineHeight, canvas.height - y - 2);
                var maxY = y + blockH;

                var color = (typeof tb.color === 'string' && tb.color)
                        ? tb.color
                        : '#3b2f2f';

                var rawText = (tb.text == null ? '' : String(tb.text))
                        .replace(/\r/g, '');

                // Skeleton fallback when there's nothing to render or the
                // font would be too small to be readable at thumbnail scale.
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
                        // Blank line = paragraph break. Give it a little
                        // vertical breathing room but not a full line.
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

                // If we couldn't render anything (e.g. every word was wider
                // than the block, or the block was too small), fall back to
                // the skeleton so we never show an empty block.
                if (!rendered) {
                    drawTextSkeleton(c, x, y, w, blockH, Math.max(lineHeight, 8));
                }
            });
            c.restore();
        }
        c.restore();
    }

    /**
     * Draws a stack of horizontal warm-gray bars inside the given box — used
     * as a "text preview skeleton" when we can't render actual text (empty
     * block, oversized words, or font too small to be readable).
     */
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
            if (idx > 60) break; // safety
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
            default: /* blank */ break;
        }
    }

    // ------------------------------------------------------------------
    // Spread rendering
    // ------------------------------------------------------------------
    function renderCurrentSpread() {
        currentSpread = Math.max(0, Math.min(currentSpread, spreadCount() - 1));

        // Zero-page filter case: only cover is available
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
            updateNavAndStatus();
            return;
        }

        // Any non-cover spread: restore the normal two-page layout
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

        // Desktop spread — left side
        if (slots.leftAdd) {
            renderAddPage(leftPageEl, 'left-page');
        } else if (slots.leftPageIdx < 0) {
            renderBlank(leftPageEl, 'left-page');
        } else if (slots.leftPageIdx >= filteredPages.length) {
            renderBlank(leftPageEl, 'left-page');
        } else {
            renderPage(leftPageEl, 'left-page', filteredPages[slots.leftPageIdx]);
        }

        // Desktop spread — right side
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
        if (prevBtn) prevBtn.disabled = (currentSpread <= 0);
        if (nextBtn) nextBtn.disabled = (currentSpread >= total - 1);
        if (!statusEl) return;

        if (currentSpread === 0) {
            statusEl.textContent = filteredPages.length === 0 && activeTagIds.length === 0
                ? 'Your journal is empty \u2014 start a new page.'
                : 'Front cover';
            return;
        }
        if (filteredPages.length === 0) {
            statusEl.textContent = '';
            return;
        }

        var slots = slotsForSpread(currentSpread);
        var n = filteredPages.length;

        // Spreads whose only meaningful content is the Add Page slot
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
    // Navigation
    // ------------------------------------------------------------------
    function goPrev() {
        if (currentSpread > 0) {
            currentSpread--;
            renderCurrentSpread();
        }
    }
    function goNext() {
        if (currentSpread < spreadCount() - 1) {
            currentSpread++;
            renderCurrentSpread();
        }
    }

    if (prevBtn) prevBtn.addEventListener('click', goPrev);
    if (nextBtn) nextBtn.addEventListener('click', goNext);

    document.addEventListener('keydown', function (e) {
        if (window.JOTPAGE_VIEW_MODE !== 'book') return;
        // Don't hijack arrows when the user is typing in an input
        var tag = (e.target && e.target.tagName) || '';
        if (tag === 'INPUT' || tag === 'TEXTAREA') return;
        if (e.key === 'ArrowLeft') { goPrev(); e.preventDefault(); }
        else if (e.key === 'ArrowRight') { goNext(); e.preventDefault(); }
    });

    // Touch swipe
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
    // Filter integration (called by the shared tag filter handler)
    // ------------------------------------------------------------------
    function filterPages() {
        if (activeTagIds.length === 0) {
            filteredPages = allPages.slice();
            return;
        }
        filteredPages = allPages.filter(function (p) {
            if (!p.tagIds || !p.tagIds.length) return false;
            return activeTagIds.some(function (tid) {
                // tagIds on server are numbers; chips emit strings. Coerce.
                var n = parseInt(tid, 10);
                return p.tagIds.indexOf(n) !== -1;
            });
        });
    }

    function setFilter(ids) {
        activeTagIds = Array.isArray(ids) ? ids.slice() : [];
        filterPages();
        // After filtering, jump to the last spread so the user sees their
        // newest matching pages first (same as initial load).
        currentSpread = lastRealSpreadIndex();
        renderCurrentSpread();
        return { shown: filteredPages.length, total: allPages.length };
    }

    // ------------------------------------------------------------------
    // Init + resize
    // ------------------------------------------------------------------
    function init() {
        // Seed activeTagIds from ?tags= so the first render already reflects
        // the filter when someone returns from the editor.
        try {
            var params = new URLSearchParams(window.location.search);
            var raw = params.get('tags');
            if (raw) {
                activeTagIds = raw.split(',').map(function (s) { return s.trim(); })
                                 .filter(Boolean);
            }
        } catch (err) { /* ignore */ }
        filterPages();
        currentSpread = lastRealSpreadIndex();
        renderCurrentSpread();
    }

    var resizeTimer = null;
    window.addEventListener('resize', function () {
        if (resizeTimer) clearTimeout(resizeTimer);
        resizeTimer = setTimeout(function () {
            // Clamp & re-render (layout changes between mobile/desktop)
            currentSpread = Math.min(currentSpread, spreadCount() - 1);
            renderCurrentSpread();
        }, 120);
    });

    window.bookView = {
        setFilter: setFilter,
        refresh: function () { renderCurrentSpread(); }
    };

    init();
})();
