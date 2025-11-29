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

        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        // TODO: use this.Content to load your game content here
    }

    protected override void Update(GameTime gameTime)
    {
        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
            Exit();

        // TODO: Add your update logic here

        base.Update(gameTime);

        // If in render test mode and we've already taken the screenshot, we can exit or just idle.
        // For automated testing, exiting is often useful, but the prompt didn't strictly say "Exit".
        // It just said "SaveScreenshot". We will stick to that.
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.CornflowerBlue);

        // TODO: Add your drawing code here

        base.Draw(gameTime);

        if (_renderTestMode && !_screenshotTaken)
        {
            // We do this at the end of Draw to capture the final frame state
            VisualTester.SaveScreenshot(GraphicsDevice, "init_test.png");
            _screenshotTaken = true;

            // Optional: Print to console for the test runner to see
            Console.WriteLine("Render test complete: init_test.png saved.");
        }
    }
}
