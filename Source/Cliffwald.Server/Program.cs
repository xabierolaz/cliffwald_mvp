using System;
using System.Threading;
using Cliffwald.Server.Network;

namespace Cliffwald.Server;

class Program
{
    static void Main(string[] args)
    {
        Console.WriteLine("Cliffwald Server Starting...");

        // Initialize Database
        var dbManager = new Cliffwald.Server.Persistence.DatabaseManager();
        dbManager.Initialize();

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

            Thread.Sleep(15); // ~60 FPS
        }

        netManager.Stop();
        Console.WriteLine("Server Stopped.");
    }
}
