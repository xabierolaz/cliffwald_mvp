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
public struct JoinRequestPacket
{
    public int ProtocolVersion;
}

public struct JoinAcceptPacket
{
    public int PlayerId;
    public Vector2 SpawnPosition;
}

public struct StateUpdatePacket
{
    public int Tick;
    // We would have a list of entities here
}
