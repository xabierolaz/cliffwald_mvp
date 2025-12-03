using System;
using System.IO;
using SQLite;
using Cliffwald.Shared;

namespace Cliffwald.Server.Data;

[Table("Students")]
public class StudentEntity
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }

    public int Doctrine { get; set; } // 0=Ignis, 1=Axiom, 2=Vesper
    public int Year { get; set; }
    public int XP { get; set; }
    public float PosX { get; set; }
    public float PosY { get; set; }
}

public class DatabaseManager
{
    private SQLiteConnection _db;

    public void Initialize()
    {
        string dbPath = Path.Combine(Environment.CurrentDirectory, "cliffwald.db");
        _db = new SQLiteConnection(dbPath);

        // Create Tables
        _db.CreateTable<StudentEntity>();

        Console.WriteLine($"[DB] Database initialized at {dbPath}");

        // Seed if empty
        if (_db.Table<StudentEntity>().Count() == 0)
        {
            Console.WriteLine("[DB] Seeding initial population...");
            SeedDatabase();
        }
    }

    private void SeedDatabase()
    {
        for (int i = 0; i < 84; i++)
        {
            var s = new StudentEntity
            {
                Id = i,
                Doctrine = i % 3,
                Year = (i / 21) + 1,
                XP = 0,
                PosX = (i % 10) * 10 - 50,
                PosY = (i / 10) * 10 - 50
            };
            _db.Insert(s);
        }
        Console.WriteLine($"[DB] Seeded 84 students.");
    }

    public void UpdateStudent(StudentEntity student)
    {
        _db.Update(student);
    }

    public StudentEntity GetStudent(int id)
    {
        return _db.Find<StudentEntity>(id);
    }
}
