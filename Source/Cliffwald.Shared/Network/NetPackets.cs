using System;
using Microsoft.Xna.Framework;

namespace Cliffwald.Shared.Network;

public enum PacketType : byte
{
    JoinRequest,
    JoinAccept,
    StateUpdate
}

public struct PacketHeader
{
    public PacketType Type;
}

// Simple struct wrappers for serialization (LiteNetLib handles basic types well)
// In a real scenario we'd use INetSerializable or similar
public class JoinRequestPacket
{
    public int ProtocolVersion;
    public Doctrine Doctrine;
}

public class ClientStatePacket
{
    public Vector2 Position;
    public Vector2 Velocity;
    public bool IsMoving;
    public int Direction;
}

public class JoinAcceptPacket
{
    public int PlayerId;
    public Vector2 SpawnPosition;
}

public class StateUpdatePacket
{
    public int Tick;
    public StudentData[] Students;
    public PlayerState[] Players;
}
