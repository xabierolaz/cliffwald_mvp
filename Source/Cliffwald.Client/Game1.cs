using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Linq;
using Cliffwald.Client.Utils;

namespace Cliffwald.Client;

public class Game1 : Game
{
    private GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch;
    private bool _renderTestMode;
    private bool _screenshotTaken;

    private EntityManager _entityManager;
    private LocalPlayer _localPlayer;
    private Texture2D _pixelTexture;

    // Simulation for local testing of "other" entities since we don't have a real netcode hookup yet in this class
    // In a real scenario, network packets would drive EntityManager.
    // For this Sprint, we will rely on the "Draw ALL entities" requirement.
    // The prompt asks for "Server Simulation Loop" in Server/Program.cs, but Game1 needs to show them.
    // Since we don't have network yet, I will manually add a dummy entity to EntityManager in Initialize
    // to prove the red rendering works.

    public Game1()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        IsMouseVisible = true;
    }

    protected override void Initialize()
    {
        // Check for render test argument
        var args = Environment.GetCommandLineArgs();
        if (args.Contains("--render-test"))
        {
            _renderTestMode = true;
        }

        _entityManager = new EntityManager();
        _localPlayer = new LocalPlayer(999, new Vector2(100, 100));

        // Add a dummy remote entity for visualization
        _entityManager.UpdateEntity(1, new Cliffwald.Shared.PlayerState
        {
            Id = 1,
            Position = new Vector2(200, 200),
            Direction = 0
        });

        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        // Create 1x1 white pixel texture
        _pixelTexture = new Texture2D(GraphicsDevice, 1, 1);
        _pixelTexture.SetData(new Color[] { Color.White });
        // TODO: use this.Content to load your game content here
    }

    protected override void Update(GameTime gameTime)
    {
        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
            Exit();

        _localPlayer.Update(gameTime);

        // In the future, _entityManager updates come from network.
        // For now, they are static or moved by server (but we aren't connected yet).

        base.Update(gameTime);
        // TODO: Add your update logic here

        base.Update(gameTime);

        // If in render test mode and we've already taken the screenshot, we can exit or just idle.
        // For automated testing, exiting is often useful, but the prompt didn't strictly say "Exit".
        // It just said "SaveScreenshot". We will stick to that.
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.CornflowerBlue);

        _spriteBatch.Begin();

        // 1. Draw Local Player (GREEN)
        DrawEntity(_localPlayer.State, Color.Green);

        // 2. Draw Other Entities (RED)
        foreach (var entity in _entityManager.GetAllEntities())
        {
            DrawEntity(entity, Color.Red);
        }

        _spriteBatch.End();
        // TODO: Add your drawing code here

        base.Draw(gameTime);

        if (_renderTestMode && !_screenshotTaken)
        {
            VisualTester.SaveScreenshot(GraphicsDevice, "init_test.png");
            _screenshotTaken = true;
            Console.WriteLine("Render test complete: init_test.png saved.");
        }
    }

    private void DrawEntity(Cliffwald.Shared.PlayerState state, Color color)
    {
        // Draw 32x48 Rectangle centered at Position
        // Assuming Position is the "feet" or center. Let's assume Top-Left for simplicity or Center.
        // Prompt says "Draw them as 32x48 rectangles."
        int width = 32;
        int height = 48;
        Rectangle destRect = new Rectangle((int)state.Position.X, (int)state.Position.Y, width, height);

        _spriteBatch.Draw(_pixelTexture, destRect, color);

        // Debug: Draw Debug Line (Simple representation of direction/heading)
        // Since we don't have a font guaranteed, we draw a small yellow square indicating "head"
        // or a line. Let's draw a small dot at X,Y
        _spriteBatch.Draw(_pixelTexture, new Rectangle((int)state.Position.X, (int)state.Position.Y, 2, 2), Color.Yellow);
    }
            // We do this at the end of Draw to capture the final frame state
            VisualTester.SaveScreenshot(GraphicsDevice, "init_test.png");
            _screenshotTaken = true;

            // Optional: Print to console for the test runner to see
            Console.WriteLine("Render test complete: init_test.png saved.");
        }
    }
}
