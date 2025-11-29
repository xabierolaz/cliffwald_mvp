using Microsoft.Xna.Framework;

namespace Cliffwald.Shared;

public enum Doctrine
{
    Ignis,
    Axiom,
    Vesper
}

public enum ActivityState
{
    Idle,
    Class,
    Eating,
    Sleeping,
    Walking
}

public class StudentData
{
    public int Id;
    public Doctrine Doctrine;
    public int Year; // 1-4
    public Vector2 Position;
    public Vector2 TargetPosition;

    public Color DoctrineColor
    {
        get
        {
            switch (Doctrine)
            {
                case Doctrine.Ignis: return Color.Red;
                case Doctrine.Axiom: return Color.Blue;
                case Doctrine.Vesper: return Color.Violet;
                default: return Color.White;
            }
        }
    }
}

public class GameClock
{
    public double ServerTime; // In Seconds

    // Mapping: 1 Real Second = 1 Game Minute (implied or chosen for speed)
    // Prompt says: "Global Clock controls behavior".
    // Let's stick to the previous logic: 120s real time = 24h game time.
    // 5s real = 1h game.
    // Assuming a Day Cycle. Let's make 1 Real Minute = 1 Game Hour?
    // Or simpler: 1 Real Second = 1 Game Minute.
    // Day = 24 Hours = 1440 Minutes = 24 Real Seconds.
    // That's very fast.
    // Let's try: Day = 2 Minutes (120 seconds).
    // 120s = 24h. 5s = 1h.

    public int GetGameHour()
    {
        double dayDuration = 120.0; // 2 minutes per day
        double timeOfDay = ServerTime % dayDuration;
        double hour = (timeOfDay / dayDuration) * 24.0;
        return (int)hour;
    }

    public string GetTimeDisplay()
    {
        double dayDuration = 120.0;
        double timeOfDay = ServerTime % dayDuration;
        double hour = (timeOfDay / dayDuration) * 24.0;
        int h = (int)hour;
        int m = (int)((hour - h) * 60);
        return $"{h:D2}:{m:D2}";
    }
}
