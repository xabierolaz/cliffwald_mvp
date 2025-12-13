using SQLite;
using Cliffwald.Shared;

namespace Cliffwald.Server.Data
{
    public class StudentEntity
    {
        [PrimaryKey]
        public int Id { get; set; }
        public Doctrine Doctrine { get; set; }
        public int Year { get; set; }
        public float PositionX { get; set; }
        public float PositionY { get; set; }
        public int XP { get; set; }
    }
}
