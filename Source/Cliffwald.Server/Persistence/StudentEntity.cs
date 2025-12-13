using SQLite;
using Cliffwald.Shared;
using Microsoft.Xna.Framework;

namespace Cliffwald.Server.Persistence;

public class StudentEntity
{
    [PrimaryKey]
    public int Id { get; set; }

    public Doctrine Doctrine { get; set; }
    public int Year { get; set; }
    public int XP { get; set; }

    // SQLite-net-pcl doesn't store Vector2 natively well unless we serialize it or store X/Y
    public float PositionX { get; set; }
    public float PositionY { get; set; }

    [Ignore]
    public Vector2 Position
    {
        get => new Vector2(PositionX, PositionY);
        set
        {
            PositionX = value.X;
            PositionY = value.Y;
        }
    }
}
