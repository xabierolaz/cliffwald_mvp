using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using System;
using System.Linq;

namespace Cliffwald.Client.Input;

public class MagicSystem
{
    public List<Vector2> Trail = new List<Vector2>();
    public string LastSpell = "None";

    private MouseState _lastMouse;
    private bool _isDrawing = false;

    public void Update()
    {
        MouseState currentMouse = Mouse.GetState();

        // Right Click Drag
        if (currentMouse.RightButton == ButtonState.Pressed)
        {
            if (!_isDrawing)
            {
                _isDrawing = true;
                Trail.Clear();
                LastSpell = "Casting...";
            }

            Vector2 pos = new Vector2(currentMouse.X, currentMouse.Y);
            if (Trail.Count == 0 || Vector2.Distance(Trail.Last(), pos) > 5)
            {
                Trail.Add(pos);
            }
        }
        else if (_isDrawing && currentMouse.RightButton == ButtonState.Released)
        {
            _isDrawing = false;
            Analyze();
        }

        _lastMouse = currentMouse;
    }

    private void Analyze()
    {
        if (Trail.Count < 5)
        {
            LastSpell = "Fizzle (Too short)";
            return;
        }

        float minX = float.MaxValue, maxX = float.MinValue;
        float minY = float.MaxValue, maxY = float.MinValue;

        foreach (var p in Trail)
        {
            if (p.X < minX) minX = p.X;
            if (p.X > maxX) maxX = p.X;
            if (p.Y < minY) minY = p.Y;
            if (p.Y > maxY) maxY = p.Y;
        }

        float width = maxX - minX;
        float height = maxY - minY;

        Vector2 first = Trail.First();
        Vector2 last = Trail.Last();
        float distFirstLast = Vector2.Distance(first, last);

        // Horizontal Line: Width > 100 && Height < 30
        if (width > 100 && height < 30)
        {
            LastSpell = "FORCE PUSH (Line)";
            return;
        }

        // Circle: Width approx Height && Distance(First, Last) < 20 (Prompt says 20)
        // Check Aspect Ratio
        if (Math.Abs(width - height) < 50 && distFirstLast < 20)
        {
            LastSpell = "FIREBALL (Circle)";
            return;
        }

        LastSpell = "Fizzle (Unknown)";
    }
}
