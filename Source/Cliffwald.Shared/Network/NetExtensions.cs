using LiteNetLib.Utils;
using Microsoft.Xna.Framework;

namespace Cliffwald.Shared.Network;

public static class NetExtensions
{
    public static void Put(this NetDataWriter writer, Vector2 vector)
    {
        writer.Put(vector.X);
        writer.Put(vector.Y);
    }

    public static Vector2 GetVector2(this NetDataReader reader)
    {
        return new Vector2(reader.GetFloat(), reader.GetFloat());
    }
}
