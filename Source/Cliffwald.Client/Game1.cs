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
        var args = Environment.GetCommandLineArgs();
        if (args.Contains("--render-test"))
        {
            _renderTestMode = true;
        }

        _populationManager = new PopulationManager();
        _populationManager.Initialize();

        _magicSystem = new MagicSystem();

        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        _pixelTexture = new Texture2D(GraphicsDevice, 1, 1);
        _pixelTexture.SetData(new Color[] { Color.White });
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
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.Black);

        // Center Camera
        var transform = Matrix.CreateTranslation(_graphics.PreferredBackBufferWidth / 2f, _graphics.PreferredBackBufferHeight / 2f, 0);

        _spriteBatch.Begin(transformMatrix: transform);

        // Draw Infinite Grid
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
            Rectangle rect = new Rectangle(
                (int)student.Position.X - 16,
                (int)student.Position.Y - 24,
                32, 48);
            _spriteBatch.Draw(_pixelTexture, rect, student.DoctrineColor);
        }

        _spriteBatch.End();

        // Draw Magic (Screen Space)
        _spriteBatch.Begin();
        if (_magicSystem.Trail.Count > 1)
        {
            for (int i = 0; i < _magicSystem.Trail.Count - 1; i++)
            {
                DrawLine(_magicSystem.Trail[i], _magicSystem.Trail[i+1], Color.White, 2);
            }
        }
        _spriteBatch.End();

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
    }
}
