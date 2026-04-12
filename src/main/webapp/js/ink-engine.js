(function () {
    'use strict';

    var CANVAS_W = 1480;
    var CANVAS_H = 2100;
    var A5_RATIO_W = 148;
    var A5_RATIO_H = 210;
    // The canvas is A5 at 10x resolution, so a real-world N-point font size
    // is stored as N * POINT_TO_PIXEL canvas pixels. The UI <select> exposes
    // point sizes; we multiply on write and divide on read. Rendering uses
    // the stored canvas-pixel value directly (multiplied by the display
    // scale factor in layoutTextBlock).
    var POINT_TO_PIXEL = 10;
    var DEFAULT_FONT_POINT = 16;

    var canvas = document.getElementById('ink-canvas');
    var wrap = document.getElementById('canvas-wrap');
    var stage = document.getElementById('canvas-stage');
    var ctx = canvas.getContext('2d');

    var saveBtn = document.getElementById('save-btn');
    var saveStatus = document.getElementById('save-status');

    var btnPen = document.getElementById('tool-pen');
    var btnEraser = document.getElementById('tool-eraser');
    var btnText = document.getElementById('tool-text');
    var colorInput = document.getElementById('tool-color');
    var thicknessInput = document.getElementById('tool-thickness');
    var thicknessValue = document.getElementById('tool-thickness-value');
    var btnUndo = document.getElementById('tool-undo');
    var btnRedo = document.getElementById('tool-redo');
    var textLayer = document.getElementById('text-layer');
    var fontSizeWrap = document.getElementById('font-size-wrap');
    var fontSizeSelect = document.getElementById('tool-fontsize');


    var state = {
        tool: 'pen',
        color: '#000000',
        thickness: 3,
        strokes: [],
        currentStroke: null,
        activePointerId: null,
        history: [],
        historyIndex: -1,
        dirty: false,
        textLayers: [],
        selectedTextId: null
    };

    // ------------------------------------------------------------------
    // Initial strokes from pageData
    // ------------------------------------------------------------------
    (function loadInitialStrokes() {
        var ink = pageData && pageData.inkData;
        if (ink && Array.isArray(ink.strokes)) {
            state.strokes = ink.strokes.map(cloneStroke);
        }
        commitHistory();
        scheduleRender();
    })();

    // ------------------------------------------------------------------
    // Initial text layers from pageData
    // ------------------------------------------------------------------
    (function loadInitialTextLayers() {
        var existing = pageData && pageData.textLayers;
        if (Array.isArray(existing)) {
            for (var i = 0; i < existing.length; i++) {
                var tb = normalizeTextBlock(existing[i]);
                if (tb) {
                    state.textLayers.push(tb);
                    createTextBlockDom(tb);
                }
            }
        }
        layoutTextBlocks();
    })();

    // ------------------------------------------------------------------
    // Layout / canvas sizing
    // ------------------------------------------------------------------
    function fitCanvas() {
        var availW = stage.clientWidth - 32;
        var availH = stage.clientHeight - 32;
        if (availW <= 0 || availH <= 0) return;
        var wByH = availH * (A5_RATIO_W / A5_RATIO_H);
        var targetW, targetH;
        if (wByH <= availW) {
            targetW = wByH;
            targetH = availH;
        } else {
            targetW = availW;
            targetH = availW * (A5_RATIO_H / A5_RATIO_W);
        }
        wrap.style.width = targetW + 'px';
        wrap.style.height = targetH + 'px';
        layoutTextBlocks();
    }
    window.addEventListener('resize', fitCanvas);
    fitCanvas();

    // ------------------------------------------------------------------
    // Coordinate conversion
    // ------------------------------------------------------------------
    function eventToCanvas(e) {
        var rect = canvas.getBoundingClientRect();
        var x = (e.clientX - rect.left) * (CANVAS_W / rect.width);
        var y = (e.clientY - rect.top) * (CANVAS_H / rect.height);
        var pressure = (typeof e.pressure === 'number' && e.pressure > 0) ? e.pressure : 0.5;
        return { x: x, y: y, pressure: pressure };
    }

    // ------------------------------------------------------------------
    // Pointer handlers
    // ------------------------------------------------------------------
    canvas.addEventListener('pointerdown', function (e) {
        if (state.tool === 'text') return; // text-layer handles clicks when in text mode
        if (state.activePointerId !== null) return;
        e.preventDefault();
        canvas.setPointerCapture(e.pointerId);
        state.activePointerId = e.pointerId;

        var pt = eventToCanvas(e);
        if (state.tool === 'pen') {
            state.currentStroke = {
                points: [pt],
                color: state.color,
                thickness: state.thickness
            };
        } else if (state.tool === 'eraser') {
            eraseAt(pt);
        }
        scheduleRender();
    });

    canvas.addEventListener('pointermove', function (e) {
        if (state.activePointerId !== e.pointerId) return;
        e.preventDefault();
        var pt = eventToCanvas(e);
        if (state.tool === 'pen' && state.currentStroke) {
            state.currentStroke.points.push(pt);
            scheduleRender();
        } else if (state.tool === 'eraser' && e.buttons) {
            eraseAt(pt);
            scheduleRender();
        }
    });

    function endStroke(e) {
        if (state.activePointerId !== e.pointerId) return;
        state.activePointerId = null;
        try { canvas.releasePointerCapture(e.pointerId); } catch (err) {}
        if (state.tool === 'pen' && state.currentStroke) {
            if (state.currentStroke.points.length >= 1) {
                state.strokes.push(state.currentStroke);
                commitHistory();
                state.dirty = true;
            }
            state.currentStroke = null;
        }
        scheduleRender();
    }
    canvas.addEventListener('pointerup', endStroke);
    canvas.addEventListener('pointercancel', endStroke);
    canvas.addEventListener('pointerleave', function (e) {
        if (state.activePointerId === e.pointerId && state.tool === 'pen') {
            endStroke(e);
        }
    });

    // Disable default browser gestures on canvas
    canvas.addEventListener('touchstart', function (e) { e.preventDefault(); }, { passive: false });
    canvas.addEventListener('touchmove', function (e) { e.preventDefault(); }, { passive: false });

    // ------------------------------------------------------------------
    // Eraser: hit-test against whole strokes
    // ------------------------------------------------------------------
    function eraseAt(pt) {
        var threshold = 12;
        for (var i = state.strokes.length - 1; i >= 0; i--) {
            if (strokeHitTest(state.strokes[i], pt, threshold)) {
                state.strokes.splice(i, 1);
                commitHistory();
                state.dirty = true;
                return;
            }
        }
    }

    function strokeHitTest(stroke, pt, threshold) {
        var pts = stroke.points;
        var effective = threshold + (stroke.thickness || 1) / 2;
        if (pts.length === 1) {
            return distSq(pts[0], pt) <= effective * effective;
        }
        for (var i = 0; i < pts.length - 1; i++) {
            if (pointToSegmentDistSq(pt, pts[i], pts[i + 1]) <= effective * effective) {
                return true;
            }
        }
        return false;
    }

    function distSq(a, b) {
        var dx = a.x - b.x, dy = a.y - b.y;
        return dx * dx + dy * dy;
    }

    function pointToSegmentDistSq(p, a, b) {
        var dx = b.x - a.x, dy = b.y - a.y;
        var lenSq = dx * dx + dy * dy;
        if (lenSq === 0) return distSq(p, a);
        var t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq;
        if (t < 0) t = 0; else if (t > 1) t = 1;
        var proj = { x: a.x + t * dx, y: a.y + t * dy };
        return distSq(p, proj);
    }

    // ------------------------------------------------------------------
    // History
    // ------------------------------------------------------------------
    function commitHistory() {
        state.history = state.history.slice(0, state.historyIndex + 1);
        state.history.push(state.strokes.map(cloneStroke));
        state.historyIndex = state.history.length - 1;
        if (state.history.length > 100) {
            state.history.shift();
            state.historyIndex--;
        }
        updateHistoryButtons();
    }

    function undo() {
        if (state.historyIndex <= 0) return;
        state.historyIndex--;
        state.strokes = state.history[state.historyIndex].map(cloneStroke);
        state.dirty = true;
        updateHistoryButtons();
        scheduleRender();
    }

    function redo() {
        if (state.historyIndex >= state.history.length - 1) return;
        state.historyIndex++;
        state.strokes = state.history[state.historyIndex].map(cloneStroke);
        state.dirty = true;
        updateHistoryButtons();
        scheduleRender();
    }

    function updateHistoryButtons() {
        btnUndo.disabled = state.historyIndex <= 0;
        btnRedo.disabled = state.historyIndex >= state.history.length - 1;
    }

    function cloneStroke(s) {
        return {
            color: s.color,
            thickness: s.thickness,
            points: s.points.map(function (p) {
                return { x: p.x, y: p.y, pressure: p.pressure };
            })
        };
    }

    // ------------------------------------------------------------------
    // Rendering
    // ------------------------------------------------------------------
    var renderScheduled = false;
    function scheduleRender() {
        if (renderScheduled) return;
        renderScheduled = true;
        requestAnimationFrame(function () {
            renderScheduled = false;
            render();
        });
    }

    function render() {
        ctx.save();
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
        drawBackground(pageData && pageData.backgroundType);
        for (var i = 0; i < state.strokes.length; i++) {
            drawStroke(state.strokes[i]);
        }
        if (state.currentStroke) {
            drawStroke(state.currentStroke);
        }
        ctx.restore();
    }

    function drawStroke(stroke) {
        var pts = stroke.points;
        if (!pts || pts.length === 0) return;
        ctx.strokeStyle = stroke.color || '#000000';
        ctx.lineWidth = stroke.thickness || 3;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        if (pts.length === 1) {
            ctx.beginPath();
            ctx.arc(pts[0].x, pts[0].y, (stroke.thickness || 3) / 2, 0, Math.PI * 2);
            ctx.fillStyle = stroke.color || '#000000';
            ctx.fill();
            return;
        }
        ctx.beginPath();
        ctx.moveTo(pts[0].x, pts[0].y);
        for (var i = 1; i < pts.length; i++) {
            ctx.lineTo(pts[i].x, pts[i].y);
        }
        ctx.stroke();
    }

    var customBgImage = null;
    var customBgImageSrc = null;

    function drawCustomBackground() {
        if (!pageData || !pageData.backgroundData) return;
        var src = 'data:image/png;base64,' + pageData.backgroundData;
        if (customBgImageSrc !== src) {
            customBgImageSrc = src;
            customBgImage = new Image();
            customBgImage.onload = function () { scheduleRender(); };
            customBgImage.onerror = function () {
                console.error('[ink-engine] failed to load custom background image');
            };
            customBgImage.src = src;
        }
        if (customBgImage && customBgImage.complete && customBgImage.naturalWidth > 0) {
            ctx.drawImage(customBgImage, 0, 0, CANVAS_W, CANVAS_H);
        }
    }

    function drawBackground(type) {
        ctx.save();
        switch (type) {
            case 'custom':
                drawCustomBackground();
                break;
            case 'lined':
                ctx.strokeStyle = '#c5d6f5';
                ctx.lineWidth = 2;
                var lineSpacing = 80;
                for (var y = lineSpacing; y < CANVAS_H; y += lineSpacing) {
                    ctx.beginPath();
                    ctx.moveTo(60, y);
                    ctx.lineTo(CANVAS_W - 60, y);
                    ctx.stroke();
                }
                break;
            case 'dot_grid':
                ctx.fillStyle = '#b8c1cc';
                var dotSpacing = 60;
                for (var dy = dotSpacing; dy < CANVAS_H; dy += dotSpacing) {
                    for (var dx = dotSpacing; dx < CANVAS_W; dx += dotSpacing) {
                        ctx.beginPath();
                        ctx.arc(dx, dy, 3, 0, Math.PI * 2);
                        ctx.fill();
                    }
                }
                break;
            case 'graph':
                // Warm-gray square grid, ~40px cell → 37 cols × 52 rows.
                // 3px line width at canvas scale renders ~0.8px at the
                // typical display scale so the grid reads as crisp and
                // consistent instead of faded lined paper.
                ctx.strokeStyle = '#d4c9bc';
                ctx.lineWidth = 3;
                var gridStep = 40;
                ctx.beginPath();
                for (var gx = gridStep; gx < CANVAS_W; gx += gridStep) {
                    ctx.moveTo(gx, 0);
                    ctx.lineTo(gx, CANVAS_H);
                }
                for (var gy = gridStep; gy < CANVAS_H; gy += gridStep) {
                    ctx.moveTo(0, gy);
                    ctx.lineTo(CANVAS_W, gy);
                }
                ctx.stroke();
                break;
            case 'blank':
            default:
                // white background already drawn
                break;
        }
        ctx.restore();
    }

    // ------------------------------------------------------------------
    // Toolbar
    // ------------------------------------------------------------------
    btnPen.addEventListener('click', function () { setTool('pen'); });
    btnEraser.addEventListener('click', function () { setTool('eraser'); });
    btnText.addEventListener('click', function () { setTool('text'); });
    colorInput.addEventListener('input', function () {
        state.color = colorInput.value;
        if (state.selectedTextId) {
            var tb = findTextBlock(state.selectedTextId);
            if (tb) {
                tb.color = state.color;
                applyTextBlockStyles(tb);
                state.dirty = true;
            }
        }
    });
    thicknessInput.addEventListener('input', function () {
        state.thickness = parseInt(thicknessInput.value, 10);
        thicknessValue.textContent = state.thickness;
    });
    btnUndo.addEventListener('click', undo);
    btnRedo.addEventListener('click', redo);

    fontSizeSelect.addEventListener('change', function () {
        // Dropdown values are real-world point sizes. Store the canvas-pixel
        // equivalent (point * 10) on the text block so layout maths stays
        // consistent with stored layers loaded from the server.
        var pointSize = parseInt(fontSizeSelect.value, 10);
        if (!state.selectedTextId || isNaN(pointSize)) return;
        var tb = findTextBlock(state.selectedTextId);
        if (!tb) return;
        tb.fontSize = pointSize * POINT_TO_PIXEL;
        layoutTextBlock(tb);
        state.dirty = true;
    });

    function setTool(tool) {
        state.tool = tool;
        btnPen.classList.toggle('active', tool === 'pen');
        btnEraser.classList.toggle('active', tool === 'eraser');
        btnText.classList.toggle('active', tool === 'text');
        textLayer.classList.toggle('text-mode', tool === 'text');
        if (tool !== 'text') {
            selectTextBlock(null);
        }
    }

    // Keyboard shortcuts
    document.addEventListener('keydown', function (e) {
        var mod = e.ctrlKey || e.metaKey;
        if (!mod) return;
        if (e.key === 'z' || e.key === 'Z') {
            if (e.shiftKey) { redo(); } else { undo(); }
            e.preventDefault();
        } else if (e.key === 'y' || e.key === 'Y') {
            redo();
            e.preventDefault();
        } else if (e.key === 's' || e.key === 'S') {
            save();
            e.preventDefault();
        }
    });

    // ------------------------------------------------------------------
    // Save
    // ------------------------------------------------------------------
    console.log('[ink-engine] init; saveBtn=', saveBtn, 'pageData=', pageData, 'CONTEXT_PATH=', CONTEXT_PATH);
    if (!saveBtn) {
        console.error('[ink-engine] #save-btn not found in DOM');
    } else {
        saveBtn.addEventListener('click', function (e) {
            console.log('[ink-engine] save button click event fired');
            save();
        });
    }
    function save() {
        console.log('Save clicked');
        if (!pageData || typeof pageData.id === 'undefined') {
            console.error('[ink-engine] cannot save: pageData.id is missing', pageData);
            saveStatus.textContent = 'Error';
            return;
        }
        saveStatus.textContent = 'Saving...';
        saveBtn.disabled = true;
        var body = {
            inkData: { strokes: state.strokes },
            textLayers: serializeTextLayers()
        };
        var url = CONTEXT_PATH + '/app/page/' + pageData.id;
        console.log('[ink-engine] PUT', url, 'body=', body);
        fetch(url, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'same-origin',
            body: JSON.stringify(body)
        }).then(function (resp) {
            console.log('[ink-engine] response status:', resp.status, resp.statusText);
            saveBtn.disabled = false;
            return resp.text().then(function (text) {
                console.log('[ink-engine] response body:', text);
                if (resp.ok) {
                    saveStatus.textContent = 'Saved';
                    state.dirty = false;
                    setTimeout(function () { saveStatus.textContent = ''; }, 2000);
                } else if (resp.status === 403) {
                    saveStatus.textContent = 'Locked';
                } else {
                    saveStatus.textContent = 'Error ' + resp.status;
                }
            });
        }).catch(function (err) {
            console.error('[ink-engine] save failed:', err);
            saveBtn.disabled = false;
            saveStatus.textContent = 'Network error';
        });
    }

    // ------------------------------------------------------------------
    // Text block subsystem
    // ------------------------------------------------------------------
    function genId() {
        if (window.crypto && typeof window.crypto.randomUUID === 'function') {
            return window.crypto.randomUUID();
        }
        return 'tb-' + Date.now() + '-' + Math.floor(Math.random() * 1e9).toString(16);
    }

    function normalizeTextBlock(raw) {
        if (!raw || typeof raw !== 'object') return null;
        return {
            id: raw.id || genId(),
            x: typeof raw.x === 'number' ? raw.x : 0,
            y: typeof raw.y === 'number' ? raw.y : 0,
            text: typeof raw.text === 'string' ? raw.text : '',
            fontSize: typeof raw.fontSize === 'number'
                    ? raw.fontSize
                    : DEFAULT_FONT_POINT * POINT_TO_PIXEL,
            color: typeof raw.color === 'string' ? raw.color : '#000000',
            width: typeof raw.width === 'number' ? raw.width : 300,
            height: typeof raw.height === 'number' ? raw.height : null,
            _el: null,
            _content: null
        };
    }

    function serializeTextLayers() {
        return state.textLayers.map(function (tb) {
            return {
                id: tb.id,
                x: tb.x,
                y: tb.y,
                text: tb.text,
                fontSize: tb.fontSize,
                color: tb.color,
                width: tb.width,
                height: tb.height
            };
        });
    }

    function findTextBlock(id) {
        for (var i = 0; i < state.textLayers.length; i++) {
            if (state.textLayers[i].id === id) return state.textLayers[i];
        }
        return null;
    }

    function getCanvasScale() {
        var rect = canvas.getBoundingClientRect();
        return rect.width === 0 ? 1 : rect.width / CANVAS_W;
    }

    function layoutTextBlocks() {
        var scale = getCanvasScale();
        for (var i = 0; i < state.textLayers.length; i++) {
            layoutTextBlock(state.textLayers[i], scale);
        }
    }

    function layoutTextBlock(tb, scale) {
        if (!tb._el) return;
        if (typeof scale !== 'number') scale = getCanvasScale();
        tb._el.style.left = (tb.x * scale) + 'px';
        tb._el.style.top = (tb.y * scale) + 'px';
        tb._el.style.width = (tb.width * scale) + 'px';
        if (typeof tb.height === 'number' && tb.height > 0) {
            tb._el.style.height = (tb.height * scale) + 'px';
            if (tb._content) {
                tb._content.style.height = '100%';
                tb._content.style.overflow = 'auto';
            }
        } else {
            tb._el.style.height = '';
            if (tb._content) {
                tb._content.style.height = '';
                tb._content.style.overflow = '';
            }
        }
        if (tb._content) {
            tb._content.style.fontSize = (tb.fontSize * scale) + 'px';
        }
    }

    function applyTextBlockStyles(tb) {
        if (!tb._content) return;
        tb._content.style.color = tb.color;
    }

    function createTextBlockDom(tb) {
        var el = document.createElement('div');
        el.className = 'text-block';
        el.dataset.id = tb.id;

        var handle = document.createElement('div');
        handle.className = 'tb-handle';
        handle.title = 'Drag to move';
        handle.innerHTML = '<i class="bi bi-arrows-move"></i>';

        var delBtn = document.createElement('button');
        delBtn.type = 'button';
        delBtn.className = 'tb-delete';
        delBtn.title = 'Delete';
        delBtn.innerHTML = '<i class="bi bi-x-lg"></i>';

        var resizeHandle = document.createElement('div');
        resizeHandle.className = 'tb-resize';
        resizeHandle.title = 'Resize';
        resizeHandle.innerHTML = '<i class="bi bi-arrows-angle-expand"></i>';

        var content = document.createElement('div');
        content.className = 'tb-content';
        content.contentEditable = 'true';
        content.spellcheck = false;
        content.textContent = tb.text;

        el.appendChild(handle);
        el.appendChild(delBtn);
        el.appendChild(resizeHandle);
        el.appendChild(content);

        tb._el = el;
        tb._content = content;

        applyTextBlockStyles(tb);
        layoutTextBlock(tb);

        // Select on click (in text mode); let the browser place caret naturally
        el.addEventListener('pointerdown', function (e) {
            if (state.tool !== 'text') return;
            e.stopPropagation();
            selectTextBlock(tb.id, false);
        });

        // Typing updates text model + dirty flag
        content.addEventListener('input', function () {
            tb.text = content.textContent || '';
            state.dirty = true;
        });

        // Delete key on empty block removes it
        content.addEventListener('keydown', function (e) {
            if ((e.key === 'Delete' || e.key === 'Backspace')
                    && (content.textContent || '') === '') {
                e.preventDefault();
                removeTextBlock(tb.id);
            }
        });

        // Explicit delete button
        delBtn.addEventListener('pointerdown', function (e) {
            e.stopPropagation();
            e.preventDefault();
            removeTextBlock(tb.id);
        });

        // Drag handle only
        attachDragHandler(tb, handle);
        // Resize handle
        attachResizeHandler(tb, resizeHandle);

        textLayer.appendChild(el);
    }

    function attachResizeHandler(tb, handleEl) {
        var resize = null;
        handleEl.addEventListener('pointerdown', function (e) {
            if (state.tool !== 'text') return;
            e.stopPropagation();
            e.preventDefault();
            selectTextBlock(tb.id, false);
            var scale = getCanvasScale();
            // Capture the current rendered height in canvas coords as a
            // starting point, so "auto" blocks get a concrete height on
            // the first drag.
            var currentHeight;
            if (typeof tb.height === 'number' && tb.height > 0) {
                currentHeight = tb.height;
            } else {
                var rect = tb._el.getBoundingClientRect();
                currentHeight = rect.height / scale;
            }
            resize = {
                pointerId: e.pointerId,
                startClientX: e.clientX,
                startClientY: e.clientY,
                startW: tb.width,
                startH: currentHeight,
                scale: scale
            };
            try { handleEl.setPointerCapture(e.pointerId); } catch (err) {}
        });
        handleEl.addEventListener('pointermove', function (e) {
            if (!resize || resize.pointerId !== e.pointerId) return;
            var dx = (e.clientX - resize.startClientX) / resize.scale;
            var dy = (e.clientY - resize.startClientY) / resize.scale;
            var newW = resize.startW + dx;
            var newH = resize.startH + dy;
            // Minimums in canvas coords
            if (newW < 40) newW = 40;
            if (newH < 24) newH = 24;
            // Clamp to canvas bounds so the block doesn't run off the page
            if (tb.x + newW > CANVAS_W) newW = CANVAS_W - tb.x;
            if (tb.y + newH > CANVAS_H) newH = CANVAS_H - tb.y;
            tb.width = newW;
            tb.height = newH;
            layoutTextBlock(tb, resize.scale);
            state.dirty = true;
        });
        function endResize(e) {
            if (!resize || resize.pointerId !== e.pointerId) return;
            try { handleEl.releasePointerCapture(e.pointerId); } catch (err) {}
            resize = null;
        }
        handleEl.addEventListener('pointerup', endResize);
        handleEl.addEventListener('pointercancel', endResize);
    }

    function attachDragHandler(tb, handleEl) {
        var drag = null;
        handleEl.addEventListener('pointerdown', function (e) {
            if (state.tool !== 'text') return;
            e.stopPropagation();
            e.preventDefault();
            selectTextBlock(tb.id, false);
            var scale = getCanvasScale();
            drag = {
                pointerId: e.pointerId,
                startClientX: e.clientX,
                startClientY: e.clientY,
                startX: tb.x,
                startY: tb.y,
                scale: scale
            };
            try { handleEl.setPointerCapture(e.pointerId); } catch (err) {}
        });
        handleEl.addEventListener('pointermove', function (e) {
            if (!drag || drag.pointerId !== e.pointerId) return;
            var dx = (e.clientX - drag.startClientX) / drag.scale;
            var dy = (e.clientY - drag.startClientY) / drag.scale;
            tb.x = Math.max(0, Math.min(CANVAS_W - 20, drag.startX + dx));
            tb.y = Math.max(0, Math.min(CANVAS_H - 20, drag.startY + dy));
            layoutTextBlock(tb, drag.scale);
            state.dirty = true;
        });
        function endDrag(e) {
            if (!drag || drag.pointerId !== e.pointerId) return;
            try { handleEl.releasePointerCapture(e.pointerId); } catch (err) {}
            drag = null;
        }
        handleEl.addEventListener('pointerup', endDrag);
        handleEl.addEventListener('pointercancel', endDrag);
    }

    function createTextBlockAt(x, y) {
        var tb = normalizeTextBlock({
            id: genId(),
            x: x,
            y: y,
            text: '',
            fontSize: DEFAULT_FONT_POINT * POINT_TO_PIXEL,
            color: state.color,
            width: 300
        });
        state.textLayers.push(tb);
        createTextBlockDom(tb);
        selectTextBlock(tb.id, true);
        state.dirty = true;
    }

    function selectTextBlock(id, autoFocusCaret) {
        if (state.selectedTextId && state.selectedTextId !== id) {
            var prev = findTextBlock(state.selectedTextId);
            if (prev && prev._el) {
                prev._el.classList.remove('selected');
                if (prev._content) {
                    prev._content.blur();
                }
            }
        }
        state.selectedTextId = id;
        if (!id) {
            fontSizeWrap.classList.remove('visible');
            return;
        }
        var tb = findTextBlock(id);
        if (!tb || !tb._el) {
            fontSizeWrap.classList.remove('visible');
            return;
        }
        tb._el.classList.add('selected');
        fontSizeWrap.classList.add('visible');
        syncFontSizeControl(tb.fontSize);
        if (autoFocusCaret && tb._content) {
            setTimeout(function () {
                tb._content.focus();
                placeCaretAtEnd(tb._content);
            }, 0);
        }
    }

    function syncFontSizeControl(canvasPixelSize) {
        // Incoming size is in canvas pixels (from tb.fontSize). The dropdown
        // options are real-world point sizes, so divide by POINT_TO_PIXEL
        // before looking for a match.
        var pointSize = Math.round(canvasPixelSize / POINT_TO_PIXEL);
        var str = String(pointSize);
        var found = false;
        for (var i = 0; i < fontSizeSelect.options.length; i++) {
            if (fontSizeSelect.options[i].value === str) {
                fontSizeSelect.selectedIndex = i;
                found = true;
                break;
            }
        }
        if (!found) {
            fontSizeSelect.value = String(DEFAULT_FONT_POINT);
        }
    }

    function placeCaretAtEnd(el) {
        try {
            var range = document.createRange();
            range.selectNodeContents(el);
            range.collapse(false);
            var sel = window.getSelection();
            sel.removeAllRanges();
            sel.addRange(range);
        } catch (err) {}
    }

    function removeTextBlock(id) {
        var idx = -1;
        for (var i = 0; i < state.textLayers.length; i++) {
            if (state.textLayers[i].id === id) { idx = i; break; }
        }
        if (idx < 0) return;
        var tb = state.textLayers[idx];
        if (tb._el && tb._el.parentNode) {
            tb._el.parentNode.removeChild(tb._el);
        }
        state.textLayers.splice(idx, 1);
        if (state.selectedTextId === id) {
            state.selectedTextId = null;
            fontSizeWrap.classList.remove('visible');
        }
        state.dirty = true;
    }

    // Click on empty area of the text layer (while in text mode) creates a block
    textLayer.addEventListener('pointerdown', function (e) {
        if (state.tool !== 'text') return;
        if (e.target !== textLayer) return; // clicks on existing blocks are handled there
        e.preventDefault();
        var rect = canvas.getBoundingClientRect();
        var x = (e.clientX - rect.left) * (CANVAS_W / rect.width);
        var y = (e.clientY - rect.top) * (CANVAS_H / rect.height);
        createTextBlockAt(x, y);
    });

    // ------------------------------------------------------------------
    // External API
    // Exposed so presentation-layer code (e.g. tablet-mode.js two-finger
    // swipe navigation) can abort an in-progress stroke without committing
    // it to the strokes array or triggering the dirty flag. The first
    // finger's pointerdown has already started a stroke by the time we
    // detect the second finger, so we need a way to undo that start cleanly.
    // ------------------------------------------------------------------
    window.inkEngine = {
        cancelStroke: function () {
            if (state.activePointerId !== null) {
                try { canvas.releasePointerCapture(state.activePointerId); }
                catch (err) { /* ignore */ }
            }
            state.activePointerId = null;
            state.currentStroke = null;
            scheduleRender();
        }
    };

    // Kick off first render now that everything is wired
    scheduleRender();
    updateHistoryButtons();
})();
