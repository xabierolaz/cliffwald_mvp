using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace Cliffwald.Shared.AI
{
    public class Pathfinder
    {
        private GridMap _grid;

        public Pathfinder(GridMap grid)
        {
            _grid = grid;
        }

        public List<Vector2> FindPath(Vector2 startWorld, Vector2 endWorld)
        {
            Point start = _grid.WorldToGrid(startWorld);
            Point end = _grid.WorldToGrid(endWorld);

            if (!_grid.IsWalkable(start.X, start.Y) || !_grid.IsWalkable(end.X, end.Y))
                return null;

            var openSet = new List<Node>();
            var closedSet = new HashSet<Point>();

            var startNode = new Node(start, null, 0, GetDistance(start, end));
            openSet.Add(startNode);

            while (openSet.Count > 0)
            {
                // Get node with lowest F cost
                openSet.Sort((a, b) => a.F.CompareTo(b.F));
                Node current = openSet[0];
                openSet.RemoveAt(0);

                if (current.Position == end)
                {
                    return RetracePath(current);
                }

                closedSet.Add(current.Position);

                foreach (Point neighborPos in GetNeighbors(current.Position))
                {
                    if (closedSet.Contains(neighborPos) || !_grid.IsWalkable(neighborPos.X, neighborPos.Y))
                        continue;

                    float newMovementCostToNeighbor = current.G + GetDistance(current.Position, neighborPos);

                    Node neighborNode = openSet.Find(n => n.Position == neighborPos);

                    if (neighborNode == null || newMovementCostToNeighbor < neighborNode.G)
                    {
                        if (neighborNode == null)
                        {
                            neighborNode = new Node(neighborPos, current, newMovementCostToNeighbor, GetDistance(neighborPos, end));
                            openSet.Add(neighborNode);
                        }
                        else
                        {
                            neighborNode.Parent = current;
                            neighborNode.G = newMovementCostToNeighbor;
                            neighborNode.H = GetDistance(neighborPos, end);
                        }
                    }
                }
            }

            return null; // No path found
        }

        private List<Vector2> RetracePath(Node endNode)
        {
            List<Vector2> path = new List<Vector2>();
            Node currentNode = endNode;

            while (currentNode != null)
            {
                path.Add(_grid.GridToWorld(currentNode.Position));
                currentNode = currentNode.Parent;
            }

            path.Reverse();
            return path;
        }

        private float GetDistance(Point a, Point b)
        {
            float dstX = Math.Abs(a.X - b.X);
            float dstY = Math.Abs(a.Y - b.Y);
            return (float)Math.Sqrt(dstX * dstX + dstY * dstY);
        }

        private List<Point> GetNeighbors(Point p)
        {
            var neighbors = new List<Point>();

            if (p.X > 0) neighbors.Add(new Point(p.X - 1, p.Y));
            if (p.X < GridMap.Width - 1) neighbors.Add(new Point(p.X + 1, p.Y));
            if (p.Y > 0) neighbors.Add(new Point(p.X, p.Y - 1));
            if (p.Y < GridMap.Height - 1) neighbors.Add(new Point(p.X, p.Y + 1));

            return neighbors;
        }

        private class Node
        {
            public Point Position;
            public Node Parent;
            public float G; // Cost from start
            public float H; // Heuristic to end
            public float F => G + H;

            public Node(Point pos, Node parent, float g, float h)
            {
                Position = pos;
                Parent = parent;
                G = g;
                H = h;
            }
        }
    }
}
