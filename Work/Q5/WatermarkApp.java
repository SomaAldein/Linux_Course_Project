import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;

public class WatermarkApp {
    public static void main(String[] args) {
        if (args.length != 1) {
            System.out.println("Usage: java WatermarkApp <images_directory>");
            return;
        }

        String imagesDir = args[0];
        File folder = new File(imagesDir);
        File[] images = folder.listFiles((dir, name) -> name.endsWith(".png"));

        if (images == null || images.length == 0) {
            System.out.println("No images found in directory: " + imagesDir);
            return;
        }

        for (File imageFile : images) {
            try {
                BufferedImage image = ImageIO.read(imageFile);
                Graphics2D g2d = image.createGraphics();

                // Set font and color
                Font font = new Font("Arial", Font.BOLD, 30);
                g2d.setFont(font);
                g2d.setColor(new Color(102, 0, 51)); // Red with transparency

                // Watermark text
                String watermark = "Soma Fkaher Aldeen - 214046013, Lujain Awidat - 325217792";

                // Get text size dynamically
                FontMetrics fontMetrics = g2d.getFontMetrics();
                int textWidth = fontMetrics.stringWidth(watermark);
                int textHeight = fontMetrics.getHeight();

                // Position the watermark at the top-center
                int x = (image.getWidth() - textWidth) / 2; // Center horizontally
                int y = textHeight + 10; // Add padding from top

                g2d.drawString(watermark, x, y);
                g2d.dispose();

                ImageIO.write(image, "png", imageFile);
                System.out.println("Watermark added to: " + imageFile.getName());

            } catch (IOException e) {
                System.out.println("Error processing image: " + imageFile.getName());
                e.printStackTrace();
            }
        }
    }
}
