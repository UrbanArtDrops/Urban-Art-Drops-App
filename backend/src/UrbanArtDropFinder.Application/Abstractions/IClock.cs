namespace UrbanArtDropFinder.Application.Abstractions;

public interface IClock
{
    DateTimeOffset UtcNow { get; }
}
