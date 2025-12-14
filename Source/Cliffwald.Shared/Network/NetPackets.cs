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

public class JoinRequestPacket
{
    public int ProtocolVersion;
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
}
