using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using System.Linq;

namespace Cliffwald.Client.Magic;

/// <summary>
/// Implements the $1 Unistroke Recognizer algorithm.
/// Reference: http://depts.washington.edu/madlab/proj/dollar/
/// </summary>
public class GestureRecognizer
{
    private const int NumPoints = 64;
    private const float SquareSize = 250.0f;
    private const float Diagonal = 353.55f; // sqrt(250^2 + 250^2)
    private const float HalfDiagonal = 0.5f * Diagonal;
    private static readonly float AngleRange = MathHelper.ToRadians(45.0f);
    private static readonly float AnglePrecision = MathHelper.ToRadians(2.0f);
    private const float Phi = 0.5f * (-1.0f + 2.236067977f); // (sqrt(5) - 1) / 2

    private List<Template> _templates = new List<Template>();

    public GestureRecognizer()
    {
        // Define Templates
        // Line (Horizontal-ish)
        AddTemplate("Line", new List<Vector2> { new Vector2(0, 0), new Vector2(1, 0) });

        // Square
        AddTemplate("Square", new List<Vector2>
        {
            new Vector2(0,0), new Vector2(1,0), new Vector2(1,1), new Vector2(0,1), new Vector2(0,0)
        });

        // Triangle
        AddTemplate("Triangle", new List<Vector2>
        {
            new Vector2(0,1), new Vector2(0.5f, 0), new Vector2(1,1), new Vector2(0,1)
        });

        // Circle (Approximate with points)
        List<Vector2> circlePoints = new List<Vector2>();
        for (int i = 0; i <= 32; i++)
        {
            float angle = i * MathHelper.TwoPi / 32;
            circlePoints.Add(new Vector2((float)Math.Cos(angle), (float)Math.Sin(angle)));
        }
        AddTemplate("Circle", circlePoints);
    }

    public string Recognize(List<Vector2> points)
    {
        if (points.Count < 5) return "Unknown";

        var candidate = new Template("Candidate", points);

        float bestDistance = float.MaxValue;
        string bestTemplate = "Unknown";

        foreach (var template in _templates)
        {
            float distance = DistanceAtBestAngle(candidate.Points, template, -AngleRange, AngleRange, AnglePrecision);
            if (distance < bestDistance)
            {
                bestDistance = distance;
                bestTemplate = template.Name;
            }
        }

        // Score can be calculated as 1 - (bestDistance / HalfDiagonal)
        float score = 1.0f - (bestDistance / HalfDiagonal);

        // Threshold
        if (score < 0.75f) return "Unknown";

        return bestTemplate;
    }

    private void AddTemplate(string name, List<Vector2> points)
    {
        _templates.Add(new Template(name, points));
    }

    // --- Helper Classes & Methods ---

    private class Template
    {
        public string Name;
        public Vector2[] Points;

        public Template(string name, List<Vector2> points)
        {
            Name = name;
            Points = Normalize(points);
        }
    }

    private static Vector2[] Normalize(List<Vector2> points)
    {
        var resampled = Resample(points, NumPoints);
        var rotated = RotateToZero(resampled);
        var scaled = ScaleToSquare(rotated, SquareSize);
        var translated = TranslateToOrigin(scaled);
        return translated;
    }

    private static Vector2[] Resample(List<Vector2> points, int n)
    {
        // Clone the list to avoid modifying the caller's data
        points = new List<Vector2>(points);

        float I = PathLength(points) / (n - 1);
        float D = 0;

        List<Vector2> newPoints = new List<Vector2> { points[0] };

        for (int i = 1; i < points.Count; i++)
        {
            float d = Vector2.Distance(points[i - 1], points[i]);
            if (D + d >= I)
            {
                float qx = points[i - 1].X + ((I - D) / d) * (points[i].X - points[i - 1].X);
                float qy = points[i - 1].Y + ((I - D) / d) * (points[i].Y - points[i - 1].Y);
                Vector2 q = new Vector2(qx, qy);
                newPoints.Add(q);
                points.Insert(i, q);
                D = 0;
            }
            else
            {
                D += d;
            }
        }

        if (newPoints.Count == n - 1)
        {
            newPoints.Add(points.Last());
        }

        return newPoints.ToArray();
    }

    private static Vector2[] RotateToZero(Vector2[] points)
    {
        Vector2 c = Centroid(points);
        float theta = (float)Math.Atan2(points[0].Y - c.Y, points[0].X - c.X);
        return RotateBy(points, -theta);
    }

    private static Vector2[] RotateBy(Vector2[] points, float theta)
    {
        Vector2 c = Centroid(points);
        Vector2[] newPoints = new Vector2[points.Length];
        float cos = (float)Math.Cos(theta);
        float sin = (float)Math.Sin(theta);

        for (int i = 0; i < points.Length; i++)
        {
            float qx = (points[i].X - c.X) * cos - (points[i].Y - c.Y) * sin + c.X;
            float qy = (points[i].X - c.X) * sin + (points[i].Y - c.Y) * cos + c.Y;
            newPoints[i] = new Vector2(qx, qy);
        }
        return newPoints;
    }

    private static Vector2[] ScaleToSquare(Vector2[] points, float size)
    {
        BoundingBox(points, out float minX, out float maxX, out float minY, out float maxY);
        float width = maxX - minX;
        float height = maxY - minY;

        Vector2[] newPoints = new Vector2[points.Length];
        for (int i = 0; i < points.Length; i++)
        {
            float qx = points[i].X * (size / width);
            float qy = points[i].Y * (size / height);
            newPoints[i] = new Vector2(qx, qy);
        }
        return newPoints;
    }

    private static Vector2[] TranslateToOrigin(Vector2[] points)
    {
        Vector2 c = Centroid(points);
        Vector2[] newPoints = new Vector2[points.Length];
        for (int i = 0; i < points.Length; i++)
        {
            newPoints[i] = new Vector2(points[i].X - c.X, points[i].Y - c.Y);
        }
        return newPoints;
    }

    private static float DistanceAtBestAngle(Vector2[] points, Template T, float thetaA, float thetaB, float thetaDelta)
    {
        float x1 = Phi * thetaA + (1 - Phi) * thetaB;
        float f1 = DistanceAtAngle(points, T, x1);
        float x2 = (1 - Phi) * thetaA + Phi * thetaB;
        float f2 = DistanceAtAngle(points, T, x2);

        while (Math.Abs(thetaB - thetaA) > thetaDelta)
        {
            if (f1 < f2)
            {
                thetaB = x2;
                x2 = x1;
                f2 = f1;
                x1 = Phi * thetaA + (1 - Phi) * thetaB;
                f1 = DistanceAtAngle(points, T, x1);
            }
            else
            {
                thetaA = x1;
                x1 = x2;
                f1 = f2;
                x2 = (1 - Phi) * thetaA + Phi * thetaB;
                f2 = DistanceAtAngle(points, T, x2);
            }
        }
        return Math.Min(f1, f2);
    }

    private static float DistanceAtAngle(Vector2[] points, Template T, float theta)
    {
        var newPoints = RotateBy(points, theta);
        return PathDistance(newPoints, T.Points);
    }

    private static float PathDistance(Vector2[] pts1, Vector2[] pts2)
    {
        float d = 0;
        for (int i = 0; i < pts1.Length; i++)
        {
            d += Vector2.Distance(pts1[i], pts2[i]);
        }
        return d / pts1.Length;
    }

    private static float PathLength(List<Vector2> points)
    {
        float d = 0;
        for (int i = 1; i < points.Count; i++)
            d += Vector2.Distance(points[i - 1], points[i]);
        return d;
    }

    private static Vector2 Centroid(Vector2[] points)
    {
        float x = 0, y = 0;
        foreach (var p in points)
        {
            x += p.X;
            y += p.Y;
        }
        return new Vector2(x / points.Length, y / points.Length);
    }

    private static void BoundingBox(Vector2[] points, out float minX, out float maxX, out float minY, out float maxY)
    {
        minX = float.MaxValue;
        maxX = float.MinValue;
        minY = float.MaxValue;
        maxY = float.MinValue;

        foreach (var p in points)
        {
            if (p.X < minX) minX = p.X;
            if (p.X > maxX) maxX = p.X;
            if (p.Y < minY) minY = p.Y;
            if (p.Y > maxY) maxY = p.Y;
        }
    }
}
