using System;
using System.Threading;
using LiteNetLib;
using LiteNetLib.Utils;
using Cliffwald.Shared.Network;

namespace Cliffwald.Server.Network;

public class ServerNetManager : INetEventListener
{
    private NetManager _netManager;
    private NetPacketProcessor _packetProcessor;
    private int _connectedClients = 0;

    public ServerNetManager()
    {
        _packetProcessor = new NetPacketProcessor();
        _packetProcessor.RegisterNestedType((w, v) => w.Put(v), r => r.GetVector2());

        // Register Callbacks
        _packetProcessor.SubscribeReusable<JoinRequestPacket, NetPeer>(OnJoinRequest);
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
        Console.WriteLine($"[SERVER] Peer connected: {peer.EndPoint}");
        _connectedClients++;
    }

    public void OnPeerDisconnected(NetPeer peer, DisconnectInfo disconnectInfo)
    {
        Console.WriteLine($"[SERVER] Peer disconnected: {peer.EndPoint}");
        _connectedClients--;
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
        Console.WriteLine($"[SERVER] Received Join Request. Protocol: {packet.ProtocolVersion}");

        // Send Accept
        var acceptPacket = new JoinAcceptPacket { PlayerId = peer.Id, SpawnPosition = new Microsoft.Xna.Framework.Vector2(0, 0) };
        _packetProcessor.Send(_netManager, acceptPacket, DeliveryMethod.ReliableOrdered);
    }
}
