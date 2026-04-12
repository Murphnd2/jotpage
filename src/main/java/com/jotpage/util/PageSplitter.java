package com.jotpage.util;

import java.util.ArrayList;
import java.util.List;

/**
 * Splits a block of text into a sequence of page-sized chunks that fit the
 * JotPage canvas (1480x2100 internal px, minus margins).
 *
 * Usable area:           1380 wide, 2000 tall
 * Character width est.:  fontSize * 0.6 (monospace approximation)
 * Line height:           fontSize * 1.5
 *
 * Respects existing newlines (so markdown headers, bullet points, and blank
 * lines from paragraph breaks are preserved). Never splits a word.
 *
 * ==== Font size scaling ====
 * The JotPage canvas is 1480x2100 internal pixels — that's a real A5 page
 * (148x210 mm) at 10x resolution. So 1 mm on the page = 10 canvas pixels,
 * and a real-world N-point font size corresponds to N * 10 canvas pixels.
 *
 * splitToPages accepts a UI "point size" (e.g. 16) and multiplies by
 * POINT_TO_PIXEL internally before computing chars-per-line and
 * lines-per-page. Callers that also need to emit canvas-pixel font sizes
 * elsewhere (e.g. when writing text_layers JSON into a Page) should import
 * PageSplitter.POINT_TO_PIXEL so there's one source of truth for the scale.
 */
public final class PageSplitter {

    private static final int USABLE_WIDTH = 1380;
    private static final int USABLE_HEIGHT = 2000;

    /**
     * Conversion factor from UI point sizes to internal canvas pixels.
     * The canvas is A5 at 10x, so 1 pt ≈ 10 canvas px.
     */
    public static final int POINT_TO_PIXEL = 10;

    private PageSplitter() {
    }

    /**
     * @param text      the text to lay out
     * @param pointSize the UI-displayed point size (e.g. 16). Internally
     *                  multiplied by {@link #POINT_TO_PIXEL} to get the
     *                  canvas-pixel size used for the geometry maths.
     */
    public static List<String> splitToPages(String text, int pointSize) {
        if (pointSize <= 0) pointSize = 16;
        int pixelSize = pointSize * POINT_TO_PIXEL;
        int charsPerLine = Math.max(1, (int) Math.floor(USABLE_WIDTH / (pixelSize * 0.6)));
        int linesPerPage = Math.max(1, (int) Math.floor(USABLE_HEIGHT / (pixelSize * 1.5)));

        if (text == null) text = "";

        // 1) Flatten into a list of display lines, honoring newlines as hard
        //    breaks and word-wrapping everything else.
        List<String> displayLines = new ArrayList<>();
        String[] rawLines = text.split("\n", -1);
        for (String raw : rawLines) {
            if (raw.isEmpty()) {
                displayLines.add("");
                continue;
            }
            wrapLine(raw, charsPerLine, displayLines);
        }

        // 2) Paginate: pack up to linesPerPage display lines into each page.
        List<String> pages = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        int linesInCurrent = 0;
        for (String line : displayLines) {
            if (linesInCurrent == linesPerPage) {
                pages.add(current.toString());
                current = new StringBuilder();
                linesInCurrent = 0;
            }
            if (linesInCurrent > 0) current.append('\n');
            current.append(line);
            linesInCurrent++;
        }
        if (linesInCurrent > 0) {
            pages.add(current.toString());
        }

        // Edge case: empty input → single empty page, so callers always get
        // at least one page back.
        if (pages.isEmpty()) pages.add("");
        return pages;
    }

    /**
     * Word-wrap a single logical line into charsPerLine-width display lines.
     * Never splits mid-word: any word longer than charsPerLine occupies its
     * own line as-is.
     */
    private static void wrapLine(String line, int charsPerLine, List<String> out) {
        if (line.length() <= charsPerLine) {
            out.add(line);
            return;
        }
        String[] words = line.split(" ");
        StringBuilder cur = new StringBuilder();
        for (String word : words) {
            if (word.isEmpty()) {
                // Preserve consecutive spaces as best we can without splitting.
                if (cur.length() > 0 && cur.length() < charsPerLine) {
                    cur.append(' ');
                }
                continue;
            }
            if (word.length() > charsPerLine) {
                // Word is wider than a line — flush whatever we have and put
                // the word on its own line as-is. Per spec: never split words.
                if (cur.length() > 0) {
                    out.add(cur.toString());
                    cur.setLength(0);
                }
                out.add(word);
                continue;
            }
            if (cur.length() == 0) {
                cur.append(word);
            } else if (cur.length() + 1 + word.length() <= charsPerLine) {
                cur.append(' ').append(word);
            } else {
                out.add(cur.toString());
                cur.setLength(0);
                cur.append(word);
            }
        }
        if (cur.length() > 0) {
            out.add(cur.toString());
        }
    }
}
