using Microsoft.Xna.Framework.Graphics;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using System.IO;

namespace Cliffwald.Client.Utils;

public static class VisualTester
{
    public static void SaveScreenshot(GraphicsDevice device, string filename)
    {
        int w = device.PresentationParameters.BackBufferWidth;
        int h = device.PresentationParameters.BackBufferHeight;
        Microsoft.Xna.Framework.Color[] backBuffer = new Microsoft.Xna.Framework.Color[w * h];
        device.GetBackBufferData(backBuffer);

        using (Image<Rgba32> image = new Image<Rgba32>(w, h))
        {
            image.ProcessPixelRows(accessor =>
            {
                for (int y = 0; y < h; y++)
                {
                    var pixelRow = accessor.GetRowSpan(y);
                    for (int x = 0; x < w; x++)
                    {
                        var color = backBuffer[y * w + x];
                        pixelRow[x] = new Rgba32(color.R, color.G, color.B, color.A);
                    }
                }
            });

            // Ensure output directory exists
            // Assuming execution from project root or bin folder, we try to locate Output/Previews
            string outputDir = Path.Combine(System.Environment.CurrentDirectory, "Output", "Previews");

            // If the folder doesn't exist in current dir, check if we are in bin/Debug/...
            if (!Directory.Exists(Path.Combine(System.Environment.CurrentDirectory, "Output")))
            {
                 // Fallback: Try to find repo root by walking up?
                 // For now, let's create it in CurrentDirectory/Output/Previews which is safe
            }
            Directory.CreateDirectory(outputDir);

            string path = Path.Combine(outputDir, filename);
            image.SaveAsPng(path);
            System.Console.WriteLine($"Saved screenshot to: {path}");
        }
    }
}
