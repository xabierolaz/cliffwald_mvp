using System;
using Microsoft.Xna.Framework;

namespace Cliffwald.Shared.AI
{
    public class GridMap
    {
        public const int Width = 100;
        public const int Height = 100;
        public const int TileSize = 32;

        private bool[,] _walkable;

        public GridMap()
        {
            _walkable = new bool[Width, Height];

            // Initialize all as walkable by default
            for (int x = 0; x < Width; x++)
            {
                for (int y = 0; y < Height; y++)
                {
                    _walkable[x, y] = true;
                }
            }
        }

        public bool IsWalkable(int x, int y)
        {
            if (x < 0 || x >= Width || y < 0 || y >= Height)
                return false;
            return _walkable[x, y];
        }

        public void SetWalkable(int x, int y, bool value)
        {
             if (x >= 0 && x < Width && y >= 0 && y < Height)
                _walkable[x, y] = value;
        }

        public Point WorldToGrid(Vector2 worldPos)
        {
            float x = (worldPos.X + (Width * TileSize) / 2f) / TileSize;
            float y = (worldPos.Y + (Height * TileSize) / 2f) / TileSize;
            return new Point((int)Math.Floor(x), (int)Math.Floor(y));
        }

        public Vector2 GridToWorld(Point gridPos)
        {
             float x = (gridPos.X * TileSize) - (Width * TileSize) / 2f + TileSize / 2f;
             float y = (gridPos.Y * TileSize) - (Height * TileSize) / 2f + TileSize / 2f;
             return new Vector2(x, y);
        }
    }
}
