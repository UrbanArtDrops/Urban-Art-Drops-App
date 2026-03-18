using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Domain.Drops;

public sealed class Drop
{
    private const int MaxDropMakerCommentLength = 1000;

    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ArtPieceId { get; private set; }
    public Guid DropMakerId { get; private set; }
    public bool IsStationary { get; private set; }
    public int? PortableItemCount { get; private set; }
    public string? DropMakerComment { get; private set; }
    public double? Latitude { get; private set; }
    public double? Longitude { get; private set; }
    public bool IsPublished { get; private set; }
    public ICollection<DropItem> Items { get; set; } = new List<DropItem>();
    public ICollection<DropLocationPhoto> LocationPhotos { get; set; } = new List<DropLocationPhoto>();
    public ICollection<DropSocialChannelSelection> SocialChannels { get; set; } = new List<DropSocialChannelSelection>();

    private Drop()
    {
    }

    public static Drop Create(
        Guid artPieceId,
        Guid dropMakerId,
        bool isStationary,
        int? portableItemCount,
        string? dropMakerComment,
        IEnumerable<string>? socialChannels)
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

        var drop = new Drop
        {
            ArtPieceId = artPieceId,
            DropMakerId = dropMakerId,
            IsStationary = isStationary,
            PortableItemCount = isStationary ? null : portableItemCount,
            DropMakerComment = NormalizeDropMakerComment(dropMakerComment),
            IsPublished = false
        };

        drop.ReplaceSocialChannels(socialChannels);
        return drop;
    }

    public void UpdateDetails(
        bool isStationary,
        int? portableItemCount,
        string? dropMakerComment,
        IEnumerable<string>? socialChannels,
        int itemCount)
    {
        if (!isStationary && (!portableItemCount.HasValue || portableItemCount.Value < 1))
        {
            throw new DomainValidationException("Portable drops require a positive item count.");
        }

        if (!isStationary && portableItemCount > itemCount)
        {
            throw new DomainValidationException("Portable item count must not exceed the number of generated drop items.");
        }

        IsStationary = isStationary;
        PortableItemCount = isStationary ? null : portableItemCount;
        DropMakerComment = NormalizeDropMakerComment(dropMakerComment);
        ReplaceSocialChannels(socialChannels);
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

    public void AddLocationPhoto(byte[] binaryData, string contentType)
    {
        if (binaryData is null || binaryData.Length == 0)
        {
            throw new DomainValidationException("Location photo binary data is required.");
        }

        if (string.IsNullOrWhiteSpace(contentType))
        {
            throw new DomainValidationException("Location photo content type is required.");
        }

        LocationPhotos.Add(new DropLocationPhoto
        {
            DropId = Id,
            BinaryData = binaryData,
            ContentType = contentType.Trim()
        });
    }

    public void ReplaceLocationPhotos(IEnumerable<(byte[] BinaryData, string ContentType)> photos)
    {
        LocationPhotos.Clear();
        foreach (var photo in photos)
        {
            AddLocationPhoto(photo.BinaryData, photo.ContentType);
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

    public void ReplaceSocialChannels(IEnumerable<string>? socialChannels)
    {
        SocialChannels.Clear();
        var distinctChannels = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var rawChannel in socialChannels ?? [])
        {
            var normalizedChannel = DropSocialChannelSelection.NormalizeChannel(rawChannel);
            if (!distinctChannels.Add(normalizedChannel))
            {
                continue;
            }

            SocialChannels.Add(new DropSocialChannelSelection
            {
                DropId = Id,
                Channel = normalizedChannel
            });
        }
    }

    public IReadOnlyList<DropItem> ReconcileItemCount(int itemCount, Func<string> nextQrToken)
    {
        if (itemCount < 1)
        {
            throw new DomainValidationException("Drop requires at least one item.");
        }

        var claimedItemCount = Items.Count(item => item.IsClaimed);
        if (itemCount < claimedItemCount)
        {
            throw new DomainValidationException("Claimed drop items cannot be removed.");
        }

        var removedItems = new List<DropItem>();
        var unclaimedItems = Items.Where(item => !item.IsClaimed).ToList();
        while (Items.Count > itemCount)
        {
            var removableItem = unclaimedItems.LastOrDefault();
            if (removableItem is null)
            {
                throw new DomainValidationException("Claimed drop items cannot be removed.");
            }

            Items.Remove(removableItem);
            removedItems.Add(removableItem);
            unclaimedItems.RemoveAt(unclaimedItems.Count - 1);
        }

        while (Items.Count < itemCount)
        {
            var nextToken = nextQrToken();
            AddItem(nextToken);
        }

        return removedItems;
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

    private static string? NormalizeDropMakerComment(string? dropMakerComment)
    {
        var normalizedComment = dropMakerComment?.Trim();
        if (string.IsNullOrWhiteSpace(normalizedComment))
        {
            return null;
        }

        if (normalizedComment.Length > MaxDropMakerCommentLength)
        {
            throw new DomainValidationException($"Drop maker comment must not exceed {MaxDropMakerCommentLength} characters.");
        }

        return normalizedComment;
    }
}
