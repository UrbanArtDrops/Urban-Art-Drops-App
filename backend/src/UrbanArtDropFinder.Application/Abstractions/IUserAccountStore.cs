using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Application.Abstractions;

public interface IUserAccountStore
{
    Task<bool> UserNameExistsAsync(string userName, CancellationToken cancellationToken);

    Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken);

    Task<UserAccount?> GetByEmailAsync(string email, CancellationToken cancellationToken);

    Task<UserAccount?> GetByProviderSubjectAsync(string provider, string providerSubject, CancellationToken cancellationToken);

    Task AddAsync(UserAccount user, string? providerSubject, CancellationToken cancellationToken);

    Task SaveChangesAsync(CancellationToken cancellationToken);

    Task<ISet<string>> GetRegisteredUserNamesAsync(CancellationToken cancellationToken);
}
