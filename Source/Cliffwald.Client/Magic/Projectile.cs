using Microsoft.Xna.Framework;

using Color = Microsoft.Xna.Framework.Color;
using Rectangle = Microsoft.Xna.Framework.Rectangle;

namespace Cliffwald.Client.Magic;

public class Projectile
{
    public Vector2 Position;
    public Vector2 Velocity;
    public Color Color;
    public bool IsActive;
    public float Scale;

    public Projectile(Vector2 pos, Vector2 vel, Color color, float scale = 1.0f)
    {
        Position = pos;
        Velocity = vel;
        Color = color;
        IsActive = true;
        Scale = scale;
    }

    public void Update(float dt)
    {
        Position += Velocity * dt;
        // Simple bounds check or lifetime could go here
        if (Position.LengthSquared() > 2000 * 2000) // Despawn if too far
            IsActive = false;
    }
}
