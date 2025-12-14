using System;
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
    private readonly NetDataWriter _writer = new NetDataWriter();
    private int _connectedClients = 0;

    public PopulationManager Population { get; private set; }
    private DatabaseManager _db;
    private int _tick;

    public ServerNetManager()
    {
        _packetProcessor = new NetPacketProcessor();

        // Register Vector2 (Manual serialization to be safe across platforms)
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

        _packetProcessor.SubscribeReusable<JoinRequestPacket, NetPeer>(OnJoinRequest);

        Population = new PopulationManager();
        _db = new DatabaseManager();
    }

    public void Start(int port)
    {
        _db.Initialize();
        var loaded = _db.LoadStudents();
        if (loaded != null) {
            Population.Students = loaded;
            Console.WriteLine($"[SERVER] Loaded {loaded.Count} students from DB.");
        } else {
            Population.Initialize();
            _db.SaveStudents(Population.Students);
            Console.WriteLine("[SERVER] Generated new population.");
        }

        _netManager = new NetManager(this);
        _netManager.Start(port);
        Console.WriteLine($"[SERVER] Listening on port {port}");
    }

    public void Update()
    {
        _netManager.PollEvents();

        // Simulation Update (Fixed step approx)
        float dt = 0.016f;
        Population.Update(dt);

        // Broadcast State
        _tick++;
        var packet = new StateUpdatePacket {
            Tick = _tick,
            Students = Population.Students.ToArray()
        };

        _writer.Reset();
        _packetProcessor.Write(_writer, packet);
        _netManager.SendToAll(_writer, DeliveryMethod.Sequenced);
    }

    public void Stop()
    {
        _db.SaveStudents(Population.Students);
        Console.WriteLine("[SERVER] Saved population.");
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

        var acceptPacket = new JoinAcceptPacket { PlayerId = peer.Id, SpawnPosition = new Vector2(0, 0) };

        _writer.Reset();
        _packetProcessor.Write(_writer, acceptPacket);
        peer.Send(_writer, DeliveryMethod.ReliableOrdered);
    }
}
