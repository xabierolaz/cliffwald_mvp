using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Linq;
using Cliffwald.Client.Utils;
using Cliffwald.Client.Input;
using Cliffwald.Shared;
using Cliffwald.Client.Scenes;
using Cliffwald.Client.Magic;
using Cliffwald.Client.Network; // Added

using Color = Microsoft.Xna.Framework.Color;
using Rectangle = Microsoft.Xna.Framework.Rectangle;

namespace Cliffwald.Client;

public enum GameState
{
    CharacterCreator,
    Playing
}

public class Game1 : Game
{
    private GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch;
    private bool _renderTestMode;
    private bool _snapshotTaken;

    private PopulationManager _populationManager;
    private MagicSystem _magicSystem;
    private CharacterCreator _characterCreator;
    private List<Projectile> _projectiles;

    private ClientNetManager _netManager; // Added

    private Texture2D _pixelTexture;
    private GameState _currentState = GameState.CharacterCreator;
    private Color _playerColor = Color.White;

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
        if (args.Contains("--snapshot") || args.Contains("--render-test"))
        {
            _renderTestMode = true;
        }

        _populationManager = new PopulationManager();
        // We don't need to Initialize locally as we expect server data,
        // but initializing avoids null reference before first packet.
        _populationManager.Initialize();

        _magicSystem = new MagicSystem();
        _magicSystem.OnSpellCast += HandleSpellCast;

        _characterCreator = new CharacterCreator(_graphics.PreferredBackBufferWidth, _graphics.PreferredBackBufferHeight);
        _projectiles = new List<Projectile>();

        // Initialize Networking
        _netManager = new ClientNetManager();
        _netManager.OnStateReceived += (packet) =>
        {
            if (_populationManager != null && packet.Students != null)
            {
                _populationManager.Students = packet.Students.ToList();
            }
        };

        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        _pixelTexture = new Texture2D(GraphicsDevice, 1, 1);
        _pixelTexture.SetData(new Color[] { Color.White });
    }

    private void HandleSpellCast(string spellName, Vector2 start, Vector2 end, Vector2 center)
    {
        Vector2 offset = new Vector2(_graphics.PreferredBackBufferWidth / 2f, _graphics.PreferredBackBufferHeight / 2f);

        if (spellName == "Force Push")
        {
            Vector2 direction = end - start;
            if (direction != Vector2.Zero) direction.Normalize();
            _projectiles.Add(new Projectile(Vector2.Zero, direction * 500f, _playerColor, 1.0f));
            Console.WriteLine($"[CAST] {spellName} -> Dir: {direction}");
        }
        else if (spellName == "Fireball")
        {
            Vector2 worldPos = center - offset;
            _projectiles.Add(new Projectile(worldPos, Vector2.Zero, Color.Orange, 5.0f));
            Console.WriteLine($"[CAST] {spellName} -> At: {worldPos}");
        }
    }

    protected override void Update(GameTime gameTime)
    {
        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
            Exit();

        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;

        // Update Networking
        _netManager.Update();

        if (_currentState == GameState.CharacterCreator)
        {
            _characterCreator.Update();
            if (_characterCreator.IsComplete)
            {
                switch (_characterCreator.SelectedDoctrine)
                {
                    case Doctrine.Ignis: _playerColor = Color.Red; break;
                    case Doctrine.Axiom: _playerColor = Color.Blue; break;
                    case Doctrine.Vesper: _playerColor = Color.Violet; break;
                }
                _currentState = GameState.Playing;

                // Connect to Server when starting play
                _netManager.Connect("localhost", 9050);
            }
        }
        else if (_currentState == GameState.Playing)
        {
            // _populationManager.Update(dt); // REMOVED: Managed by Server

            _magicSystem.Update();

            for (int i = _projectiles.Count - 1; i >= 0; i--)
            {
                _projectiles[i].Update(dt);
                if (!_projectiles[i].IsActive) _projectiles.RemoveAt(i);
            }
        }

        Window.Title = $"Cliffwald [{_currentState}] | Spells: {_magicSystem.LastSpell} | Connected: {_netManager.IsConnected}";

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.Black);

        if (_currentState == GameState.CharacterCreator)
        {
            _characterCreator.Draw(_spriteBatch, _pixelTexture);

            if (_renderTestMode && !_snapshotTaken)
            {
                VisualTester.SaveScreenshot(GraphicsDevice, "character_creator_snapshot.png");
                _snapshotTaken = true;
                Console.WriteLine("Snapshot taken: character_creator_snapshot.png");
            }
        }
        else if (_currentState == GameState.Playing)
        {
            var transform = Matrix.CreateTranslation(_graphics.PreferredBackBufferWidth / 2f, _graphics.PreferredBackBufferHeight / 2f, 0);

            _spriteBatch.Begin(transformMatrix: transform);

            int gridSize = 1000;
            int spacing = 100;
            Color gridColor = Color.DarkGray * 0.5f;
            for (int x = -gridSize; x <= gridSize; x += spacing)
                DrawLine(new Vector2(x, -gridSize), new Vector2(x, gridSize), gridColor);
            for (int y = -gridSize; y <= gridSize; y += spacing)
                DrawLine(new Vector2(-gridSize, y), new Vector2(gridSize, y), gridColor);

            // Population (From Server)
            foreach (var student in _populationManager.Students)
            {
                Rectangle rect = new Rectangle((int)student.Position.X - 16, (int)student.Position.Y - 24, 32, 48);
                _spriteBatch.Draw(_pixelTexture, rect, student.DoctrineColor);
            }

            Rectangle playerRect = new Rectangle(-16, -24, 32, 48);
            _spriteBatch.Draw(_pixelTexture, playerRect, _playerColor);

            foreach (var proj in _projectiles)
            {
                int size = (int)(8 * proj.Scale);
                int offset = size / 2;
                _spriteBatch.Draw(_pixelTexture, new Rectangle((int)proj.Position.X - offset, (int)proj.Position.Y - offset, size, size), proj.Color);
            }

            _spriteBatch.End();

            _spriteBatch.Begin();
            if (_magicSystem.Trail.Count > 1)
            {
                for (int i = 0; i < _magicSystem.Trail.Count - 1; i++)
                {
                    DrawLine(_magicSystem.Trail[i], _magicSystem.Trail[i+1], Color.White, 2);
                }
            }
            _spriteBatch.End();
        }

        base.Draw(gameTime);
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
