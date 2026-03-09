using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Contracts.Auth;

public sealed record RegisterLocalRequest(string Email, string UserName, string Password, UserRole Role);

public sealed record RegisterProviderRequest(string Provider, string ProviderSubject, string Email, string UserName, UserRole Role);

public sealed record LoginLocalRequest(string Email, string Password);

public sealed record LoginProviderRequest(string Provider, string ProviderSubject, string Email);

public sealed record AuthResult(bool Success, string Message, Guid? UserId = null, DateTimeOffset? RetryAfterUtc = null);
