using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Domain.Drops;

public sealed class Drop
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ArtPieceId { get; private set; }
    public Guid DropMakerId { get; private set; }
    public bool IsStationary { get; private set; }
    public int? PortableItemCount { get; private set; }
    public double? Latitude { get; private set; }
    public double? Longitude { get; private set; }
    public bool IsPublished { get; private set; }
    public ICollection<DropItem> Items { get; set; } = new List<DropItem>();
    public ICollection<DropLocationPhoto> LocationPhotos { get; set; } = new List<DropLocationPhoto>();

    private Drop()
    {
    }

    public static Drop Create(Guid artPieceId, Guid dropMakerId, bool isStationary, int? portableItemCount)
    {
        if (artPieceId == Guid.Empty)
        {
            throw new DomainValidationException("Art piece reference is required.");
        }

        if (dropMakerId == Guid.Empty)
        {
            throw new DomainValidationException("Drop maker reference is required.");
        }

        if (!isStationary && (!portableItemCount.HasValue || portableItemCount.Value < 1))
        {
            throw new DomainValidationException("Portable drops require a positive item count.");
        }

        return new Drop
        {
            ArtPieceId = artPieceId,
            DropMakerId = dropMakerId,
            IsStationary = isStationary,
            PortableItemCount = isStationary ? null : portableItemCount,
            IsPublished = false
        };
    }

    public void UpdateTransportSettings(bool isStationary, int? portableItemCount)
    {
        if (!isStationary && (!portableItemCount.HasValue || portableItemCount.Value < 1))
        {
            throw new DomainValidationException("Portable drops require a positive item count.");
        }

        IsStationary = isStationary;
        PortableItemCount = isStationary ? null : portableItemCount;
    }

    public void SetLocation(double latitude, double longitude)
    {
        Latitude = latitude;
        Longitude = longitude;
    }

    public void ClearLocation()
    {
        Latitude = null;
        Longitude = null;
    }

    public void AddLocationPhoto(string url)
    {
        if (string.IsNullOrWhiteSpace(url))
        {
            throw new DomainValidationException("Location photo url is required.");
        }

        LocationPhotos.Add(new DropLocationPhoto
        {
            DropId = Id,
            Url = url.Trim()
        });
    }

    public void ReplaceLocationPhotos(IEnumerable<string> urls)
    {
        LocationPhotos.Clear();
        foreach (var url in urls)
        {
            AddLocationPhoto(url);
        }
    }

    public void AddItem(string qrToken)
    {
        if (string.IsNullOrWhiteSpace(qrToken))
        {
            throw new DomainValidationException("QR token is required.");
        }

        Items.Add(new DropItem
        {
            DropId = Id,
            QrToken = qrToken.Trim()
        });
    }

    public void ReplaceItems(IEnumerable<string> qrTokens)
    {
        Items.Clear();
        foreach (var token in qrTokens)
        {
            AddItem(token);
        }
    }

    public bool CanPublish() =>
        Latitude.HasValue &&
        Longitude.HasValue &&
        LocationPhotos.Count > 0 &&
        Items.Count > 0;

    public void Publish()
    {
        if (!CanPublish())
        {
            throw new DomainValidationException(
                "Drop requires location, at least one location photo and at least one item before publishing.");
        }

        IsPublished = true;
    }

    public void Depublish() => IsPublished = false;

    public void MarkAllClaimed(Guid? userId, string? anonymousNickname, DateTimeOffset nowUtc)
    {
        foreach (var item in Items)
        {
            if (!item.IsClaimed)
            {
                item.MarkClaimed(userId, anonymousNickname, nowUtc);
            }
        }
    }
}
