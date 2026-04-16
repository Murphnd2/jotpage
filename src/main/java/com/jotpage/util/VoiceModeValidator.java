package com.jotpage.util;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Light-weight pre-flight check for non-verbatim voice processing modes.
 * Each mode looks for simple signals that the transcript can reasonably be
 * turned into the requested artifact (notes, minutes, journal, outline). If
 * those signals are missing we fail fast so the user gets an actionable
 * message rather than a Claude call against unsuitable content.
 *
 * Verbatim is never validated — it's the fall-through mode.
 */
public final class VoiceModeValidator {

    public static final class Result {
        public final boolean ok;
        public final String userMessage; // null when ok
        public final String detail;      // short debug reason, null when ok

        private Result(boolean ok, String userMessage, String detail) {
            this.ok = ok;
            this.userMessage = userMessage;
            this.detail = detail;
        }

        public static Result ok() { return new Result(true, null, null); }
        public static Result fail(String userMessage, String detail) {
            return new Result(false, userMessage, detail);
        }
    }

    // Whole-word stop list for the repeated-noun check in study_notes.
    private static final Set<String> STOP_WORDS = new HashSet<>(Arrays.asList(
        "a","an","and","or","the","is","are","was","were","be","to","of","in","on",
        "at","for","with","this","that","these","those","it","its","as","by","from",
        "you","your","we","our","they","them","their","he","she","his","her","has",
        "have","had","do","does","did","not","but","if","so","just","like","about"
    ));

    // First-person pronouns we look for in journal_entry (case-insensitive,
    // whole-word matched against tokens that keep their apostrophes).
    private static final Set<String> FIRST_PERSON = new HashSet<>(Arrays.asList(
        "i","i'm","i've","i'll","i'd","me","my","myself","mine"
    ));

    private VoiceModeValidator() {}

    // ------------------------------------------------------------------
    // Entry point — rules read top-to-bottom per mode.
    // ------------------------------------------------------------------
    public static Result validate(String jobType, String transcript, String customPrompt) {
        String t = transcript == null ? "" : transcript;
        String lower = t.toLowerCase();

        if ("verbatim".equals(jobType)) {
            return Result.ok();
        }

        if ("custom".equals(jobType)) {
            if (customPrompt == null || customPrompt.trim().length() < 10) {
                return Result.fail(
                    "Add a custom instruction of at least 10 characters.",
                    "custom:prompt-missing");
            }
            if (wordCount(t) < 20) {
                return Result.fail(
                    "Record at least a few sentences before running custom processing.",
                    "custom:too-short");
            }
            return Result.ok();
        }

        int wc = wordCount(t);

        if ("study_notes".equals(jobType)) {
            if (wc < 80) {
                return Result.fail(
                    "Study Notes mode needs more content to organize. Try recording a longer explanation of a topic, or switch to Verbatim.",
                    "study_notes:too-short");
            }
            String[] markers = {
                "is defined as", "means", "refers to",
                "the concept of", "the idea of",
                "for example", "in other words"
            };
            if (containsAnyPhrase(lower, markers)) return Result.ok();
            if (hasRepeatedContentNoun(t)) return Result.ok();
            if (sentenceCount(t) >= 3) return Result.ok();
            return Result.fail(
                "Study Notes mode needs more content to organize. Try recording a longer explanation of a topic, or switch to Verbatim.",
                "study_notes:no-topic-signal");
        }

        if ("meeting_minutes".equals(jobType)) {
            if (wc < 60) {
                return Result.fail(
                    "Meeting Minutes mode looks for decisions, action items, or attendees. This recording doesn't seem to contain them \u2014 switch to Verbatim or re-record with more meeting context.",
                    "meeting_minutes:too-short");
            }
            String[] verbs = {
                "decided", "agreed", "approved", "rejected",
                "will do", "we'll", "going to",
                "action item", "next step", "follow up",
                "assigned to", "owner"
            };
            if (containsAnyPhrase(lower, verbs)) return Result.ok();
            if (countProperNounTokens(t) >= 2) return Result.ok();
            return Result.fail(
                "Meeting Minutes mode looks for decisions, action items, or attendees. This recording doesn't seem to contain them \u2014 switch to Verbatim or re-record with more meeting context.",
                "meeting_minutes:no-meeting-signal");
        }

        if ("journal_entry".equals(jobType)) {
            if (wc < 40) {
                return Result.fail(
                    "Journal Entry mode is for reflective first-person writing. Try recording in first person, or switch to Verbatim.",
                    "journal_entry:too-short");
            }
            if (countFirstPerson(t) >= 3) return Result.ok();
            return Result.fail(
                "Journal Entry mode is for reflective first-person writing. Try recording in first person, or switch to Verbatim.",
                "journal_entry:no-first-person");
        }

        if ("outline".equals(jobType)) {
            if (wc < 60) {
                return Result.fail(
                    "Outline mode needs structured content with multiple topics. Try enumerating your points as you speak, or switch to Verbatim.",
                    "outline:too-short");
            }
            String[] markers = {
                "first", "second", "third", "next", "another", "finally",
                "also", "additionally", "on the other hand", "in addition",
                "one", "two", "three"
            };
            if (containsAnyPhrase(lower, markers)) return Result.ok();
            if (hasColonList(t)) return Result.ok();
            return Result.fail(
                "Outline mode needs structured content with multiple topics. Try enumerating your points as you speak, or switch to Verbatim.",
                "outline:no-structure-signal");
        }

        return Result.fail("Unsupported processing mode.", "unknown:" + jobType);
    }

    // ------------------------------------------------------------------
    // Small helpers
    // ------------------------------------------------------------------

    private static int wordCount(String t) {
        if (t == null) return 0;
        String trimmed = t.trim();
        if (trimmed.isEmpty()) return 0;
        return trimmed.split("\\s+").length;
    }

    private static int sentenceCount(String t) {
        if (t == null || t.isEmpty()) return 0;
        int count = 0;
        for (int i = 0; i < t.length(); i++) {
            char c = t.charAt(i);
            if (c == '.' || c == '!' || c == '?') count++;
        }
        return count;
    }

    // Matches any of the given lowercase phrases as a whole word / whole
    // phrase, bounded by regex \b. Prevents "means" from matching inside
    // "meaning" or "one" from matching inside "anyone".
    private static boolean containsAnyPhrase(String lowerTranscript, String[] phrases) {
        for (String p : phrases) {
            Pattern pat = Pattern.compile("\\b" + Pattern.quote(p) + "\\b");
            if (pat.matcher(lowerTranscript).find()) return true;
        }
        return false;
    }

    private static boolean hasRepeatedContentNoun(String t) {
        Map<String, Integer> counts = new HashMap<>();
        for (String tok : letterTokens(t)) {
            if (tok.length() < 5) continue;
            if (STOP_WORDS.contains(tok)) continue;
            int c = counts.getOrDefault(tok, 0) + 1;
            counts.put(tok, c);
            if (c >= 3) return true;
        }
        return false;
    }

    // Capitalized tokens (length >= 2 after stripping non-letter chars) that
    // are not the first token of a sentence. A token is sentence-initial if
    // it's the very first token or the previous token ended in . ! or ?.
    private static int countProperNounTokens(String t) {
        if (t == null || t.isEmpty()) return 0;
        String trimmed = t.trim();
        if (trimmed.isEmpty()) return 0;
        String[] raw = trimmed.split("\\s+");
        int count = 0;
        boolean sentenceInitial = true;
        for (String tok : raw) {
            if (tok.isEmpty()) continue;
            String core = tok.replaceAll("^[^\\p{L}]+", "").replaceAll("[^\\p{L}]+$", "");
            boolean isProperNoun = core.length() >= 2 && Character.isUpperCase(core.charAt(0));
            if (isProperNoun && !sentenceInitial) count++;
            char last = tok.charAt(tok.length() - 1);
            sentenceInitial = (last == '.' || last == '!' || last == '?');
        }
        return count;
    }

    private static int countFirstPerson(String t) {
        int count = 0;
        for (String tok : firstPersonTokens(t)) {
            if (FIRST_PERSON.contains(tok)) count++;
        }
        return count;
    }

    // Look for a ':' followed within the next 200 characters by at least two
    // separator characters (',' or ';'). Cheap approximation of a list like
    // "agenda: intro, discussion, next steps".
    private static boolean hasColonList(String t) {
        if (t == null) return false;
        int idx = 0;
        while ((idx = t.indexOf(':', idx)) >= 0) {
            int end = Math.min(t.length(), idx + 1 + 200);
            String window = t.substring(idx + 1, end);
            int separators = 0;
            for (int i = 0; i < window.length(); i++) {
                char c = window.charAt(i);
                if (c == ',' || c == ';') separators++;
                if (separators >= 2) return true;
            }
            idx++;
        }
        return false;
    }

    // Lowercase, letter-only tokens (strip digits/punctuation). Used by the
    // repeated-noun check where we want simple bag-of-words counting.
    private static List<String> letterTokens(String t) {
        List<String> out = new ArrayList<>();
        if (t == null) return out;
        String trimmed = t.trim();
        if (trimmed.isEmpty()) return out;
        String[] raw = trimmed.split("\\s+");
        for (String tok : raw) {
            String stripped = tok.toLowerCase().replaceAll("[^a-z]", "");
            if (!stripped.isEmpty()) out.add(stripped);
        }
        return out;
    }

    // Lowercase tokens that preserve apostrophes, with curly apostrophes
    // normalized to straight. Used by the first-person check so tokens like
    // "I'm" match the FIRST_PERSON set regardless of keyboard layout.
    private static List<String> firstPersonTokens(String t) {
        List<String> out = new ArrayList<>();
        if (t == null) return out;
        String normalized = t.replace('\u2019', '\'').toLowerCase();
        String trimmed = normalized.trim();
        if (trimmed.isEmpty()) return out;
        String[] raw = trimmed.split("\\s+");
        for (String tok : raw) {
            String stripped = tok.replaceAll("^[^a-z']+", "").replaceAll("[^a-z']+$", "");
            if (!stripped.isEmpty()) out.add(stripped);
        }
        return out;
    }
}
