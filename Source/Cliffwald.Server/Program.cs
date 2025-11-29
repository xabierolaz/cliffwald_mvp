using System;
using System.Collections.Generic;
using System.Threading;

namespace Cliffwald.Server;

class Program
{
    // Mock Data Structure for Server
    struct MockBot
    {
        public int Id;
        public float X, Y;
    }

    static void Main(string[] args)
    {
        Console.WriteLine("Server Started... (Simulation Mode)");

        List<MockBot> bots = new List<MockBot>();
        Random rng = new Random();

        // Initialize 5 bots
        for (int i = 0; i < 5; i++)
        {
            bots.Add(new MockBot { Id = i, X = 100 + i * 50, Y = 100 });
        }

        Console.WriteLine("Press 'Q' to quit.");
        bool running = true;

        // Basic loop
        while (running)
        {
            if (Console.KeyAvailable)
            {
                var key = Console.ReadKey(true);
                if (key.Key == ConsoleKey.Q) running = false;
            }

            // Update Bots (Wander)
            for (int i = 0; i < bots.Count; i++)
            {
                var bot = bots[i];
                // Random walk -5 to +5 pixels
                bot.X += rng.Next(-5, 6);
                bot.Y += rng.Next(-5, 6);
                bots[i] = bot; // Struct copy update
            }

            // Print Positions (Simulation Output)
            Console.Clear();
            Console.WriteLine("Server Running. Bots:");
            foreach (var bot in bots)
            {
                Console.WriteLine($"[Bot {bot.Id}] Pos: ({bot.X}, {bot.Y})");
            }

            Thread.Sleep(100);
        }

        Console.WriteLine("Server Stopped.");
    static void Main(string[] args)
    {
        Console.WriteLine("Server Started...");
        Console.WriteLine("Press Enter to exit.");
        Console.ReadLine();
    }
}
