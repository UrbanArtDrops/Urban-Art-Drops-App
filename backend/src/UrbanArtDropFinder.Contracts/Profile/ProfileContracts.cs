using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Contracts.Profile;

public sealed record UpdateCurrentUserProfileRequest(
    string Email,
    string UserName,
    string? ProfileImageSource);

public sealed record DisableCurrentUserMfaRequest(string Code);

public sealed record ProfileImageReferenceResponse(Guid Id, string Url);

public sealed record CurrentUserProfileResponse(
    Guid UserId,
    string Email,
    string UserName,
    UserRole Role,
    bool IsProviderAccount,
    bool IsMfaEnabled,
    bool IsMfaRequiredByPolicy,
    ProfileImageReferenceResponse? ProfileImage);
