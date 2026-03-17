using Microsoft.EntityFrameworkCore;
using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Domain.Users;
using UrbanArtDropFinder.Persistence.Db;

namespace UrbanArtDropFinder.Infrastructure.Stores;

public sealed class UserAccountStore : IUserAccountStore
{
    private readonly UrbanArtDbContext _dbContext;

    public UserAccountStore(UrbanArtDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<bool> UserNameExistsAsync(string userName, CancellationToken cancellationToken)
    {
        var normalized = userName.Trim();
        return _dbContext.UserAccounts.AnyAsync(x => x.UserName == normalized, cancellationToken);
    }

    public Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken)
    {
        var normalized = email.Trim().ToLowerInvariant();
        return _dbContext.UserAccounts.AnyAsync(x => x.Email == normalized, cancellationToken);
    }

    public Task<UserAccount?> GetByEmailAsync(string email, CancellationToken cancellationToken)
    {
        var normalized = email.Trim().ToLowerInvariant();
        return _dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Email == normalized, cancellationToken);
    }

    public Task<UserAccount?> GetByIdAsync(Guid userId, CancellationToken cancellationToken)
        => _dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);

    public async Task<UserAccount?> GetByProviderSubjectAsync(string provider, string providerSubject, CancellationToken cancellationToken)
    {
        var link = await _dbContext.UserProviderLinks.FirstOrDefaultAsync(
            x => x.Provider == provider && x.ProviderSubject == providerSubject,
            cancellationToken);

        if (link is null)
        {
            return null;
        }

        return await _dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == link.UserAccountId, cancellationToken);
    }

    public async Task AddAsync(UserAccount user, string? providerSubject, CancellationToken cancellationToken)
    {
        await _dbContext.UserAccounts.AddAsync(user, cancellationToken);

        if (user.IsProviderAccount && !string.IsNullOrWhiteSpace(user.Provider) && !string.IsNullOrWhiteSpace(providerSubject))
        {
            await _dbContext.UserProviderLinks.AddAsync(new UserProviderLink
            {
                UserAccountId = user.Id,
                Provider = user.Provider,
                ProviderSubject = providerSubject.Trim()
            }, cancellationToken);
        }
    }

    public Task SaveChangesAsync(CancellationToken cancellationToken)
    {
        return _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<ISet<string>> GetRegisteredUserNamesAsync(CancellationToken cancellationToken)
    {
        var names = await _dbContext.UserAccounts
            .AsNoTracking()
            .Select(x => x.UserName)
            .ToListAsync(cancellationToken);

        return new HashSet<string>(names, StringComparer.OrdinalIgnoreCase);
    }
}
