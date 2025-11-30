using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Cliffwald.Shared;

using Color = Microsoft.Xna.Framework.Color;
using Rectangle = Microsoft.Xna.Framework.Rectangle;
using Point = Microsoft.Xna.Framework.Point;

namespace Cliffwald.Client.Scenes;

public class CharacterCreator
{
    private Rectangle _rectIgnis;
    private Rectangle _rectAxiom;
    private Rectangle _rectVesper;
    private bool _isActive = true;
    public Doctrine SelectedDoctrine = Doctrine.Axiom; // Default
    public bool IsComplete = false;

    public CharacterCreator(int screenWidth, int screenHeight)
    {
        int w = 200;
        int h = 400;
        int gap = 50;
        int startX = (screenWidth - (3 * w + 2 * gap)) / 2;
        int startY = (screenHeight - h) / 2;

        _rectIgnis = new Rectangle(startX, startY, w, h);
        _rectAxiom = new Rectangle(startX + w + gap, startY, w, h);
        _rectVesper = new Rectangle(startX + 2 * w + 2 * gap, startY, w, h);
    }

    public void Update()
    {
        if (IsComplete) return;

        var mouse = Mouse.GetState();
        if (mouse.LeftButton == ButtonState.Pressed)
        {
            Point mousePos = new Point(mouse.X, mouse.Y);
            if (_rectIgnis.Contains(mousePos))
            {
                SelectedDoctrine = Doctrine.Ignis;
                IsComplete = true;
            }
            else if (_rectAxiom.Contains(mousePos))
            {
                SelectedDoctrine = Doctrine.Axiom;
                IsComplete = true;
            }
            else if (_rectVesper.Contains(mousePos))
            {
                SelectedDoctrine = Doctrine.Vesper;
                IsComplete = true;
            }
        }
    }

    public void Draw(SpriteBatch spriteBatch, Texture2D pixel)
    {
        spriteBatch.Begin();

        // Draw Background
        spriteBatch.Draw(pixel, new Rectangle(0, 0, 1920, 1080), Color.Black); // Assume large enough

        // Draw Options
        spriteBatch.Draw(pixel, _rectIgnis, Color.Red);
        spriteBatch.Draw(pixel, _rectAxiom, Color.Blue);
        spriteBatch.Draw(pixel, _rectVesper, Color.Violet);

        // Ideally draw text here "Choose Your Doctrine", but we avoid text if not initialized
        // We will draw a small white border around the hovered one maybe?

        var mouse = Mouse.GetState();
        Point mousePos = new Point(mouse.X, mouse.Y);

        if (_rectIgnis.Contains(mousePos)) DrawBorder(spriteBatch, pixel, _rectIgnis, Color.White);
        if (_rectAxiom.Contains(mousePos)) DrawBorder(spriteBatch, pixel, _rectAxiom, Color.White);
        if (_rectVesper.Contains(mousePos)) DrawBorder(spriteBatch, pixel, _rectVesper, Color.White);

        spriteBatch.End();
    }

    private void DrawBorder(SpriteBatch sb, Texture2D pix, Rectangle rect, Color color)
    {
        int t = 5; // thickness
        sb.Draw(pix, new Rectangle(rect.X - t, rect.Y - t, rect.Width + 2*t, t), color);
        sb.Draw(pix, new Rectangle(rect.X - t, rect.Y + rect.Height, rect.Width + 2*t, t), color);
        sb.Draw(pix, new Rectangle(rect.X - t, rect.Y, t, rect.Height), color);
        sb.Draw(pix, new Rectangle(rect.X + rect.Width, rect.Y, t, rect.Height), color);
    }
}
