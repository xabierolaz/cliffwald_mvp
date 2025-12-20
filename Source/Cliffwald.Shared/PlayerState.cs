using Microsoft.Xna.Framework;
using LiteNetLib.Utils;
using Cliffwald.Shared.Network;

namespace Cliffwald.Shared;

public struct PlayerState : INetSerializable
{
    public int Id;
    public Vector2 Position;
    public Vector2 Velocity;
    public bool IsMoving;
    /// <summary>
    /// 0=Down, 1=Right, 2=Up, 3=Left
    /// </summary>
    public int Direction;
    public Doctrine Doctrine;

    public void Serialize(NetDataWriter writer)
    {
        writer.Put(Id);
        writer.Put(Position);
        writer.Put(Velocity);
        writer.Put(IsMoving);
        writer.Put(Direction);
        writer.Put((int)Doctrine);
    }

    public void Deserialize(NetDataReader reader)
    {
        Id = reader.GetInt();
        Position = reader.GetVector2();
        Velocity = reader.GetVector2();
        IsMoving = reader.GetBool();
        Direction = reader.GetInt();
        Doctrine = (Doctrine)reader.GetInt();
    }
}
