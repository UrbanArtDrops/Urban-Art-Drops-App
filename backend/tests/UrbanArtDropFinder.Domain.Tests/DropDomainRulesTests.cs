using UrbanArtDropFinder.Domain.Drops;
using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Domain.Tests;

public sealed class DropDomainRulesTests
{
    private static readonly byte[] SamplePhotoBytes = [1, 2, 3];

    [Fact]
    public void Publish_WhenDropHasNoLocationOrPhotos_ThrowsValidationException()
    {
        var drop = Drop.Create(Guid.NewGuid(), Guid.NewGuid(), true, null);
        drop.AddItem(Guid.NewGuid().ToString("N"));

        Assert.Throws<DomainValidationException>(() => drop.Publish());
    }

    [Fact]
    public void ValidateClaim_WhenAnonymousNicknameMatchesRegisteredUser_ThrowsValidationException()
    {
        var drop = Drop.Create(Guid.NewGuid(), Guid.NewGuid(), true, null);
        drop.SetLocation(50, 8);
        drop.AddLocationPhoto(SamplePhotoBytes, "image/jpeg");
        drop.AddItem(Guid.NewGuid().ToString("N"));
        var item = drop.Items.First();

        var registeredNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "taken-name"
        };

        Assert.Throws<DomainValidationException>(() => DropClaimPolicy.ValidateClaim(drop, item, null, "taken-name", registeredNames));
    }

    [Fact]
    public void ValidateClaim_WhenSameHunterAlreadyClaimedAnItem_ThrowsValidationException()
    {
        var hunterId = Guid.NewGuid();
        var drop = Drop.Create(Guid.NewGuid(), Guid.NewGuid(), true, null);
        drop.SetLocation(50, 8);
        drop.AddLocationPhoto(SamplePhotoBytes, "image/jpeg");
        drop.AddItem(Guid.NewGuid().ToString("N"));
        drop.AddItem(Guid.NewGuid().ToString("N"));

        drop.Items.First().MarkClaimed(hunterId, null, DateTimeOffset.UtcNow);
        var secondItem = drop.Items.Skip(1).First();

        Assert.Throws<DomainValidationException>(() =>
            DropClaimPolicy.ValidateClaim(drop, secondItem, hunterId, null, new HashSet<string>(StringComparer.OrdinalIgnoreCase)));
    }

    [Fact]
    public void ReconcileItemCount_WhenIncreasingAndThenReducing_PreservesExistingItems()
    {
        var drop = Drop.Create(Guid.NewGuid(), Guid.NewGuid(), true, null);
        drop.AddItem("token-a");
        drop.AddItem("token-b");

        var removedAfterIncrease = drop.ReconcileItemCount(4, NextToken);
        var tokensAfterIncrease = drop.Items.Select(item => item.QrToken).ToList();
        var removedAfterReduce = drop.ReconcileItemCount(3, NextToken);
        var tokensAfterReduce = drop.Items.Select(item => item.QrToken).ToList();

        Assert.Empty(removedAfterIncrease);
        Assert.Equal(4, tokensAfterIncrease.Count);
        Assert.Contains("token-a", tokensAfterIncrease);
        Assert.Contains("token-b", tokensAfterIncrease);
        Assert.Single(removedAfterReduce);
        Assert.Equal(3, tokensAfterReduce.Count);
        Assert.Contains("token-a", tokensAfterReduce);
        Assert.Contains("token-b", tokensAfterReduce);
    }

    [Fact]
    public void ReconcileItemCount_WhenRemovingClaimedItemsWouldBeRequired_ThrowsValidationException()
    {
        var hunterId = Guid.NewGuid();
        var drop = Drop.Create(Guid.NewGuid(), Guid.NewGuid(), true, null);
        drop.AddItem("token-a");
        drop.AddItem("token-b");
        drop.Items.First().MarkClaimed(hunterId, null, DateTimeOffset.UtcNow);

        Assert.Throws<DomainValidationException>(() => drop.ReconcileItemCount(0, NextToken));
    }

    private static string NextToken() => Guid.NewGuid().ToString("N");
}
