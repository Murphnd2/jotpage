package com.jotpage.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Runs the Whisper CLI as a subprocess and returns the transcript text.
 *
 * Config comes from web.xml context params (wired by the servlet layer):
 *   whisper.command   (default: "whisper")
 *   whisper.model     (default: "base")
 *   ffmpeg.path       (optional: directory containing ffmpeg.exe / ffmpeg)
 *
 * Why ffmpegPath matters: Whisper's Python CLI shells out to `ffmpeg` via
 * Python's subprocess.run to decode audio. If ffmpeg isn't on the PATH that
 * Tomcat inherits, you get "FileNotFoundError: [WinError 2]" deep inside
 * Whisper's audio.py. Rather than forcing users to fight Windows system
 * environment variables and restart IntelliJ, we let them point at FFmpeg's
 * install directory in web.xml and prepend it to the child process PATH
 * right before launch. Leave ffmpegPath empty on Linux/macOS where ffmpeg
 * is typically already on a well-known PATH.
 *
 * Usage:
 *   WhisperService ws = new WhisperService(command, model, ffmpegPath);
 *   String text = ws.transcribe(new File("/tmp/note.mp3"));
 */
public class WhisperService {

    private static final long PROCESS_TIMEOUT_MINUTES = 5;

    private final String command;
    private final String model;
    private final String ffmpegPath;

    public WhisperService(String command, String model, String ffmpegPath) {
        this.command = (command == null || command.isEmpty()) ? "whisper" : command;
        this.model = (model == null || model.isEmpty()) ? "base" : model;
        this.ffmpegPath = (ffmpegPath == null) ? "" : ffmpegPath.trim();
    }

    /** Back-compat constructor for callers that don't need to configure ffmpegPath. */
    public WhisperService(String command, String model) {
        this(command, model, null);
    }

    public String transcribe(File audioFile) {
        if (audioFile == null || !audioFile.exists()) {
            throw new RuntimeException("Whisper: audio file not found: " + audioFile);
        }

        Path tempDir;
        try {
            tempDir = Files.createTempDirectory("jotpage-whisper-");
        } catch (IOException e) {
            throw new RuntimeException("Whisper: unable to create temp dir", e);
        }

        try {
            ProcessBuilder pb = new ProcessBuilder(
                    command,
                    audioFile.getAbsolutePath(),
                    "--model", model,
                    "--output_format", "txt",
                    "--output_dir", tempDir.toString(),
                    "--language", "en"
            );
            pb.redirectErrorStream(false);

            // If an explicit ffmpeg directory was provided, prepend it to the
            // child's PATH so Whisper's internal subprocess.run can locate
            // ffmpeg no matter how Tomcat was launched.
            if (!ffmpegPath.isEmpty()) {
                Map<String, String> env = pb.environment();
                String pathKey = null;
                for (String k : env.keySet()) {
                    if ("PATH".equalsIgnoreCase(k)) {
                        pathKey = k;
                        break;
                    }
                }
                String existing = (pathKey == null) ? "" : env.get(pathKey);
                String sep = System.getProperty("path.separator", ":");
                String merged;
                if (existing == null || existing.isEmpty()) {
                    merged = ffmpegPath;
                } else {
                    merged = ffmpegPath + sep + existing;
                }
                env.put(pathKey == null ? "PATH" : pathKey, merged);
            }

            Process proc;
            try {
                proc = pb.start();
            } catch (IOException e) {
                throw new RuntimeException(
                        "Whisper: failed to start process (is '" + command + "' on PATH?)", e);
            }

            // Drain stdout/stderr concurrently so large outputs don't block the process.
            StringBuilder stdout = new StringBuilder();
            StringBuilder stderr = new StringBuilder();
            Thread outThread = new Thread(() -> drain(proc.getInputStream(), stdout));
            Thread errThread = new Thread(() -> drain(proc.getErrorStream(), stderr));
            outThread.setDaemon(true);
            errThread.setDaemon(true);
            outThread.start();
            errThread.start();

            boolean finished;
            try {
                finished = proc.waitFor(PROCESS_TIMEOUT_MINUTES, TimeUnit.MINUTES);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                proc.destroyForcibly();
                throw new RuntimeException("Whisper: interrupted while waiting", e);
            }
            if (!finished) {
                proc.destroyForcibly();
                throw new RuntimeException(
                        "Whisper: timed out after " + PROCESS_TIMEOUT_MINUTES + " minutes");
            }
            try {
                outThread.join(1000);
                errThread.join(1000);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
            }

            int exit = proc.exitValue();
            if (exit != 0) {
                throw new RuntimeException(
                        "Whisper: exit " + exit + "\n" + stderr.toString().trim());
            }

            // Whisper names the output <basename-without-ext>.txt inside the output dir.
            String baseName = audioFile.getName();
            int dot = baseName.lastIndexOf('.');
            if (dot > 0) baseName = baseName.substring(0, dot);
            Path txtFile = tempDir.resolve(baseName + ".txt");
            if (!Files.exists(txtFile)) {
                throw new RuntimeException(
                        "Whisper: expected output file not found: " + txtFile
                                + "\nstderr: " + stderr.toString().trim());
            }

            try {
                return new String(Files.readAllBytes(txtFile), StandardCharsets.UTF_8).trim();
            } catch (IOException e) {
                throw new RuntimeException("Whisper: failed to read output file", e);
            }
        } finally {
            cleanup(tempDir);
        }
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------
    private static void drain(InputStream in, StringBuilder sink) {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(in, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                sink.append(line).append('\n');
            }
        } catch (IOException ignored) {
            // Stream closed — nothing more to read.
        }
    }

    private static void cleanup(Path dir) {
        if (dir == null) return;
        try {
            if (!Files.exists(dir)) return;
            Files.walk(dir)
                    .sorted(Comparator.reverseOrder())
                    .forEach(p -> {
                        try {
                            Files.deleteIfExists(p);
                        } catch (IOException ignored) {
                        }
                    });
        } catch (IOException ignored) {
        }
    }
}
