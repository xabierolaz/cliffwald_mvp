using SQLite;
using System;
using System.IO;
using System.Collections.Generic;

namespace Cliffwald.Server.Persistence;

public class DatabaseManager
{
    private SQLiteConnection _db;
    private string _dbPath;

    public void Initialize()
    {
        string folder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Cliffwald");
        // Or local folder
        folder = "Data";
        if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);

        _dbPath = Path.Combine(folder, "cliffwald.db");
        _db = new SQLiteConnection(_dbPath);

        _db.CreateTable<StudentEntity>();
        Console.WriteLine($"[DB] Database initialized at {_dbPath}");
    }

    public void InsertOrUpdateStudent(StudentEntity student)
    {
        _db.InsertOrReplace(student);
    }

    public StudentEntity GetStudent(int id)
    {
        return _db.Find<StudentEntity>(id);
    }

    public List<StudentEntity> GetAllStudents()
    {
        return _db.Table<StudentEntity>().ToList();
    }
}
