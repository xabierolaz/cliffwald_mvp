using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace Cliffwald.Shared;

public class PopulationManager
{
    public List<StudentData> Students = new List<StudentData>();
    public GameClock Clock = new GameClock();

    public void Initialize()
    {
        Students.Clear();
        // Generate 84 Students
        for (int i = 0; i < 84; i++)
        {
            var s = new StudentData();
            s.Id = i;
            s.Doctrine = (Doctrine)(i % 3);
            s.Year = (i / 21) + 1; // 0-20=Year1, 21-41=Year2, ...

            // Random start position around center
            s.Position = new Vector2((i % 10) * 10 - 50, (i / 10) * 10 - 50);
            s.TargetPosition = s.Position;

            Students.Add(s);
        }
    }

    public void Update(float deltaTime)
    {
        Clock.ServerTime += deltaTime;
        int hour = Clock.GetGameHour();

        foreach (var student in Students)
        {
            // Scheduler Logic
            // If Hour 08-09 (Breakfast): Target = GreatHall (0, -300).
            if (hour >= 8 && hour < 9)
            {
                student.TargetPosition = new Vector2(0, -300);
            }
            // If Hour 09-13 (Classes): Target = Classrooms (Spread X based on Year)
            else if (hour >= 9 && hour < 13)
            {
                // Year 1 = -400, Year 4 = 400.
                // Map 1->-400, 4->400.
                // Range 800. Steps: -400, -133, 133, 400.
                float x = -400 + (student.Year - 1) * (800f / 3f);
                student.TargetPosition = new Vector2(x, -100); // Assume classrooms at Y=-100
            }
            // If Hour 22-06 (Sleep): Target = Dorms
            // Ignis=Left (-300), Axiom=Center (0), Vesper=Right (300)
            else if (hour >= 22 || hour < 6)
            {
                float x = 0;
                switch (student.Doctrine)
                {
                    case Doctrine.Ignis: x = -300; break;
                    case Doctrine.Axiom: x = 0; break;
                    case Doctrine.Vesper: x = 300; break;
                }
                student.TargetPosition = new Vector2(x, 200); // Dorms at Y=200
            }
            else
            {
                // Free Time / Wander
                // Keep current target or return to center?
                // Let's send them to Commons (0,0)
                student.TargetPosition = Vector2.Zero;
            }

            // Movement Logic
            float speed = 120f; // px per sec
            if (Vector2.Distance(student.Position, student.TargetPosition) > 1f)
            {
                Vector2 dir = student.TargetPosition - student.Position;
                dir.Normalize();
                student.Position += dir * speed * deltaTime;
            }
            else
            {
                student.Position = student.TargetPosition;
            }
        }
    }
}
