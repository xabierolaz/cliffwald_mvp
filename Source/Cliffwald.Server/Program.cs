using System;
using System.Threading;
using Cliffwald.Server.Network;
using Cliffwald.Server.Data;

namespace Cliffwald.Server;

class Program
{
    static void Main(string[] args)
    {
        Console.WriteLine("Cliffwald Server Starting...");

        // Initialize Database
        var dbManager = new DatabaseManager();
        dbManager.Initialize();

        // Initialize Networking
        var netManager = new ServerNetManager();
        netManager.Start(9050);

        Console.WriteLine("Server Running. Press 'Q' to quit.");

        // Game Loop
        bool running = true;
        while (running)
        {
            if (Console.KeyAvailable)
            {
                var key = Console.ReadKey(true);
                if (key.Key == ConsoleKey.Q) running = false;
            }

            netManager.Update();

            // Simulation Logic would go here
            // e.g., Update Students in DB every few minutes

            Thread.Sleep(15); // ~60 FPS
        }

        netManager.Stop();
        Console.WriteLine("Server Stopped.");
    }
}
