using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using System.Linq;
using Cliffwald.Client.Magic;

namespace Cliffwald.Client.Input;

public class MagicSystem
{
    public List<Vector2> Trail = new List<Vector2>();
    public string LastSpell = "None";

    private MouseState _lastMouse;
    private bool _isDrawing = false;
    private GestureRecognizer _recognizer;

    // Updated Delegate to include Center
    public delegate void SpellCastHandler(string spellName, Vector2 start, Vector2 end, Vector2 center);
    public event SpellCastHandler OnSpellCast;

    public MagicSystem()
    {
        _recognizer = new GestureRecognizer();
    }

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
        string shape = _recognizer.Recognize(Trail);
        Vector2 start = Trail.Count > 0 ? Trail.First() : Vector2.Zero;
        Vector2 end = Trail.Count > 0 ? Trail.Last() : Vector2.Zero;
        Vector2 center = GetCentroid(Trail);

        // Map Shape to Spell
        switch (shape)
        {
            case "Line":
                LastSpell = "Force Push";
                OnSpellCast?.Invoke("Force Push", start, end, center);
                break;
            case "Circle":
                LastSpell = "Fireball";
                OnSpellCast?.Invoke("Fireball", start, end, center);
                break;
            case "Square":
                LastSpell = "Shield";
                OnSpellCast?.Invoke("Shield", start, end, center);
                break;
            case "Triangle":
                LastSpell = "Lightning";
                OnSpellCast?.Invoke("Lightning", start, end, center);
                break;
            default:
                LastSpell = "Fizzle";
                break;
        }
    }

    private Vector2 GetCentroid(List<Vector2> points)
    {
        if (points == null || points.Count == 0) return Vector2.Zero;
        float x = 0, y = 0;
        foreach (var p in points)
        {
            x += p.X;
            y += p.Y;
        }
        return new Vector2(x / points.Count, y / points.Count);
    }
}
