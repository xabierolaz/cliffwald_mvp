using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using LiteNetLib;
using LiteNetLib.Utils;
using Cliffwald.Shared;
using Cliffwald.Shared.Network;
using Microsoft.Xna.Framework;

namespace Cliffwald.Server.Network;

public class ServerNetManager : INetEventListener
{
    private NetManager _netManager;
    private NetPacketProcessor _packetProcessor;
    private int _connectedClients = 0;
    private readonly NetDataWriter _writer = new NetDataWriter();

    // Store connected players
    public Dictionary<int, PlayerState> Players = new Dictionary<int, PlayerState>();

    public ServerNetManager()
    {
        _packetProcessor = new NetPacketProcessor();
        _packetProcessor.RegisterNestedType((w, v) => { w.Put(v.X); w.Put(v.Y); }, r => new Vector2(r.GetFloat(), r.GetFloat()));
        _packetProcessor.RegisterNestedType<StudentData>(() => new StudentData());
        _packetProcessor.RegisterNestedType<PlayerState>();

        // Register Callbacks
        _packetProcessor.SubscribeReusable<JoinRequestPacket, NetPeer>(OnJoinRequest);
        _packetProcessor.SubscribeReusable<ClientStatePacket, NetPeer>(OnClientState);
    }

    public void BroadcastState(StateUpdatePacket packet)
    {
        // Add players to packet before sending
        packet.Players = Players.Values.ToArray();
        _writer.Reset();
        _packetProcessor.Write(_writer, packet);
        _netManager.SendToAll(_writer, DeliveryMethod.Sequenced);
    }

    public void Start(int port)
    {
        _netManager = new NetManager(this);
        _netManager.Start(port);
        Console.WriteLine($"[SERVER] Listening on port {port}");
    }

    public void Update()
    {
        _netManager.PollEvents();
    }

    public void Stop()
    {
        _netManager.Stop();
    }

    // --- INetEventListener Implementation ---

    public void OnConnectionRequest(ConnectionRequest request)
    {
        if (_netManager.ConnectedPeersCount < 100)
            request.AcceptIfKey("Cliffwald");
        else
            request.Reject();
    }

    public void OnPeerConnected(NetPeer peer)
    {
        Console.WriteLine($"[SERVER] Peer connected: {peer.EndPoint} (ID: {peer.Id})");
        _connectedClients++;
        // Initialize player state (default)
        if (!Players.ContainsKey(peer.Id))
        {
             Players[peer.Id] = new PlayerState { Id = peer.Id, Position = Vector2.Zero };
        }
    }

    public void OnPeerDisconnected(NetPeer peer, DisconnectInfo disconnectInfo)
    {
        Console.WriteLine($"[SERVER] Peer disconnected: {peer.EndPoint}");
        _connectedClients--;
        if (Players.ContainsKey(peer.Id))
        {
            Players.Remove(peer.Id);
        }
    }

    public void OnNetworkError(System.Net.IPEndPoint endPoint, System.Net.Sockets.SocketError socketError)
    {
        Console.WriteLine($"[SERVER] Network Error: {socketError}");
    }

    public void OnNetworkReceive(NetPeer peer, NetPacketReader reader, byte channelNumber, DeliveryMethod deliveryMethod)
    {
        _packetProcessor.ReadAllPackets(reader, peer);
    }

    public void OnNetworkReceiveUnconnected(System.Net.IPEndPoint remoteEndPoint, NetPacketReader reader, UnconnectedMessageType messageType) { }

    public void OnNetworkLatencyUpdate(NetPeer peer, int latency) { }

    // --- Packet Handlers ---

    private void OnJoinRequest(JoinRequestPacket packet, NetPeer peer)
    {
        Console.WriteLine($"[SERVER] Received Join Request (v{packet.ProtocolVersion}) from {peer.Id}. Doctrine: {packet.Doctrine}");

        // Update Doctrine
        if (Players.ContainsKey(peer.Id))
        {
            var p = Players[peer.Id];
            p.Doctrine = packet.Doctrine;
            Players[peer.Id] = p;
        }
        else
        {
             Players[peer.Id] = new PlayerState { Id = peer.Id, Position = Vector2.Zero, Doctrine = packet.Doctrine };
        }

        // Send Accept
        var acceptPacket = new JoinAcceptPacket { PlayerId = peer.Id, SpawnPosition = new Vector2(0, 0) };
        _writer.Reset();
        _packetProcessor.Write(_writer, acceptPacket);
        peer.Send(_writer, DeliveryMethod.ReliableOrdered);
    }

    private void OnClientState(ClientStatePacket packet, NetPeer peer)
    {
        if (Players.ContainsKey(peer.Id))
        {
            var p = Players[peer.Id];
            p.Position = packet.Position;
            p.Velocity = packet.Velocity;
            p.IsMoving = packet.IsMoving;
            p.Direction = packet.Direction;
            Players[peer.Id] = p;
        }
    }
}
