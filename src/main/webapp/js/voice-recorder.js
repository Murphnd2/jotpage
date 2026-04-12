/*
 * JotPage — voice entry client
 *
 * Handles:
 *   - Tab switching (record / upload)
 *   - Browser MediaRecorder + SpeechRecognition for live transcript
 *   - File drop / picker for upload mode with client-side validation
 *   - Mode card selection + custom prompt reveal
 *   - Inline tag selection + create
 *   - Multipart submit to /app/voice-record with progress overlay
 *
 * Upload-mode contract: when a file has been selected, clicking "Create
 * Pages" sends the file to the server even if the transcript textarea is
 * empty. The server runs Whisper and fills in the transcript.
 */
(function () {
    'use strict';

    var ctx = window.CONTEXT_PATH || '';
    var isPro = !!window.USER_IS_PRO;

    var MAX_FILE_BYTES = 25 * 1024 * 1024;
    var ACCEPTED_EXT = /\.(mp3|wav|webm|m4a|ogg|flac)$/i;

    // ------------------------------------------------------------------
    // DOM refs
    // ------------------------------------------------------------------
    var tabRecord = document.getElementById('tabRecord');
    var tabUpload = document.getElementById('tabUpload');
    var recordSection = document.getElementById('recordSection');
    var uploadSection = document.getElementById('uploadSection');

    var unsupportedMsg = document.getElementById('unsupportedMsg');
    var switchToUploadLink = document.getElementById('switchToUploadLink');
    var micBtn = document.getElementById('micBtn');
    var elapsedEl = document.getElementById('elapsed');
    var micHint = document.getElementById('micHint');
    var liveBox = document.getElementById('liveBox');

    var dropZone = document.getElementById('dropZone');
    var fileInput = document.getElementById('fileInput');
    var fileMeta = document.getElementById('fileMeta');
    var fileNameEl = document.getElementById('fileName');
    var fileSizeEl = document.getElementById('fileSize');

    var transcriptBox = document.getElementById('transcriptBox');
    var modeGrid = document.getElementById('modeGrid');
    var upgradeHint = document.getElementById('upgradeHint');
    var customPromptWrap = document.getElementById('customPromptWrap');
    var customPrompt = document.getElementById('customPrompt');
    var fontSizeSelect = document.getElementById('fontSize');
    var tagList = document.getElementById('tagList');
    var newTagForm = document.getElementById('newTagInline');
    var newTagName = document.getElementById('newTagName');
    var newTagColor = document.getElementById('newTagColor');

    var createBtn = document.getElementById('createBtn');
    var inlineError = document.getElementById('inlineError');

    var progressOverlay = document.getElementById('progressOverlay');
    var progressTitle = document.getElementById('progressTitle');
    var progressMsg = document.getElementById('progressMsg');

    // ------------------------------------------------------------------
    // State
    // ------------------------------------------------------------------
    var state = {
        activeTab: 'record',
        recording: false,
        mediaRecorder: null,
        mediaStream: null,
        chunks: [],
        audioBlob: null,
        selectedFile: null,
        recognition: null,
        recognitionFinal: '',
        recognitionInterim: '',
        elapsedStart: 0,
        elapsedTimer: null,
        selectedMode: 'verbatim',
        selectedTagIds: new Set(),
        submitting: false
    };

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------
    function escapeHtml(s) {
        return (s == null ? '' : String(s))
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
    }
    function showError(msg) {
        inlineError.textContent = msg;
        inlineError.classList.add('visible');
    }
    function clearError() {
        inlineError.textContent = '';
        inlineError.classList.remove('visible');
    }
    function pad(n) { return (n < 10 ? '0' : '') + n; }
    function formatBytes(b) {
        if (b < 1024) return b + ' B';
        if (b < 1024 * 1024) return (b / 1024).toFixed(0) + ' KB';
        return (b / (1024 * 1024)).toFixed(1) + ' MB';
    }

    // ------------------------------------------------------------------
    // Tab switching
    // ------------------------------------------------------------------
    function activateTab(tab) {
        state.activeTab = tab;
        tabRecord.classList.toggle('active', tab === 'record');
        tabUpload.classList.toggle('active', tab === 'upload');
        recordSection.classList.toggle('active', tab === 'record');
        uploadSection.classList.toggle('active', tab === 'upload');
        refreshCreateEnabled();
    }
    tabRecord.addEventListener('click', function () { activateTab('record'); });
    tabUpload.addEventListener('click', function () { activateTab('upload'); });
    if (switchToUploadLink) {
        switchToUploadLink.addEventListener('click', function (e) {
            e.preventDefault();
            activateTab('upload');
        });
    }

    // ------------------------------------------------------------------
    // Recording
    // ------------------------------------------------------------------
    var SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    var recordingSupported = !!(navigator.mediaDevices
        && navigator.mediaDevices.getUserMedia
        && window.MediaRecorder);

    if (!recordingSupported || !SpeechRecognition) {
        unsupportedMsg.style.display = 'block';
        micBtn.disabled = true;
        micBtn.style.opacity = '0.5';
        micBtn.style.cursor = 'not-allowed';
    }

    micBtn.addEventListener('click', function () {
        if (!recordingSupported || !SpeechRecognition) return;
        if (state.recording) {
            stopRecording();
        } else {
            startRecording();
        }
    });

    function startRecording() {
        clearError();
        navigator.mediaDevices.getUserMedia({ audio: true })
            .then(function (stream) {
                state.mediaStream = stream;
                state.chunks = [];
                var mimeType = '';
                if (MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
                    mimeType = 'audio/webm;codecs=opus';
                } else if (MediaRecorder.isTypeSupported('audio/webm')) {
                    mimeType = 'audio/webm';
                }
                try {
                    state.mediaRecorder = mimeType
                        ? new MediaRecorder(stream, { mimeType: mimeType })
                        : new MediaRecorder(stream);
                } catch (e) {
                    state.mediaRecorder = new MediaRecorder(stream);
                }
                state.mediaRecorder.addEventListener('dataavailable', function (ev) {
                    if (ev.data && ev.data.size > 0) state.chunks.push(ev.data);
                });
                state.mediaRecorder.addEventListener('stop', function () {
                    var blob = new Blob(state.chunks, {
                        type: state.mediaRecorder.mimeType || 'audio/webm'
                    });
                    state.audioBlob = blob;
                    state.chunks = [];
                    if (state.mediaStream) {
                        state.mediaStream.getTracks().forEach(function (t) { t.stop(); });
                        state.mediaStream = null;
                    }
                    refreshCreateEnabled();
                });
                state.mediaRecorder.start();

                // Speech recognition
                startRecognition();

                state.recording = true;
                micBtn.classList.add('recording');
                micBtn.innerHTML = '<i class="bi bi-stop-fill"></i>';
                micBtn.setAttribute('aria-label', 'Stop recording');
                micHint.textContent = 'Recording — tap to stop';

                state.elapsedStart = Date.now();
                updateElapsed();
                state.elapsedTimer = setInterval(updateElapsed, 250);
            })
            .catch(function (err) {
                console.error('[voice] mic permission failed', err);
                showError('Microphone access was denied. Check your browser permissions.');
            });
    }

    function stopRecording() {
        if (!state.recording) return;
        state.recording = false;
        try {
            if (state.mediaRecorder && state.mediaRecorder.state !== 'inactive') {
                state.mediaRecorder.stop();
            }
        } catch (e) { /* ignore */ }
        stopRecognition();

        micBtn.classList.remove('recording');
        micBtn.innerHTML = '<i class="bi bi-mic-fill"></i>';
        micBtn.setAttribute('aria-label', 'Start recording');
        micHint.textContent = 'Tap to record again';

        if (state.elapsedTimer) {
            clearInterval(state.elapsedTimer);
            state.elapsedTimer = null;
        }
    }

    function updateElapsed() {
        var ms = Date.now() - state.elapsedStart;
        var total = Math.floor(ms / 1000);
        var m = Math.floor(total / 60);
        var s = total % 60;
        elapsedEl.textContent = pad(m) + ':' + pad(s);
    }

    function startRecognition() {
        if (!SpeechRecognition) return;
        try {
            state.recognition = new SpeechRecognition();
            state.recognition.continuous = true;
            state.recognition.interimResults = true;
            state.recognition.lang = 'en-US';
            state.recognitionFinal = transcriptBox.value || '';
            state.recognitionInterim = '';
            state.recognition.addEventListener('result', function (ev) {
                var interim = '';
                for (var i = ev.resultIndex; i < ev.results.length; i++) {
                    var res = ev.results[i];
                    var txt = res[0] && res[0].transcript ? res[0].transcript : '';
                    if (res.isFinal) {
                        if (state.recognitionFinal && !/\s$/.test(state.recognitionFinal)) {
                            state.recognitionFinal += ' ';
                        }
                        state.recognitionFinal += txt.trim();
                    } else {
                        interim += txt;
                    }
                }
                state.recognitionInterim = interim;
                transcriptBox.value = state.recognitionFinal
                    + (interim ? ' ' + interim : '');
                paintLiveBox();
                refreshCreateEnabled();
            });
            state.recognition.addEventListener('error', function (ev) {
                console.warn('[voice] recognition error', ev.error);
            });
            state.recognition.addEventListener('end', function () {
                // If we're still recording, restart (Chrome stops after silence)
                if (state.recording && state.recognition) {
                    try { state.recognition.start(); } catch (e) { /* ignore */ }
                }
            });
            state.recognition.start();
        } catch (e) {
            console.warn('[voice] recognition start failed', e);
            state.recognition = null;
        }
    }

    function stopRecognition() {
        if (!state.recognition) return;
        try { state.recognition.stop(); } catch (e) { /* ignore */ }
        state.recognition = null;
        state.recognitionInterim = '';
        paintLiveBox();
    }

    function paintLiveBox() {
        var html = '';
        if (state.recognitionFinal) {
            html += '<span>' + escapeHtml(state.recognitionFinal) + '</span>';
        }
        if (state.recognitionInterim) {
            html += ' <span class="interim">' + escapeHtml(state.recognitionInterim) + '</span>';
        }
        if (!html) {
            html = '<span class="text-muted small fst-italic">Your words will appear here as you speak.</span>';
        }
        liveBox.innerHTML = html;
        liveBox.scrollTop = liveBox.scrollHeight;
    }

    // Keep the user-edited transcript in sync with our "final" buffer so new
    // speech appends after manual edits instead of overwriting them.
    transcriptBox.addEventListener('input', function () {
        state.recognitionFinal = transcriptBox.value || '';
        state.recognitionInterim = '';
        refreshCreateEnabled();
    });

    // ------------------------------------------------------------------
    // Upload handling
    // ------------------------------------------------------------------
    function handleFile(file) {
        clearError();
        if (!file) return;
        if (!ACCEPTED_EXT.test(file.name) && !/^audio\//.test(file.type || '')) {
            showError('That doesn\u2019t look like an audio file. Try MP3, WAV, WebM, M4A, OGG, or FLAC.');
            return;
        }
        if (file.size > MAX_FILE_BYTES) {
            showError('File is ' + formatBytes(file.size) + '. Max is 25 MB.');
            return;
        }
        state.selectedFile = file;
        fileNameEl.textContent = file.name;
        fileSizeEl.textContent = formatBytes(file.size);
        fileMeta.classList.add('visible');
        // Auto-jump to the upload tab so the UI reflects what will actually
        // be submitted. Prevents a stale "record" tab from confusing anyone.
        if (state.activeTab !== 'upload') {
            activateTab('upload');
        }
        refreshCreateEnabled();
    }

    fileInput.addEventListener('change', function () {
        if (fileInput.files && fileInput.files[0]) handleFile(fileInput.files[0]);
    });

    ['dragenter', 'dragover'].forEach(function (evt) {
        dropZone.addEventListener(evt, function (e) {
            e.preventDefault();
            dropZone.classList.add('dragover');
        });
    });
    ['dragleave', 'drop'].forEach(function (evt) {
        dropZone.addEventListener(evt, function (e) {
            e.preventDefault();
            dropZone.classList.remove('dragover');
        });
    });
    dropZone.addEventListener('drop', function (e) {
        var dt = e.dataTransfer;
        if (dt && dt.files && dt.files[0]) handleFile(dt.files[0]);
    });

    // ------------------------------------------------------------------
    // Mode cards
    // ------------------------------------------------------------------
    modeGrid.addEventListener('click', function (e) {
        var card = e.target.closest('.mode-card');
        if (!card) return;
        selectMode(card.getAttribute('data-mode'));
    });

    function selectMode(mode) {
        state.selectedMode = mode;
        Array.prototype.forEach.call(modeGrid.querySelectorAll('.mode-card'), function (c) {
            c.classList.toggle('selected', c.getAttribute('data-mode') === mode);
        });
        customPromptWrap.classList.toggle('visible', mode === 'custom');

        var isProOnly = mode !== 'verbatim';
        if (isProOnly && !isPro) {
            upgradeHint.classList.add('visible');
        } else {
            upgradeHint.classList.remove('visible');
        }
        clearError();
        refreshCreateEnabled();
    }

    // ------------------------------------------------------------------
    // Tag picker
    // ------------------------------------------------------------------
    tagList.addEventListener('click', function (e) {
        var chip = e.target.closest('.tag-choice');
        if (!chip) return;
        var id = chip.getAttribute('data-tag-id');
        if (!id) return;
        if (state.selectedTagIds.has(id)) {
            state.selectedTagIds.delete(id);
            chip.classList.remove('selected');
        } else {
            state.selectedTagIds.add(id);
            chip.classList.add('selected');
        }
    });

    newTagForm.addEventListener('submit', function (e) {
        e.preventDefault();
        var name = (newTagName.value || '').trim();
        if (!name) return;
        var color = newTagColor.value || '#8b6e4e';
        fetch(ctx + '/app/api/tags', {
            method: 'POST',
            credentials: 'same-origin',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: name, color: color })
        }).then(function (r) {
            if (!r.ok) throw new Error('tag create failed');
            return r.json();
        }).then(function (tag) {
            var emptyMsg = tagList.querySelector('.text-muted');
            if (emptyMsg) emptyMsg.remove();
            var chip = document.createElement('span');
            chip.className = 'tag-choice selected';
            chip.setAttribute('data-tag-id', String(tag.id));
            chip.innerHTML = '<span class="swatch" style="background:' + escapeHtml(tag.color) + '"></span>'
                + escapeHtml(tag.name);
            tagList.appendChild(chip);
            state.selectedTagIds.add(String(tag.id));
            newTagName.value = '';
        }).catch(function (err) {
            console.error(err);
            showError('Could not create tag.');
        });
    });

    // ------------------------------------------------------------------
    // Create button / submission
    // ------------------------------------------------------------------
    function hasAudio() {
        return !!(state.audioBlob || state.selectedFile);
    }
    function hasContent() {
        var hasTranscript = (transcriptBox.value || '').trim().length > 0;
        return hasTranscript || hasAudio();
    }
    function refreshCreateEnabled() {
        createBtn.disabled = state.submitting || !hasContent();
    }

    createBtn.addEventListener('click', function () {
        if (state.submitting) return;
        clearError();

        var transcript = (transcriptBox.value || '').trim();
        var audioPresent = hasAudio();

        // The server will run Whisper on uploaded/recorded audio, so we
        // only block submission when there's literally nothing to send.
        if (!transcript && !audioPresent) {
            showError('Record or upload some audio first.');
            return;
        }

        if (state.selectedMode !== 'verbatim' && !isPro) {
            showError('That processing mode is part of JotPage Pro. Switch to Verbatim to continue on the free tier.');
            return;
        }
        if (state.selectedMode === 'custom' && !(customPrompt.value || '').trim()) {
            showError('Add a custom instruction or choose a different mode.');
            return;
        }

        submit(transcript);
    });

    function submit(transcript) {
        state.submitting = true;
        createBtn.disabled = true;
        showProgress('Uploading audio…', 'Preparing your entry');

        var fd = new FormData();
        // Prefer an explicitly uploaded file; fall back to a just-recorded
        // blob. This is independent of which tab is active so a stale
        // activeTab value can't drop the audio on the floor.
        if (state.selectedFile) {
            fd.append('audioFile', state.selectedFile, state.selectedFile.name);
            console.log('[voice] submitting upload file',
                state.selectedFile.name, state.selectedFile.size, 'bytes');
        } else if (state.audioBlob) {
            fd.append('audioFile', state.audioBlob, 'recording.webm');
            console.log('[voice] submitting recorded blob',
                state.audioBlob.size, 'bytes');
        } else {
            console.log('[voice] submitting transcript-only, no audio');
        }
        fd.append('browserTranscript', transcript);
        fd.append('fontSize', fontSizeSelect.value || '16');
        fd.append('jobType', state.selectedMode);
        fd.append('customPrompt', customPrompt.value || '');
        fd.append('tagIds', Array.from(state.selectedTagIds).join(','));

        // Simulated status ticker so the user sees progress text while the
        // server works. The actual pipeline stages happen server-side.
        var stages = [
            { title: 'Uploading audio…', msg: 'Sending your recording to the server' },
            { title: 'Transcribing…',    msg: 'Turning speech into text' },
            { title: 'Processing with AI…', msg: 'Shaping your transcript' },
            { title: 'Creating pages…',  msg: 'Laying out your notebook entries' }
        ];
        var stageIdx = 0;
        var stageTimer = setInterval(function () {
            stageIdx++;
            if (stageIdx >= stages.length) { clearInterval(stageTimer); return; }
            updateProgress(stages[stageIdx].title, stages[stageIdx].msg);
        }, 1800);

        fetch(ctx + '/app/voice-record', {
            method: 'POST',
            credentials: 'same-origin',
            body: fd
        }).then(function (r) {
            return r.json().then(function (body) { return { r: r, body: body }; });
        }).then(function (res) {
            clearInterval(stageTimer);
            if (res.r.ok && res.body && res.body.success) {
                updateProgress('Done', 'Created ' + res.body.pagesCreated + ' page'
                    + (res.body.pagesCreated === 1 ? '' : 's') + '. Redirecting…');
                setTimeout(function () {
                    window.location.href = res.body.redirectUrl
                        || (ctx + '/app/dashboard');
                }, 700);
            } else {
                hideProgress();
                state.submitting = false;
                refreshCreateEnabled();
                var msg = (res.body && res.body.error)
                    ? res.body.error
                    : ('Server returned ' + res.r.status);
                showError(msg);
            }
        }).catch(function (err) {
            clearInterval(stageTimer);
            hideProgress();
            state.submitting = false;
            refreshCreateEnabled();
            console.error('[voice] submit failed', err);
            showError('Network error: ' + (err.message || err));
        });
    }

    function showProgress(title, msg) {
        updateProgress(title, msg);
        progressOverlay.classList.add('visible');
    }
    function hideProgress() {
        progressOverlay.classList.remove('visible');
    }
    function updateProgress(title, msg) {
        progressTitle.textContent = title;
        progressMsg.textContent = msg;
    }

    // ------------------------------------------------------------------
    // Init
    // ------------------------------------------------------------------
    selectMode('verbatim');
    refreshCreateEnabled();
})();
