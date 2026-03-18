using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Domain.Users;

public sealed class UserNotification
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserAccountId { get; set; }
    public string Title { get; private set; }
    public string Message { get; private set; }
    public string Category { get; private set; }
    public bool IsRead { get; private set; }
    public DateTimeOffset CreatedAtUtc { get; private set; } = DateTimeOffset.UtcNow;
    public Guid? RelatedEntityId { get; private set; }
    public string? RelatedEntityType { get; private set; }

    private UserNotification()
    {
        Title = string.Empty;
        Message = string.Empty;
        Category = string.Empty;
    }

    public static UserNotification Create(
        Guid userAccountId,
        string title,
        string message,
        string category,
        Guid? relatedEntityId = null,
        string? relatedEntityType = null)
    {
        if (userAccountId == Guid.Empty)
        {
            throw new DomainValidationException("Notification user is required.");
        }

        if (string.IsNullOrWhiteSpace(title))
        {
            throw new DomainValidationException("Notification title is required.");
        }

        if (string.IsNullOrWhiteSpace(message))
        {
            throw new DomainValidationException("Notification message is required.");
        }

        if (string.IsNullOrWhiteSpace(category))
        {
            throw new DomainValidationException("Notification category is required.");
        }

        return new UserNotification
        {
            UserAccountId = userAccountId,
            Title = title.Trim(),
            Message = message.Trim(),
            Category = category.Trim(),
            RelatedEntityId = relatedEntityId,
            RelatedEntityType = string.IsNullOrWhiteSpace(relatedEntityType)
                ? null
                : relatedEntityType.Trim()
        };
    }

    public void MarkRead() => IsRead = true;
}
