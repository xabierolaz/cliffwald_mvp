#!/bin/bash
# Initialize Directory Structure
mkdir -p Source/Cliffwald.Client/Utils
mkdir -p Source/Cliffwald.Server
mkdir -p Source/Cliffwald.Shared
mkdir -p Output/Previews
mkdir -p References
mkdir -p Assets/Textures
mkdir -p Assets/Shaders

# Create Solution
# Note: These commands will fail if dotnet is not installed, but they are part of the requested script.
dotnet new sln -n Cliffwald

# Create Projects
dotnet new console -n Cliffwald.Client -o Source/Cliffwald.Client
dotnet new console -n Cliffwald.Server -o Source/Cliffwald.Server
dotnet new classlib -n Cliffwald.Shared -o Source/Cliffwald.Shared

# Add Projects to Solution
dotnet sln add Source/Cliffwald.Client/Cliffwald.Client.csproj
dotnet sln add Source/Cliffwald.Server/Cliffwald.Server.csproj
dotnet sln add Source/Cliffwald.Shared/Cliffwald.Shared.csproj

# Add References
dotnet add Source/Cliffwald.Client/Cliffwald.Client.csproj reference Source/Cliffwald.Shared/Cliffwald.Shared.csproj
dotnet add Source/Cliffwald.Server/Cliffwald.Server.csproj reference Source/Cliffwald.Shared/Cliffwald.Shared.csproj

# Add Packages
# Client needs ImageSharp and MonoGame
dotnet add Source/Cliffwald.Client/Cliffwald.Client.csproj package SixLabors.ImageSharp
dotnet add Source/Cliffwald.Client/Cliffwald.Client.csproj package MonoGame.Framework.DesktopGL

# Shared needs MonoGame for Vector2
dotnet add Source/Cliffwald.Shared/Cliffwald.Shared.csproj package MonoGame.Framework.DesktopGL

# Create VisualTester.cs
cat <<EOF > Source/Cliffwald.Client/Utils/VisualTester.cs
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
EOF

# Create PlayerState.cs
cat <<EOF > Source/Cliffwald.Shared/PlayerState.cs
using Microsoft.Xna.Framework;

namespace Cliffwald.Shared;

public struct PlayerState
{
    public int Id;
    public Vector2 Pos;
}
EOF

echo "Cliffwald Repository Initialized Successfully."
