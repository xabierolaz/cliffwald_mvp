using Microsoft.Xna.Framework;
using LiteNetLib.Utils;

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

public class StudentData : INetSerializable
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

    public void Serialize(NetDataWriter writer)
    {
        writer.Put(Id);
        writer.Put((int)Doctrine);
        writer.Put(Year);
        writer.Put(Position.X);
        writer.Put(Position.Y);
        writer.Put(TargetPosition.X);
        writer.Put(TargetPosition.Y);
    }

    public void Deserialize(NetDataReader reader)
    {
        Id = reader.GetInt();
        Doctrine = (Doctrine)reader.GetInt();
        Year = reader.GetInt();
        Position = new Vector2(reader.GetFloat(), reader.GetFloat());
        TargetPosition = new Vector2(reader.GetFloat(), reader.GetFloat());
    }
}

public class GameClock
{
    public double ServerTime; // In Seconds

    // Mapping: 1 Real Second = 1 Game Minute (implied or chosen for speed)
    // Prompt says: "Global Clock controls behavior".
    // Let's stick to the previous logic: 120s real time = 24h game time.
    // 5s real = 1h game.

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
