using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Domain.Art;

public sealed class ArtPiece
{
    private const int MaxSubtitleLength = 200;

    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ArtistId { get; private set; }
    public string Title { get; private set; }
    public string Subtitle { get; private set; }
    public string Description { get; private set; }
    public ArtPieceAssetKind AssetKind { get; private set; }
    public bool IsPublished { get; private set; }
    public bool IsReported { get; private set; }
    public string? ReportReason { get; private set; }
    public DateTimeOffset? ReportedAtUtc { get; private set; }
    public ICollection<ArtPiecePhoto> Photos { get; set; } = new List<ArtPiecePhoto>();
    public ArtPieceAssetFile? AssetFile { get; private set; }

    private ArtPiece()
    {
        Title = string.Empty;
        Subtitle = string.Empty;
        Description = string.Empty;
    }

    public static ArtPiece Create(Guid artistId, string title, string? subtitle, string description, ArtPieceAssetKind assetKind)
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

        var normalizedSubtitle = NormalizeSubtitle(subtitle);

        return new ArtPiece
        {
            ArtistId = artistId,
            Title = title.Trim(),
            Subtitle = normalizedSubtitle,
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

    public void SetAssetFile(byte[] binaryData, string contentType, string fileName)
    {
        if (binaryData is null || binaryData.Length == 0)
        {
            throw new DomainValidationException("Asset binary data is required.");
        }

        if (string.IsNullOrWhiteSpace(contentType))
        {
            throw new DomainValidationException("Asset content type is required.");
        }

        var normalizedFileName = fileName?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(normalizedFileName))
        {
            throw new DomainValidationException("Asset file name is required.");
        }

        if (AssetFile is null)
        {
            AssetFile = new ArtPieceAssetFile
            {
                ArtPieceId = Id,
                BinaryData = binaryData,
                ContentType = contentType.Trim(),
                FileName = normalizedFileName
            };
            return;
        }

        AssetFile.BinaryData = binaryData;
        AssetFile.ContentType = contentType.Trim();
        AssetFile.FileName = normalizedFileName;
    }

    public void ClearAssetFile()
    {
        AssetFile = null;
    }

    public void UpdateDetails(Guid artistId, string title, string? subtitle, string description, ArtPieceAssetKind assetKind)
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

        var normalizedSubtitle = NormalizeSubtitle(subtitle);

        ArtistId = artistId;
        Title = title.Trim();
        Subtitle = normalizedSubtitle;
        Description = normalizedDescription;
        AssetKind = assetKind;

        if (assetKind != ArtPieceAssetKind.Model3d)
        {
            ClearAssetFile();
        }
    }

    public bool CanBePublished()
    {
        if (Photos.Count < 1)
        {
            return false;
        }

        if (AssetKind == ArtPieceAssetKind.Model3d)
        {
            return AssetFile is not null;
        }

        return true;
    }

    public void Publish()
    {
        if (!CanBePublished())
        {
            throw new DomainValidationException(
                AssetKind == ArtPieceAssetKind.Model3d
                    ? "Model art pieces require at least one photo and a 3D asset before publishing."
                    : "At least one photo is required before publishing an art piece.");
        }

        IsPublished = true;
    }

    public void Depublish() => IsPublished = false;

    public void Report(string? reason, DateTimeOffset utcNow)
    {
        IsReported = true;
        ReportReason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim();
        ReportedAtUtc = utcNow;
    }

    public void DismissReport()
    {
        IsReported = false;
        ReportReason = null;
        ReportedAtUtc = null;
    }

    private static string NormalizeSubtitle(string? subtitle)
    {
        var normalizedSubtitle = subtitle?.Trim() ?? string.Empty;
        if (normalizedSubtitle.Length > MaxSubtitleLength)
        {
            throw new DomainValidationException($"Subtitle must not exceed {MaxSubtitleLength} characters.");
        }

        return normalizedSubtitle;
    }
}
