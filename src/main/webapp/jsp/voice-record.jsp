<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jyrnyl &mdash; Voice Booth</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/theme.css" rel="stylesheet">
    <%@ include file="/WEB-INF/jspf/pwa-head.jspf" %>
    <style>
        body {
            background:
                radial-gradient(circle at 15% 10%, rgba(212,148,58,0.06), transparent 40%),
                radial-gradient(circle at 90% 90%, rgba(160,82,45,0.04), transparent 45%),
                var(--bg-cream);
            min-height: 100vh;
        }
        .voice-main {
            max-width: 760px;
            margin: 0 auto;
            padding: 20px 20px 48px;
        }
        .voice-header h1 {
            font-family: var(--font-serif);
            font-weight: 700;
            font-size: 1.6rem;
            color: var(--accent-brown);
            margin: 0;
        }
        .voice-header .subhead {
            font-family: var(--font-serif);
            font-style: italic;
            color: var(--text-muted);
            margin-top: 2px;
            font-size: 0.9rem;
        }

        .voice-card {
            background: var(--bg-card);
            border: 1px solid var(--border-warm);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-paper);
            padding: 20px 22px;
            margin-top: 14px;
        }

        /* Tabs */
        .mode-tabs {
            display: inline-flex;
            background: var(--bg-cream-dark);
            border: 1px solid var(--border-warm-strong);
            border-radius: 999px;
            padding: 4px;
            gap: 4px;
        }
        .mode-tab {
            min-height: 38px;
            padding: 0 18px;
            border-radius: 999px;
            border: 0;
            background: transparent;
            color: var(--text-muted);
            font-family: var(--font-body);
            font-size: 0.9rem;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            transition: background 0.15s ease, color 0.15s ease;
        }
        .mode-tab.active {
            background: var(--accent-brown);
            color: #fff;
        }
        .mode-tab i { font-size: 1rem; }

        /* Record section */
        .record-section { display: none; margin-top: 16px; }
        .record-section.active { display: block; }
        .upload-section { display: none; margin-top: 16px; }
        .upload-section.active { display: block; }

        .mic-wrap {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 10px;
            padding: 14px 0 10px;
        }
        .mic-btn {
            width: 72px;
            height: 72px;
            border-radius: 50%;
            background: var(--accent-brown);
            border: 3px solid var(--accent-brown-dark);
            color: #fff;
            font-size: 1.7rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            box-shadow:
                0 2px 8px rgba(74,55,40,0.22),
                0 10px 24px rgba(74,55,40,0.14);
            transition: background 0.15s ease, transform 0.08s ease;
        }
        .mic-btn:hover { background: var(--accent-brown-dark); }
        .mic-btn.recording {
            background: var(--accent-burgundy);
            border-color: var(--accent-burgundy-dark);
            animation: recPulse 1.4s ease-in-out infinite;
        }
        @keyframes recPulse {
            0%, 100% { box-shadow: 0 0 0 0 rgba(160,82,45,0.55); }
            50% { box-shadow: 0 0 0 18px rgba(160,82,45,0); }
        }
        .elapsed {
            font-family: var(--font-serif);
            font-size: 1.3rem;
            color: var(--accent-brown);
            font-variant-numeric: tabular-nums;
            letter-spacing: 0.04em;
        }
        .mic-hint {
            font-family: var(--font-serif);
            font-style: italic;
            color: var(--text-muted);
            font-size: 0.9rem;
            text-align: center;
        }

        .live-box {
            border: 1px solid var(--border-warm);
            border-radius: var(--radius-md);
            background: #fffdf7;
            padding: 14px 16px;
            max-height: 180px;
            overflow-y: auto;
            font-size: 0.95rem;
            line-height: 1.5;
            color: var(--text-dark);
        }
        .live-box .interim {
            color: var(--text-muted);
            font-style: italic;
        }
        .unsupported-warn {
            color: var(--accent-burgundy-dark);
            background: rgba(160,82,45,0.08);
            border: 1px solid rgba(160,82,45,0.22);
            border-radius: var(--radius-md);
            padding: 10px 14px;
            font-size: 0.9rem;
        }

        /* Upload drop zone */
        .drop-zone {
            position: relative;
            border: 2px dashed var(--border-warm-strong);
            border-radius: var(--radius-lg);
            padding: 40px 20px;
            text-align: center;
            background: rgba(201, 168, 76, 0.06);
            cursor: pointer;
            transition: background 0.15s ease, border-color 0.15s ease;
        }
        .drop-zone:hover,
        .drop-zone.dragover {
            background: rgba(201, 168, 76, 0.14);
            border-color: var(--accent-gold);
        }
        .drop-zone input[type="file"] {
            position: absolute;
            inset: 0;
            opacity: 0;
            cursor: pointer;
        }
        .drop-zone .dz-icon {
            font-size: 2.2rem;
            color: var(--accent-brown);
            margin-bottom: 8px;
        }
        .drop-zone .dz-primary {
            font-family: var(--font-serif);
            font-size: 1.05rem;
            color: var(--accent-brown);
            margin-bottom: 4px;
        }
        .drop-zone .dz-secondary {
            color: var(--text-muted);
            font-size: 0.85rem;
            font-style: italic;
        }
        .file-meta {
            margin-top: 14px;
            background: var(--bg-card);
            border: 1px solid var(--border-warm);
            border-radius: var(--radius-md);
            padding: 10px 14px;
            display: none;
            justify-content: space-between;
            align-items: center;
            font-size: 0.9rem;
            color: var(--text-dark);
        }
        .file-meta.visible { display: flex; }
        .file-meta .fm-size {
            color: var(--text-muted);
            font-style: italic;
            font-size: 0.85rem;
        }
        .upload-note {
            margin-top: 12px;
            font-family: var(--font-serif);
            font-style: italic;
            color: var(--text-muted);
            font-size: 0.85rem;
            text-align: center;
        }

        /* Transcript area */
        .section-label {
            font-family: var(--font-serif);
            font-weight: 600;
            color: var(--accent-brown);
            font-size: 1rem;
            margin-bottom: 8px;
            display: block;
        }
        .transcript-wrap {
            margin-top: 18px;
        }
        .transcript-box {
            width: 100%;
            min-height: 110px;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-md);
            padding: 12px 14px;
            font-family: var(--font-body);
            font-size: 0.9rem;
            line-height: 1.5;
            color: var(--text-dark);
            background: #fffdf7;
            resize: vertical;
        }
        .transcript-box:focus {
            outline: none;
            border-color: var(--accent-brown);
            box-shadow: 0 0 0 0.12rem rgba(74,55,40,0.12);
        }

        /* Mode cards */
        .mode-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 8px;
            margin-top: 8px;
        }
        .mode-card {
            position: relative;
            background: var(--bg-card);
            border: 1.5px solid var(--border-warm);
            border-radius: var(--radius-md);
            padding: 10px 12px;
            cursor: pointer;
            display: flex;
            gap: 10px;
            align-items: flex-start;
            transition: border-color 0.15s ease, background 0.15s ease;
        }
        .mode-card:hover {
            border-color: var(--border-warm-strong);
            background: var(--bg-cream-dark);
        }
        .mode-card.selected {
            border-color: var(--accent-brown);
            background: rgba(74, 55, 40, 0.06);
        }
        .mode-card .mc-icon {
            flex: 0 0 auto;
            width: 32px;
            height: 32px;
            border-radius: 8px;
            background: rgba(74, 55, 40, 0.08);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--accent-brown);
            font-size: 1rem;
        }
        .mode-card.selected .mc-icon {
            background: var(--accent-brown);
            color: #fff;
        }
        .mode-card .mc-body { flex: 1 1 auto; min-width: 0; }
        .mode-card .mc-title {
            font-family: var(--font-serif);
            font-weight: 600;
            color: var(--accent-brown);
            font-size: 0.9rem;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .mode-card .mc-desc {
            font-size: 0.75rem;
            color: var(--text-muted);
            margin-top: 2px;
            font-style: italic;
        }
        .mode-card .pro-badge {
            background: var(--accent-gold);
            color: var(--accent-brown-dark);
            border-radius: 999px;
            font-size: 0.62rem;
            padding: 1px 7px;
            font-weight: 600;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            font-family: var(--font-body);
            font-style: normal;
        }
        .mode-card .lock-icon {
            color: var(--text-light);
            font-size: 0.85rem;
        }
        body.tier-free .mode-card.pro-only .mc-title::after {
            content: "";
        }
        .upgrade-hint {
            display: none;
            background: rgba(201, 168, 76, 0.12);
            border: 1px solid rgba(201, 168, 76, 0.35);
            color: var(--accent-brown-dark);
            border-radius: var(--radius-md);
            padding: 8px 12px;
            font-size: 0.88rem;
            margin-top: 8px;
        }
        .upgrade-hint.visible { display: block; }
        .custom-prompt-wrap {
            display: none;
            margin-top: 10px;
        }
        .custom-prompt-wrap.visible { display: block; }

        /* Form row */
        .form-row {
            margin-top: 16px;
            display: flex;
            gap: 18px;
            flex-wrap: wrap;
        }
        .form-row > div { flex: 1 1 220px; min-width: 180px; }
        .form-row select {
            width: 100%;
            min-height: 42px;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-md);
            padding: 0 12px;
            background: var(--bg-card);
            color: var(--text-dark);
            font-family: var(--font-body);
        }

        /* Tag chips */
        .tag-list {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-top: 6px;
        }
        .tag-choice {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 12px;
            border-radius: 999px;
            font-size: 0.85rem;
            background: rgba(212,148,58,0.08);
            color: var(--text-dark);
            border: 1.5px solid var(--border-warm-strong);
            cursor: pointer;
            user-select: none;
            transition: background 0.15s ease, border-color 0.15s ease, color 0.15s ease;
        }
        .tag-choice:hover {
            background: rgba(212,148,58,0.16);
        }
        .tag-choice.selected {
            background: var(--accent-brown);
            color: #fff;
            border-color: var(--accent-brown);
        }
        .tag-choice .swatch {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            flex: 0 0 auto;
        }
        .new-tag-inline {
            display: flex;
            gap: 8px;
            margin-top: 10px;
            align-items: center;
        }
        .new-tag-inline input[type="text"] {
            flex: 1 1 auto;
            min-width: 0;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-sm);
            padding: 6px 10px;
            font-size: 0.9rem;
            background: var(--bg-card);
        }
        .new-tag-inline input[type="text"]:focus {
            outline: none;
            border-color: var(--accent-brown);
        }
        .new-tag-inline input[type="color"] {
            width: 36px;
            height: 36px;
            padding: 2px;
            border: 1px solid var(--border-warm-strong);
            border-radius: var(--radius-sm);
            background: var(--bg-card);
        }

        /* Action buttons */
        .action-row {
            margin-top: 28px;
            display: flex;
            gap: 10px;
            align-items: center;
            justify-content: flex-end;
            flex-wrap: wrap;
        }
        .action-row .create-btn {
            min-height: 50px;
            padding: 0 28px;
            font-size: 1rem;
        }
        .action-row .create-btn:disabled { opacity: 0.45; cursor: not-allowed; }

        .inline-error {
            color: var(--accent-burgundy-dark);
            font-size: 0.9rem;
            margin-top: 6px;
            display: none;
        }
        .inline-error.visible { display: block; }

        /* Progress overlay */
        .progress-overlay {
            position: fixed;
            inset: 0;
            background: rgba(61, 42, 34, 0.55);
            backdrop-filter: blur(4px);
            -webkit-backdrop-filter: blur(4px);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 2000;
        }
        .progress-overlay.visible { display: flex; }
        .progress-card {
            background: var(--bg-card);
            border: 1px solid var(--border-warm);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-paper);
            padding: 36px 42px;
            min-width: 300px;
            text-align: center;
        }
        .progress-card .spinner {
            width: 48px;
            height: 48px;
            border: 4px solid rgba(74,55,40,0.15);
            border-top-color: var(--accent-brown);
            border-radius: 50%;
            margin: 0 auto 18px;
            animation: spin 1s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        .progress-card .p-title {
            font-family: var(--font-serif);
            font-weight: 600;
            color: var(--accent-brown);
            font-size: 1.15rem;
            margin-bottom: 4px;
        }
        .progress-card .p-msg {
            font-family: var(--font-serif);
            font-style: italic;
            color: var(--text-muted);
            font-size: 0.9rem;
        }
    </style>
</head>
<body class="${isPro ? 'tier-pro' : 'tier-free'}">
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <div class="container">
            <a class="navbar-brand" href="${pageContext.request.contextPath}/app/dashboard">Jyrnyl</a>
            <div class="d-flex align-items-center ms-auto">
                <span class="me-3 text-muted small">
                    <c:choose>
                        <c:when test="${isPro}"><i class="bi bi-star-fill"></i> Pro</c:when>
                        <c:otherwise>Free tier</c:otherwise>
                    </c:choose>
                </span>
                <a class="btn btn-outline-secondary btn-sm"
                   href="${pageContext.request.contextPath}/app/dashboard">
                    <i class="bi bi-arrow-left"></i> Back
                </a>
            </div>
        </div>
    </nav>

    <main class="voice-main">
        <div class="voice-header">
            <h1>Voice Booth</h1>
            <div class="subhead">Speak or upload — we'll press it to vinyl.</div>
        </div>

        <div class="voice-card">
            <div class="mode-tabs" role="tablist">
                <button type="button" class="mode-tab active" id="tabRecord" data-tab="record">
                    <i class="bi bi-mic-fill"></i> Record
                </button>
                <button type="button" class="mode-tab" id="tabUpload" data-tab="upload">
                    <i class="bi bi-upload"></i> Upload
                </button>
            </div>

            <!-- RECORD TAB -->
            <section class="record-section active" id="recordSection">
                <div id="unsupportedMsg" class="unsupported-warn" style="display:none;">
                    Recording isn't supported in this browser. Try Chrome or Edge,
                    or use the <a href="#" id="switchToUploadLink">Upload tab</a>.
                </div>
                <div class="mic-wrap">
                    <button type="button" id="micBtn" class="mic-btn" aria-label="Start recording">
                        <i class="bi bi-mic-fill"></i>
                    </button>
                    <div class="elapsed" id="elapsed">00:00</div>
                    <div class="mic-hint" id="micHint">Tap to start speaking</div>
                </div>
                <div>
                    <label class="section-label">Live transcript</label>
                    <div class="live-box" id="liveBox">
                        <span class="text-muted small fst-italic">Your words will appear here as you speak.</span>
                    </div>
                </div>
            </section>

            <!-- UPLOAD TAB -->
            <section class="upload-section" id="uploadSection">
                <div class="drop-zone" id="dropZone">
                    <div class="dz-icon"><i class="bi bi-cloud-arrow-up"></i></div>
                    <div class="dz-primary">Drop audio file here or click to browse</div>
                    <div class="dz-secondary">MP3, WAV, WebM, M4A, OGG, FLAC &middot; max 25&nbsp;MB</div>
                    <input type="file" id="fileInput"
                           accept=".mp3,.wav,.webm,.m4a,.ogg,.flac,audio/mpeg,audio/wav,audio/webm,audio/mp4,audio/ogg,audio/flac">
                </div>
                <div class="file-meta" id="fileMeta">
                    <span>
                        <i class="bi bi-file-earmark-music"></i>
                        <span id="fileName"></span>
                    </span>
                    <span class="fm-size" id="fileSize"></span>
                </div>
                <div class="upload-note">Audio will be transcribed after submission.</div>
            </section>

            <!-- SHARED SECTION -->
            <div class="transcript-wrap">
                <label class="section-label" for="transcriptBox">Transcript</label>
                <textarea id="transcriptBox" class="transcript-box"
                          placeholder="Your transcript will appear here. You can edit before creating pages."></textarea>
            </div>

            <div style="margin-top: 18px;">
                <label class="section-label">Processing Mode</label>
                <div class="mode-grid" id="modeGrid">
                    <div class="mode-card selected" data-mode="verbatim">
                        <div class="mc-icon"><i class="bi bi-file-earmark-text"></i></div>
                        <div class="mc-body">
                            <div class="mc-title">Verbatim</div>
                            <div class="mc-desc">Straight transcription split across pages</div>
                        </div>
                    </div>
                    <div class="mode-card pro-only" data-mode="study_notes">
                        <div class="mc-icon"><i class="bi bi-mortarboard-fill"></i></div>
                        <div class="mc-body">
                            <div class="mc-title">
                                Study Notes
                                <span class="pro-badge">Pro</span>
                                <c:if test="${!isPro}">
                                    <i class="bi bi-lock-fill lock-icon" title="Upgrade to Pro"></i>
                                </c:if>
                            </div>
                            <div class="mc-desc">Organized notes with headers and key concepts</div>
                        </div>
                    </div>
                    <div class="mode-card pro-only" data-mode="meeting_minutes">
                        <div class="mc-icon"><i class="bi bi-people-fill"></i></div>
                        <div class="mc-body">
                            <div class="mc-title">
                                Meeting Minutes
                                <span class="pro-badge">Pro</span>
                                <c:if test="${!isPro}">
                                    <i class="bi bi-lock-fill lock-icon"></i>
                                </c:if>
                            </div>
                            <div class="mc-desc">Action items, decisions, and next steps</div>
                        </div>
                    </div>
                    <div class="mode-card pro-only" data-mode="journal_entry">
                        <div class="mc-icon"><i class="bi bi-pen-fill"></i></div>
                        <div class="mc-body">
                            <div class="mc-title">
                                Journal Entry
                                <span class="pro-badge">Pro</span>
                                <c:if test="${!isPro}">
                                    <i class="bi bi-lock-fill lock-icon"></i>
                                </c:if>
                            </div>
                            <div class="mc-desc">Reflective first-person journal writing</div>
                        </div>
                    </div>
                    <div class="mode-card pro-only" data-mode="outline">
                        <div class="mc-icon"><i class="bi bi-list-ul"></i></div>
                        <div class="mc-body">
                            <div class="mc-title">
                                Outline
                                <span class="pro-badge">Pro</span>
                                <c:if test="${!isPro}">
                                    <i class="bi bi-lock-fill lock-icon"></i>
                                </c:if>
                            </div>
                            <div class="mc-desc">Structured topic outline</div>
                        </div>
                    </div>
                    <div class="mode-card pro-only" data-mode="custom">
                        <div class="mc-icon"><i class="bi bi-magic"></i></div>
                        <div class="mc-body">
                            <div class="mc-title">
                                Custom
                                <span class="pro-badge">Pro</span>
                                <c:if test="${!isPro}">
                                    <i class="bi bi-lock-fill lock-icon"></i>
                                </c:if>
                            </div>
                            <div class="mc-desc">Your own processing instructions</div>
                        </div>
                    </div>
                </div>

                <div class="upgrade-hint" id="upgradeHint">
                    <i class="bi bi-star-fill"></i>
                    This feature requires Jyrnyl Pro. Upgrade coming soon!
                </div>

                <div class="custom-prompt-wrap" id="customPromptWrap">
                    <label class="section-label" for="customPrompt">Custom instructions</label>
                    <textarea id="customPrompt" class="transcript-box" rows="3"
                              placeholder="e.g. Summarize as a list of open questions and unresolved issues"></textarea>
                </div>
            </div>

            <div class="form-row">
                <div>
                    <label class="section-label" for="fontSize">Font size</label>
                    <select id="fontSize">
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
                </div>
                <div>
                    <label class="section-label">Tags</label>
                    <div class="tag-list" id="tagList">
                        <c:choose>
                            <c:when test="${empty tags}">
                                <span class="text-muted small fst-italic">No tags yet. Create one below.</span>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="t" items="${tags}">
                                    <span class="tag-choice" data-tag-id="${t.id}">
                                        <span class="swatch" style="background: <c:out value='${t.color}'/>"></span>
                                        <c:out value="${t.name}"/>
                                    </span>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </div>
                    <form class="new-tag-inline" id="newTagInline">
                        <input type="text" id="newTagName" placeholder="New tag name" maxlength="100">
                        <input type="color" id="newTagColor" value="#8b6e4e">
                        <button type="submit" class="btn btn-outline-secondary btn-sm">Add</button>
                    </form>
                </div>
            </div>

            <div class="inline-error" id="inlineError"></div>

            <div class="action-row">
                <a href="${pageContext.request.contextPath}/app/dashboard"
                   class="btn btn-outline-secondary">Cancel</a>
                <button type="button" id="createBtn" class="btn btn-primary create-btn" disabled>
                    <i class="bi bi-journal-plus"></i> Create Pages
                </button>
            </div>
        </div>
    </main>

    <div class="progress-overlay" id="progressOverlay">
        <div class="progress-card">
            <div class="spinner"></div>
            <div class="p-title" id="progressTitle">Working on it</div>
            <div class="p-msg" id="progressMsg">Preparing your entry…</div>
        </div>
    </div>

    <script>
        window.CONTEXT_PATH = '${pageContext.request.contextPath}';
        window.USER_IS_PRO = ${isPro};
        window.TRIAL_USAGE = ${empty trialUsageJson ? '{}' : trialUsageJson};
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="${pageContext.request.contextPath}/js/voice-recorder.js"></script>
    <script>
        // Update AI mode cards with trial usage status for free users
        (function () {
            if (window.USER_IS_PRO) return;
            var usage = window.TRIAL_USAGE || {};
            document.querySelectorAll('.mode-card.pro-only').forEach(function (card) {
                var mode = card.getAttribute('data-mode');
                var lockIcon = card.querySelector('.lock-icon');
                if (!lockIcon) return;
                var used = (usage[mode] || 0) >= 1;
                if (used) {
                    lockIcon.className = 'bi bi-lock-fill lock-icon';
                    lockIcon.title = 'Trial used \u2014 upgrade to Pro';
                } else {
                    lockIcon.className = 'bi bi-unlock-fill lock-icon';
                    lockIcon.title = 'Try free (1 use)';
                    lockIcon.style.color = 'var(--accent-gold)';
                }
            });
        })();
    </script>
    <%@ include file="/WEB-INF/jspf/pwa-register.jspf" %>
</body>
</html>
