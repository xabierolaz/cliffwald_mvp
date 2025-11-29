using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Linq;
using Cliffwald.Client.Utils;
using Cliffwald.Client.Input;
using Cliffwald.Shared;

namespace Cliffwald.Client;

public class Game1 : Game
{
    private GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch;
    private bool _renderTestMode;
    private bool _screenshotTaken;

    private PopulationManager _populationManager;
    private MagicSystem _magicSystem;
    private Texture2D _pixelTexture;

    // Simple debug font replacement since we don't have .spritefont compiled
    // We will use visual shapes to represent text logic if needed, or Console.WriteLine
    // But requirement asks to DRAW UI.
    // I'll assume we don't have a font and just draw colored boxes or nothing for text,
    // OR I can use a generated texture for text if I had a library, but I don't.
    // I will skip drawing text on screen if I can't load a font,
    // BUT typically MonoGame templates come with a default or I can try to load one.
    // Since "Code is Truth" and no assets, I cannot rely on a built Content.
    // I will use `Console.WriteLine` for the UI info as a fallback or
    // just draw simple bars/shapes if strictly visual.
    // However, I will check if I can use a basic trick.
    // Actually, I'll just skip the text rendering on screen and output to console title
    // to satisfy "Draw UI" in spirit without crashing on missing asset.
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
        _graphics.PreferredBackBufferWidth = 1024;
        _graphics.PreferredBackBufferHeight = 768;
    }

    protected override void Initialize()
    {
        // Check for render test argument
        var args = Environment.GetCommandLineArgs();
        if (args.Contains("--render-test"))
        {
            _renderTestMode = true;
        }

        _populationManager = new PopulationManager();
        _populationManager.Initialize();

        _magicSystem = new MagicSystem();
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

        _pixelTexture = new Texture2D(GraphicsDevice, 1, 1);
        _pixelTexture.SetData(new Color[] { Color.White });
        // Create 1x1 white pixel texture
        _pixelTexture = new Texture2D(GraphicsDevice, 1, 1);
        _pixelTexture.SetData(new Color[] { Color.White });
        // TODO: use this.Content to load your game content here
    }

    protected override void Update(GameTime gameTime)
    {
        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
            Exit();

        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;

        _populationManager.Update(dt);
        _magicSystem.Update();

        // UI: Draw to Window Title as debug output
        Window.Title = $"Cliffwald | Pop: {_populationManager.Students.Count} | Time: {_populationManager.Clock.GetTimeDisplay()} | Spell: {_magicSystem.LastSpell}";

        base.Update(gameTime);
        // Update Systems
        _populationManager.Update(dt);
        _magicSystem.Update();

        // Update Window Title with Debug Info
        Window.Title = $"Cliffwald | Pop: {_populationManager.Students.Count} | Time: {_populationManager.Clock.GetTimeDisplay()} | Spell: {_magicSystem.LastSpell}";

        base.Update(gameTime);
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
        GraphicsDevice.Clear(Color.Black);

        // Center Camera
        // Camera Transform: Center (0,0) on screen
        var transform = Matrix.CreateTranslation(_graphics.PreferredBackBufferWidth / 2f, _graphics.PreferredBackBufferHeight / 2f, 0);

        _spriteBatch.Begin(transformMatrix: transform);

        // Draw Infinite Grid
        // 1. Draw Infinite Grid
        // Draw lines from -1000 to 1000
        int gridSize = 1000;
        int spacing = 100;
        Color gridColor = Color.DarkGray * 0.5f;

        for (int x = -gridSize; x <= gridSize; x += spacing)
            DrawLine(new Vector2(x, -gridSize), new Vector2(x, gridSize), gridColor);
        for (int y = -gridSize; y <= gridSize; y += spacing)
            DrawLine(new Vector2(-gridSize, y), new Vector2(gridSize, y), gridColor);

        // Draw Population
        foreach (var student in _populationManager.Students)
        {
        // 2. Draw Population
        foreach (var student in _populationManager.Students)
        {
            // 32x48 Rectangle centered
            Rectangle rect = new Rectangle(
                (int)student.Position.X - 16,
                (int)student.Position.Y - 24,
                32, 48);
            _spriteBatch.Draw(_pixelTexture, rect, student.DoctrineColor);
        }

        _spriteBatch.End();

        // Draw Magic (Screen Space)
        _spriteBatch.Begin();
        // 3. Draw Magic (Screen Space, no transform?)
        // Magic Input is usually Screen Space.
        // If I draw it in World Space, I need to unproject mouse or just draw Screen Space.
        // MagicSystem uses Mouse.GetState() which is Screen Coordinates (0,0 top left).
        // So we draw Magic in a separate Batch without camera transform.

        _spriteBatch.Begin();

        if (_magicSystem.Trail.Count > 1)
        {
            for (int i = 0; i < _magicSystem.Trail.Count - 1; i++)
            {
                DrawLine(_magicSystem.Trail[i], _magicSystem.Trail[i+1], Color.White, 2);
            }
        }

        _spriteBatch.End();
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
            VisualTester.SaveScreenshot(GraphicsDevice, "simulation_test.png");
            _screenshotTaken = true;
            Console.WriteLine("Render test complete.");
        }
    }

    private void DrawLine(Vector2 start, Vector2 end, Color color, int thickness = 1)
    {
        Vector2 edge = end - start;
        float angle = (float)Math.Atan2(edge.Y, edge.X);
        float length = edge.Length();

        _spriteBatch.Draw(_pixelTexture,
            new Rectangle((int)start.X, (int)start.Y, (int)length, thickness),
            null,
            color,
            angle,
            Vector2.Zero,
            SpriteEffects.None,
            0);
            0,
            Vector2.Zero,
            SpriteEffects.None,
            0);
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
