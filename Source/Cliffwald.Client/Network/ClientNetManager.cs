using System;
using LiteNetLib;
using LiteNetLib.Utils;
using Cliffwald.Shared;
using Cliffwald.Shared.Network;
using Microsoft.Xna.Framework;

namespace Cliffwald.Client.Network;

public class ClientNetManager : INetEventListener
{
    private NetManager _netManager;
    private NetPacketProcessor _packetProcessor;
    private NetPeer _serverPeer;
    private readonly NetDataWriter _writer = new NetDataWriter();
    public bool IsConnected => _serverPeer != null && _serverPeer.ConnectionState == ConnectionState.Connected;

    public ClientNetManager()
    {
        _packetProcessor = new NetPacketProcessor();
        _packetProcessor.RegisterNestedType<Vector2>((w, v) => w.Put(v), r => r.GetVector2());
        // StudentData is a class implementing INetSerializable, so we don't register it as nested struct
        _packetProcessor.RegisterNestedType<PlayerState>();

        // Subscribe
        _packetProcessor.SubscribeReusable<JoinAcceptPacket>(OnJoinAccept);
        _packetProcessor.SubscribeReusable<StateUpdatePacket>(OnStateUpdatePacket);
    }

    public event Action<StateUpdatePacket> OnStateReceived;
    public event Action<int> OnJoinAccepted;

    private void OnStateUpdatePacket(StateUpdatePacket packet)
    {
        OnStateReceived?.Invoke(packet);
    }

    private Doctrine _pendingDoctrine;

    public void Connect(string ip, int port, Doctrine doctrine)
    {
        _pendingDoctrine = doctrine;
        _netManager = new NetManager(this);
        _netManager.Start();
        _netManager.Connect(ip, port, "Cliffwald");
        Console.WriteLine($"[CLIENT] Connecting to {ip}:{port}...");
    }

    public void SendClientState(ClientStatePacket packet)
    {
        if (_serverPeer != null)
        {
             _writer.Reset();
             _packetProcessor.Write(_writer, packet);
             _serverPeer.Send(_writer, DeliveryMethod.Sequenced);
        }
    }

    public void Update()
    {
        _netManager?.PollEvents();
    }

    public void Disconnect()
    {
        _netManager?.Stop();
    }

    // --- INetEventListener ---

    public void OnPeerConnected(NetPeer peer)
    {
        Console.WriteLine("[CLIENT] Connected to server!");
        _serverPeer = peer;

        // Send Join Request
        var packet = new JoinRequestPacket { ProtocolVersion = 1, Doctrine = _pendingDoctrine };
        _writer.Reset();
        _packetProcessor.Write(_writer, packet);
        _serverPeer.Send(_writer, DeliveryMethod.ReliableOrdered);
    }

    public void OnPeerDisconnected(NetPeer peer, DisconnectInfo disconnectInfo)
    {
        Console.WriteLine($"[CLIENT] Disconnected: {disconnectInfo.Reason}");
        _serverPeer = null;
    }

    public void OnNetworkError(System.Net.IPEndPoint endPoint, System.Net.Sockets.SocketError socketError)
    {
        Console.WriteLine($"[CLIENT] Network Error: {socketError}");
    }

    public void OnNetworkReceive(NetPeer peer, NetPacketReader reader, byte channelNumber, DeliveryMethod deliveryMethod)
    {
        _packetProcessor.ReadAllPackets(reader);
    }

    public void OnNetworkReceiveUnconnected(System.Net.IPEndPoint remoteEndPoint, NetPacketReader reader, UnconnectedMessageType messageType) { }

    public void OnNetworkLatencyUpdate(NetPeer peer, int latency) { }

    public void OnConnectionRequest(ConnectionRequest request) { }

    // --- Handlers ---

    private void OnJoinAccept(JoinAcceptPacket packet)
    {
        Console.WriteLine($"[CLIENT] Join Accepted! Assigned ID: {packet.PlayerId}");
        OnJoinAccepted?.Invoke(packet.PlayerId);
    }
}
