using System;
using System.Collections.Generic;
using System.Linq;

namespace Bench.Repository;

public interface IRepository<T>
{
    void Add(string id, T item);
    T? Get(string id);
    bool Update(string id, T item);
    bool Remove(string id);
    IReadOnlyCollection<T> GetAll();
}

public sealed class InMemoryRepository<T> : IRepository<T>
{
    private readonly Dictionary<string, T> _items = new();

    public void Add(string id, T item)
    {
        if (id == null) throw new ArgumentNullException(nameof(id));
        _items.Add(id, item);
    }

    public T? Get(string id)
    {
        return _items.TryGetValue(id, out var value) ? value : default(T);
    }

    public bool Update(string id, T item)
    {
        if (_items.ContainsKey(id))
        {
            _items[id] = item;
            return true;
        }
        return false;
    }

    public bool Remove(string id)
    {
        return _items.Remove(id);
    }

    public IReadOnlyCollection<T> GetAll()
    {
        return _items.Values.ToList();
    }
}

public static class RepositoryFactory
{
    public static IRepository<T> Create<T>() => new InMemoryRepository<T>();
}
