using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Domain.Art;

public sealed class ArtPiece
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ArtistId { get; private set; }
    public string Title { get; private set; }
    public string Description { get; private set; }
    public ArtPieceAssetKind AssetKind { get; private set; }
    public bool IsPublished { get; private set; }
    public ICollection<ArtPiecePhoto> Photos { get; set; } = new List<ArtPiecePhoto>();

    private ArtPiece()
    {
        Title = string.Empty;
        Description = string.Empty;
    }

    public static ArtPiece Create(Guid artistId, string title, string description, ArtPieceAssetKind assetKind)
    {
        if (artistId == Guid.Empty)
        {
            throw new DomainValidationException("Artist is required.");
        }

        if (string.IsNullOrWhiteSpace(title) || title.Trim().Length < 3)
        {
            throw new DomainValidationException("Title must have at least 3 characters.");
        }

        var normalizedDescription = description?.Trim() ?? string.Empty;
        if (normalizedDescription.Length is < 20 or > 3000)
        {
            throw new DomainValidationException("Description length must be between 20 and 3000 characters.");
        }

        return new ArtPiece
        {
            ArtistId = artistId,
            Title = title.Trim(),
            Description = normalizedDescription,
            AssetKind = assetKind,
            IsPublished = false
        };
    }

    public void AddPhoto(byte[] binaryData, string contentType)
    {
        if (binaryData is null || binaryData.Length == 0)
        {
            throw new DomainValidationException("Photo binary data is required.");
        }

        if (string.IsNullOrWhiteSpace(contentType))
        {
            throw new DomainValidationException("Photo content type is required.");
        }

        Photos.Add(new ArtPiecePhoto
        {
            ArtPieceId = Id,
            BinaryData = binaryData,
            ContentType = contentType.Trim()
        });
    }

    public void ReplacePhotos(IEnumerable<(byte[] BinaryData, string ContentType)> photos)
    {
        Photos.Clear();
        foreach (var photo in photos)
        {
            AddPhoto(photo.BinaryData, photo.ContentType);
        }
    }

    public void UpdateDetails(string title, string description)
    {
        if (string.IsNullOrWhiteSpace(title) || title.Trim().Length < 3)
        {
            throw new DomainValidationException("Title must have at least 3 characters.");
        }

        var normalizedDescription = description?.Trim() ?? string.Empty;
        if (normalizedDescription.Length is < 20 or > 3000)
        {
            throw new DomainValidationException("Description length must be between 20 and 3000 characters.");
        }

        Title = title.Trim();
        Description = normalizedDescription;
    }

    public bool CanBePublished() => Photos.Count >= 1;

    public void Publish()
    {
        if (!CanBePublished())
        {
            throw new DomainValidationException("At least one photo is required before publishing an art piece.");
        }

        IsPublished = true;
    }

    public void Depublish() => IsPublished = false;
}
