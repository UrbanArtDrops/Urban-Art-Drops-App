namespace UrbanArtDropFinder.Contracts.Drops;

public sealed record CreateDropRequest(
    Guid ArtPieceId,
    Guid DropMakerId,
    bool IsStationary,
    int? PortableItemCount,
    string? DropMakerComment,
    IReadOnlyCollection<string> SocialChannels,
    double? Latitude,
    double? Longitude,
    IReadOnlyCollection<string> LocationPhotoUrls,
    int ItemCount);

public sealed record ClaimDropItemRequest(Guid? HunterUserId, string? AnonymousNickname);

public sealed record ClaimDropItemByTokenRequest(string QrToken, Guid? HunterUserId, string? AnonymousNickname);
