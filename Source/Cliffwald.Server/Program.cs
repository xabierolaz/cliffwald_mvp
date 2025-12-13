using System;
using System.Threading;
using System.Collections.Generic;
using Cliffwald.Server.Network;
using Cliffwald.Server.Data;
using Cliffwald.Shared;
using Cliffwald.Shared.Network;

namespace Cliffwald.Server;

class Program
{
    static void Main(string[] args)
    {
        Console.WriteLine("Cliffwald Server Starting...");

        // 1. Database
        var dbManager = new DatabaseManager();
        var students = dbManager.LoadStudents();

        // 2. Simulation
        var populationManager = new PopulationManager();
        if (students != null && students.Count > 0)
        {
            Console.WriteLine($"[SERVER] Loaded {students.Count} students from DB.");
            populationManager.Students = students;
        }
        else
        {
            Console.WriteLine("[SERVER] No students in DB. Initializing fresh world.");
            populationManager.Initialize();
        }

        // 3. Network
        var netManager = new ServerNetManager();
        netManager.Start(9050);

        Console.WriteLine("Server Running. Press 'Q' to quit.");

        // Game Loop
        bool running = true;
        int tick = 0;

        while (running)
        {
            if (Console.KeyAvailable)
            {
                var key = Console.ReadKey(true);
                if (key.Key == ConsoleKey.Q) running = false;
            }

            netManager.Update();

            // Fixed time step for simulation (simplified)
            float deltaTime = 0.016f;
            populationManager.Update(deltaTime);

            // Broadcast state every tick
            var packet = new StateUpdatePacket
            {
                Tick = tick++,
                Students = populationManager.Students.ToArray()
            };
            netManager.BroadcastState(packet);

            Thread.Sleep(15); // ~60 FPS
        }

        // Save on exit
        Console.WriteLine("[SERVER] Saving World...");
        dbManager.SaveStudents(populationManager.Students);

        netManager.Stop();
        Console.WriteLine("Server Stopped.");
    }
}
