namespace UrbanArtDropFinder.Domain.Shared;

public sealed class DomainValidationException : Exception
{
    public DomainValidationException(string message) : base(message)
    {
    }
}
