import java.awt.*;
import java.awt.geom.RoundRectangle2D;
import java.awt.image.BufferedImage;
import java.io.File;
import javax.imageio.ImageIO;

/**
 * Generates Jyrnyl PWA icons into src/main/webapp/icons/.
 *
 * Run from the project root:
 *   javac tools/IconGenerator.java
 *   java  -cp tools IconGenerator
 *
 * Produces:
 *   icon-192.png           — standard (rounded-square style, full-bleed)
 *   icon-512.png           — standard (rounded-square style, full-bleed)
 *   icon-maskable-512.png  — maskable (content confined to central 70% safe zone)
 *   favicon-32.png         — tiny favicon
 */
public class IconGenerator {

    // Brand palette (from theme.css)
    private static final Color BG_BROWN   = new Color(0x4a, 0x37, 0x28);
    private static final Color BG_BROWN_D = new Color(0x33, 0x25, 0x18);
    private static final Color ACCENT_GOLD = new Color(0xd4, 0x94, 0x3a);
    private static final Color BG_CREAM    = new Color(0xf8, 0xf4, 0xec);

    public static void main(String[] args) throws Exception {
        File outDir = new File("src/main/webapp/icons");
        if (!outDir.exists() && !outDir.mkdirs()) {
            throw new RuntimeException("Could not create " + outDir.getAbsolutePath());
        }

        write(outDir, "icon-192.png",          render(192, false));
        write(outDir, "icon-512.png",          render(512, false));
        write(outDir, "icon-maskable-512.png", render(512, true));
        write(outDir, "favicon-32.png",        render(32,  false));

        System.out.println("Done. Icons written to " + outDir.getAbsolutePath());
    }

    private static void write(File dir, String name, BufferedImage img) throws Exception {
        File out = new File(dir, name);
        ImageIO.write(img, "png", out);
        System.out.println("  wrote " + out.getName() + " (" + img.getWidth() + "x" + img.getHeight() + ")");
    }

    /**
     * Renders the Jyrnyl icon.
     *
     * @param size     edge length in pixels
     * @param maskable if true, keeps visual content inside the central 70% safe zone
     *                 (per W3C maskable-icon spec) so Android/iOS can crop to any shape.
     */
    private static BufferedImage render(int size, boolean maskable) {
        BufferedImage img = new BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = img.createGraphics();
        try {
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
            g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);

            // Maskable icons get a full-bleed background; standard icons get a rounded square.
            if (maskable) {
                // Full-bleed radial background.
                GradientPaint bg = new GradientPaint(
                        size * 0.25f, size * 0.25f, BG_BROWN,
                        size * 0.85f, size * 0.85f, BG_BROWN_D);
                g.setPaint(bg);
                g.fillRect(0, 0, size, size);
            } else {
                g.setColor(new Color(0, 0, 0, 0));
                g.fillRect(0, 0, size, size);
                float corner = size * 0.22f;
                RoundRectangle2D shape = new RoundRectangle2D.Float(0, 0, size, size, corner, corner);
                GradientPaint bg = new GradientPaint(
                        size * 0.25f, size * 0.25f, BG_BROWN,
                        size * 0.85f, size * 0.85f, BG_BROWN_D);
                g.setPaint(bg);
                g.fill(shape);
            }

            // Inner safe zone for glyph/text.
            // For maskable: 70% (per spec). For standard: 80% (leaves breathing room).
            float safe = maskable ? 0.70f : 0.80f;
            float inset = size * (1 - safe) / 2f;
            float box = size - inset * 2;

            // Subtle inner border frame (the "liner-notes" card feel from login-card::before).
            float border = Math.max(1f, size * 0.010f);
            g.setStroke(new BasicStroke(border));
            g.setColor(new Color(255, 255, 255, 30));
            float fInset = inset + size * 0.06f;
            float fBox = size - fInset * 2;
            if (fBox > 0) {
                float fCorner = size * 0.06f;
                g.draw(new RoundRectangle2D.Float(fInset, fInset, fBox, fBox, fCorner, fCorner));
            }

            // The big serif "J".
            // DM Serif Display not guaranteed on the JVM — fall back gracefully through a list.
            String[] fontCandidates = {
                    "DM Serif Display", "Georgia", "Times New Roman", "Serif"
            };
            Font font = null;
            for (String name : fontCandidates) {
                Font f = new Font(name, Font.BOLD, 10);
                if (!f.getFamily().equalsIgnoreCase("Dialog")) { font = f; break; }
                font = f;
            }
            // Scale font to fill ~80% of the safe box height.
            float targetH = box * 0.78f;
            Font big = font.deriveFont(Font.BOLD, targetH);
            g.setFont(big);
            FontMetrics fm = g.getFontMetrics();
            String glyph = "J";
            int glyphW = fm.stringWidth(glyph);
            int ascent = fm.getAscent();
            int descent = fm.getDescent();
            int glyphH = ascent + descent;
            float cx = size / 2f;
            float cy = size / 2f;
            float drawX = cx - glyphW / 2f;
            float drawY = cy + (ascent - glyphH / 2f) - size * 0.02f;
            g.setColor(ACCENT_GOLD);
            g.drawString(glyph, drawX, drawY);

            // Gold underline (matches the "login-rule" divider from index.jsp).
            float ruleW = box * 0.35f;
            float ruleH = Math.max(2f, size * 0.010f);
            float ruleX = cx - ruleW / 2f;
            float ruleY = drawY + descent * 0.4f + size * 0.02f;
            g.setColor(ACCENT_GOLD);
            g.fillRoundRect((int) ruleX, (int) ruleY, (int) ruleW, (int) ruleH,
                    (int) ruleH, (int) ruleH);

            // Cream subtitle dots under the rule — tiny decorative flourish.
            float dotSize = Math.max(2f, size * 0.012f);
            float dotY = ruleY + ruleH + size * 0.03f;
            g.setColor(new Color(BG_CREAM.getRed(), BG_CREAM.getGreen(), BG_CREAM.getBlue(), 160));
            for (int i = -1; i <= 1; i++) {
                float dx = cx + i * (dotSize * 2.2f) - dotSize / 2f;
                g.fillOval((int) dx, (int) dotY, (int) dotSize, (int) dotSize);
            }
        } finally {
            g.dispose();
        }
        return img;
    }
}
