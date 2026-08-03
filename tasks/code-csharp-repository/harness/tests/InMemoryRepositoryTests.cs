using Xunit;

namespace Bench.Repository;

public class InMemoryRepositoryTests
{
    [Fact]
    public void Add_ThenGet_ReturnsItem()
    {
        var repo = new InMemoryRepository<string>();
        repo.Add("k1", "value1");
        Assert.Equal("value1", repo.Get("k1"));
    }

    [Fact]
    public void Add_NullId_Throws()
    {
        var repo = new InMemoryRepository<string>();
        Assert.Throws<ArgumentNullException>(() => repo.Add(null!, "value1"));
    }

    [Fact]
    public void Add_DuplicateId_Throws()
    {
        var repo = new InMemoryRepository<string>();
        repo.Add("k1", "value1");
        Assert.Throws<ArgumentException>(() => repo.Add("k1", "value2"));
    }

    [Fact]
    public void Get_MissingId_ReturnsDefault()
    {
        var repo = new InMemoryRepository<string>();
        Assert.Null(repo.Get("missing"));
    }

    [Fact]
    public void Get_MissingId_ValueType_ReturnsDefault()
    {
        var repo = new InMemoryRepository<int>();
        Assert.Equal(0, repo.Get("missing"));
    }

    [Fact]
    public void Update_ExistingId_ReplacesValue_ReturnsTrue()
    {
        var repo = new InMemoryRepository<string>();
        repo.Add("k1", "value1");
        var updated = repo.Update("k1", "value2");
        Assert.True(updated);
        Assert.Equal("value2", repo.Get("k1"));
    }

    [Fact]
    public void Update_MissingId_ReturnsFalse_DoesNotThrow()
    {
        var repo = new InMemoryRepository<string>();
        Assert.False(repo.Update("missing", "value"));
    }

    [Fact]
    public void Remove_ExistingId_ReturnsTrue_AndGone()
    {
        var repo = new InMemoryRepository<string>();
        repo.Add("k1", "value1");
        Assert.True(repo.Remove("k1"));
        Assert.Null(repo.Get("k1"));
    }

    [Fact]
    public void Remove_MissingId_ReturnsFalse()
    {
        var repo = new InMemoryRepository<string>();
        Assert.False(repo.Remove("missing"));
    }

    [Fact]
    public void GetAll_ReturnsAllItems()
    {
        var repo = new InMemoryRepository<string>();
        repo.Add("k1", "v1");
        repo.Add("k2", "v2");
        var all = repo.GetAll();
        Assert.Equal(2, all.Count);
        Assert.Contains("v1", all);
        Assert.Contains("v2", all);
    }

    [Fact]
    public void GetAll_IsSnapshot_NotAffectedByLaterAdds()
    {
        var repo = new InMemoryRepository<string>();
        repo.Add("k1", "v1");
        var snapshot = repo.GetAll();
        repo.Add("k2", "v2");
        Assert.Single(snapshot);
    }

    [Fact]
    public void RepositoryFactory_Create_ReturnsWorkingRepository_String()
    {
        var repo = RepositoryFactory.Create<string>();
        repo.Add("k1", "v1");
        Assert.Equal("v1", repo.Get("k1"));
    }

    [Fact]
    public void RepositoryFactory_Create_ReturnsWorkingRepository_Int()
    {
        var repo = RepositoryFactory.Create<int>();
        repo.Add("k1", 42);
        Assert.Equal(42, repo.Get("k1"));
    }

    [Fact]
    public void RepositoryFactory_Create_ReturnsIRepositoryInterface()
    {
        var repo = RepositoryFactory.Create<string>();
        Assert.IsAssignableFrom<IRepository<string>>(repo);
    }
}
