using System;
using System.Collections.Generic;
using System.IO;
using SQLite;
using Cliffwald.Shared;
using Microsoft.Xna.Framework;

namespace Cliffwald.Server.Data
{
    public class DatabaseManager
    {
        private SQLiteConnection _db;
        private string _dbPath;

        public DatabaseManager()
        {
            _dbPath = Path.Combine(Environment.CurrentDirectory, "cliffwald.db");
            _db = new SQLiteConnection(_dbPath);
            _db.CreateTable<StudentEntity>();
            Console.WriteLine($"[DB] Database initialized at {_dbPath}");
        }

        public void SaveStudents(List<StudentData> students)
        {
            var entities = new List<StudentEntity>();
            foreach (var s in students)
            {
                entities.Add(new StudentEntity
                {
                    Id = s.Id,
                    Doctrine = s.Doctrine,
                    Year = s.Year,
                    PositionX = s.Position.X,
                    PositionY = s.Position.Y,
                    XP = 0 // XP not currently in StudentData, defaulting to 0
                });
            }

            try
            {
                _db.RunInTransaction(() =>
                {
                    foreach (var e in entities)
                    {
                        _db.InsertOrReplace(e);
                    }
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[DB] Error saving students: {ex.Message}");
            }
        }

        public List<StudentData> LoadStudents()
        {
            try
            {
                var entities = _db.Table<StudentEntity>().ToList();
                var students = new List<StudentData>();

                foreach (var e in entities)
                {
                    students.Add(new StudentData
                    {
                        Id = e.Id,
                        Doctrine = e.Doctrine,
                        Year = e.Year,
                        Position = new Vector2(e.PositionX, e.PositionY),
                        TargetPosition = new Vector2(e.PositionX, e.PositionY)
                    });
                }
                return students;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[DB] Error loading students: {ex.Message}");
                return new List<StudentData>();
            }
        }
    }
}
