using Microsoft.Xna.Framework;

namespace Cliffwald.Shared;

public struct PlayerState
{
    public int Id;
    public Vector2 Position;
    public Vector2 Velocity;
    public bool IsMoving;
    /// <summary>
    /// 0=Down, 1=Right, 2=Up, 3=Left
    /// </summary>
    public int Direction;
}
