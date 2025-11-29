using System.Collections.Generic;
using Cliffwald.Shared;

namespace Cliffwald.Client;

public class EntityManager
{
    private Dictionary<int, PlayerState> _entities = new Dictionary<int, PlayerState>();

    public void UpdateEntity(int id, PlayerState state)
    {
        _entities[id] = state;
    }

    public void RemoveEntity(int id)
    {
        if (_entities.ContainsKey(id))
        {
            _entities.Remove(id);
        }
    }

    public IEnumerable<PlayerState> GetAllEntities()
    {
        return _entities.Values;
    }
}
