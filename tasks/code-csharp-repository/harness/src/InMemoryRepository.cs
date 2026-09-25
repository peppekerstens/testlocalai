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
        if (id == null)
            throw new ArgumentNullException(nameof(id));

        if (_items.ContainsKey(id))
            throw new ArgumentException($"An item with the key '{id}' has already been added.", nameof(id));

        _items[id] = item;
    }

    public T? Get(string id)
    {
        if (id == null)
            throw new ArgumentNullException(nameof(id));

        return _items.TryGetValue(id, out var value) ? value : default;
    }

    public bool Update(string id, T item)
    {
        if (id == null)
            throw new ArgumentNullException(nameof(id));

        if (_items.TryGetValue(id, out _))
        {
            _items[id] = item;
            return true;
        }

        return false;
    }

    public bool Remove(string id)
    {
        if (id == null)
            throw new ArgumentNullException(nameof(id));

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
