using SQLite;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Cliffwald.Shared;
using Microsoft.Xna.Framework;

namespace Cliffwald.Server
{
    // Persistence Entity
    public class StudentEntity
    {
        [PrimaryKey]
        public int Id { get; set; }
        public int Doctrine { get; set; }
        public int Year { get; set; }
        public float PositionX { get; set; }
        public float PositionY { get; set; }
    }

    public class DatabaseManager
    {
        private SQLiteConnection _db;

        public void Initialize()
        {
            string dbPath = Path.Combine(Environment.CurrentDirectory, "cliffwald_world.db");
            _db = new SQLiteConnection(dbPath);
            _db.CreateTable<StudentEntity>();
            Console.WriteLine($"[DB] Database initialized at: {dbPath}");
        }

        public void SaveStudents(List<StudentData> students)
        {
            _db.RunInTransaction(() =>
            {
                foreach (var s in students)
                {
                    var entity = new StudentEntity
                    {
                        Id = s.Id,
                        Doctrine = (int)s.Doctrine,
                        Year = s.Year,
                        PositionX = s.Position.X,
                        PositionY = s.Position.Y
                    };
                    _db.InsertOrReplace(entity);
                }
            });
        }

        public List<StudentData> LoadStudents()
        {
            var entities = _db.Table<StudentEntity>().ToList();
            if (entities.Count == 0) return null;

            var list = new List<StudentData>();
            foreach (var e in entities)
            {
                list.Add(new StudentData
                {
                    Id = e.Id,
                    Doctrine = (Doctrine)e.Doctrine,
                    Year = e.Year,
                    Position = new Vector2(e.PositionX, e.PositionY),
                    TargetPosition = new Vector2(e.PositionX, e.PositionY)
                });
            }
            return list;
        }
    }
}
