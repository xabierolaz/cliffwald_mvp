using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using Cliffwald.Shared;

namespace Cliffwald.Client;

public class LocalPlayer
{
    public PlayerState State;
    private float _speed = 100f; // Pixels per second

    public LocalPlayer(int id, Vector2 startPos)
    {
        State = new PlayerState
        {
            Id = id,
            Position = startPos,
            Direction = 0, // Down
            IsMoving = false
        };
    }

    public void Update(GameTime gameTime)
    {
        var kState = Keyboard.GetState();
        Vector2 input = Vector2.Zero;

        if (kState.IsKeyDown(Keys.W) || kState.IsKeyDown(Keys.Up)) input.Y -= 1;
        if (kState.IsKeyDown(Keys.S) || kState.IsKeyDown(Keys.Down)) input.Y += 1;
        if (kState.IsKeyDown(Keys.A) || kState.IsKeyDown(Keys.Left)) input.X -= 1;
        if (kState.IsKeyDown(Keys.D) || kState.IsKeyDown(Keys.Right)) input.X += 1;

        if (input != Vector2.Zero)
        {
            input.Normalize();
            State.IsMoving = true;
            State.Velocity = input * _speed;

            // Determine Direction
            if (input.Y > 0) State.Direction = 0; // Down
            else if (input.X > 0) State.Direction = 1; // Right
            else if (input.Y < 0) State.Direction = 2; // Up
            else if (input.X < 0) State.Direction = 3; // Left
        }
        else
        {
            State.IsMoving = false;
            State.Velocity = Vector2.Zero;
        }

        // Integrate Position
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        State.Position += State.Velocity * dt;
    }
}
