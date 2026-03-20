using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Contracts.Profile;

public sealed record UpdateCurrentUserProfileRequest(
    string Email,
    string UserName,
    string? ProfileImageSource);

public sealed record DisableCurrentUserMfaRequest(string Code);

public sealed record ApplyForRoleRequest(UserRole Role);

public sealed record ProfileImageReferenceResponse(Guid Id, string Url);

public sealed record UserNotificationResponse(
    Guid Id,
    string Title,
    string Message,
    string Category,
    bool IsRead,
    DateTimeOffset CreatedAtUtc,
    Guid? RelatedEntityId,
    string? RelatedEntityType);

public sealed record CurrentUserProfileResponse(
    Guid UserId,
    string Email,
    string UserName,
    UserRole Role,
    UserRole? PendingRoleApplication,
    DateTimeOffset? PendingRoleApplicationRequestedAtUtc,
    bool IsProviderAccount,
    bool IsMfaEnabled,
    bool IsMfaRequiredByPolicy,
    ProfileImageReferenceResponse? ProfileImage);
