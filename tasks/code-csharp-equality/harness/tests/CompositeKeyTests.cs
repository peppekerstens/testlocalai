using Xunit;

namespace Bench.Equality;

public class CompositeKeyTests
{
    [Fact]
    public void Constructor_NullTenantId_Throws()
    {
        Assert.Throws<ArgumentNullException>(() => new CompositeKey(null!, "r1"));
    }

    [Fact]
    public void Constructor_NullResourceId_Throws()
    {
        Assert.Throws<ArgumentNullException>(() => new CompositeKey("t1", null!));
    }

    [Fact]
    public void Equals_SameCase_AreEqual()
    {
        var a = new CompositeKey("tenant1", "res1");
        var b = new CompositeKey("tenant1", "res1");
        Assert.True(a.Equals(b));
    }

    [Fact]
    public void Equals_DifferentCase_AreEqual()
    {
        var a = new CompositeKey("Tenant1", "Res1");
        var b = new CompositeKey("TENANT1", "RES1");
        Assert.True(a.Equals(b));
        Assert.True(a.Equals((object)b));
    }

    [Fact]
    public void Equals_DifferentTenant_AreNotEqual()
    {
        var a = new CompositeKey("tenant1", "res1");
        var b = new CompositeKey("tenant2", "res1");
        Assert.False(a.Equals(b));
    }

    [Fact]
    public void Equals_Null_ReturnsFalse_DoesNotThrow()
    {
        var a = new CompositeKey("tenant1", "res1");
        Assert.False(a.Equals(null));
        Assert.False(a!.Equals((object?)null));
    }

    [Fact]
    public void Equals_WrongType_ReturnsFalse()
    {
        var a = new CompositeKey("tenant1", "res1");
        Assert.False(a.Equals("not a key"));
    }

    [Fact]
    public void GetHashCode_EqualKeys_HaveEqualHashCodes()
    {
        var a = new CompositeKey("Tenant1", "Res1");
        var b = new CompositeKey("TENANT1", "res1");
        Assert.Equal(a.GetHashCode(), b.GetHashCode());
    }

    [Fact]
    public void EqualityOperator_BothNull_ReturnsTrue()
    {
        CompositeKey? a = null;
        CompositeKey? b = null;
        Assert.True(a == b);
    }

    [Fact]
    public void EqualityOperator_OneNull_ReturnsFalse()
    {
        var a = new CompositeKey("t1", "r1");
        CompositeKey? b = null;
        Assert.False(a == b);
        Assert.False(b == a);
        Assert.True(a != b);
    }

    [Fact]
    public void EqualityOperator_EqualValues_ReturnsTrue()
    {
        var a = new CompositeKey("t1", "r1");
        var b = new CompositeKey("T1", "R1");
        Assert.True(a == b);
        Assert.False(a != b);
    }

    [Fact]
    public void Deduplicate_CaseVariantDuplicates_CollapseToOne()
    {
        var dedup = new KeyDeduplicator();
        var keys = new List<CompositeKey>
        {
            new("tenant1", "res1"),
            new("Tenant1", "Res1"),
            new("TENANT1", "RES1"),
            new("tenant2", "res1"),
        };
        var result = dedup.Deduplicate(keys);
        Assert.Equal(2, result.Count);
        Assert.Contains(new CompositeKey("tenant1", "res1"), result);
        Assert.Contains(new CompositeKey("tenant2", "res1"), result);
    }

    [Fact]
    public void Deduplicate_EmptyInput_ReturnsEmptySet()
    {
        var dedup = new KeyDeduplicator();
        Assert.Empty(dedup.Deduplicate([]));
    }

    [Fact]
    public void Deduplicate_NullInput_Throws()
    {
        var dedup = new KeyDeduplicator();
        Assert.Throws<ArgumentNullException>(() => dedup.Deduplicate(null!));
    }
}
