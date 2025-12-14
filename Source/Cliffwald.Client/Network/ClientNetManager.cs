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
    public event Action<StateUpdatePacket> OnStateReceived;

    public ClientNetManager()
    {
        _packetProcessor = new NetPacketProcessor();

        // Register Vector2
        _packetProcessor.RegisterNestedType<Vector2>(
            (w, v) => { w.Put(v.X); w.Put(v.Y); },
            r => new Vector2(r.GetFloat(), r.GetFloat())
        );

        // Register StudentData
        _packetProcessor.RegisterNestedType<StudentData>(
            (w, s) => {
                w.Put(s.Id);
                w.Put((int)s.Doctrine);
                w.Put(s.Year);
                w.Put(s.Position.X); w.Put(s.Position.Y);
                w.Put(s.TargetPosition.X); w.Put(s.TargetPosition.Y);
            },
            r => new StudentData {
                Id = r.GetInt(),
                Doctrine = (Doctrine)r.GetInt(),
                Year = r.GetInt(),
                Position = new Vector2(r.GetFloat(), r.GetFloat()),
                TargetPosition = new Vector2(r.GetFloat(), r.GetFloat())
            }
        );

        // Subscribe
        _packetProcessor.SubscribeReusable<JoinAcceptPacket>(OnJoinAccept);
        _packetProcessor.SubscribeReusable<StateUpdatePacket>(OnStateUpdate);
    }

    public void Connect(string ip, int port)
    {
        _netManager = new NetManager(this);
        _netManager.Start();
        _netManager.Connect(ip, port, "Cliffwald");
        Console.WriteLine($"[CLIENT] Connecting to {ip}:{port}...");
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
        var packet = new JoinRequestPacket { ProtocolVersion = 1 };
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
        // Here we would set the LocalPlayer ID
    }

    private void OnStateUpdate(StateUpdatePacket packet)
    {
        OnStateReceived?.Invoke(packet);
    }
}
