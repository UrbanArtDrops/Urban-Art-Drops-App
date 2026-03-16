using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using UrbanArtDropFinder.Contracts.Art;
using UrbanArtDropFinder.Domain.Art;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class ArtPieceEndpointsTests : IClassFixture<WebApplicationFactory<Program>>
{
    private const string SamplePngDataUrl =
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/w8AAgMBgJ/gG1cAAAAASUVORK5CYII=";

    private readonly HttpClient _client;

    public ArtPieceEndpointsTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task ArtPieceCrudFlow_CreatesUpdatesPublishesAndDeletesResource()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var createRequest = new CreateArtPieceRequest(
            Guid.NewGuid(),
            $"Crystal Owl {uniqueId}",
            "This artwork description is long enough for validation.",
            ArtPieceAssetKind.Image,
            [SamplePngDataUrl]);

        var createResponse = await _client.PostAsJsonAsync("/api/art-pieces/", createRequest);

        createResponse.EnsureSuccessStatusCode();
        var createdArtPiece = await createResponse.Content.ReadFromJsonAsync<ArtPieceResponseDto>();
        Assert.NotNull(createdArtPiece);
        Assert.Equal(createRequest.ArtistId, createdArtPiece!.ArtistId);
        Assert.Equal(createRequest.Title, createdArtPiece.Title);
        Assert.Equal(ArtPieceAssetKind.Image, createdArtPiece.AssetKind);
        Assert.Single(createdArtPiece.Photos);

        var mediaResponse = await _client.GetAsync(createdArtPiece.Photos.First().Url);
        mediaResponse.EnsureSuccessStatusCode();
        Assert.Equal("image/png", mediaResponse.Content.Headers.ContentType?.MediaType);

        var getResponse = await _client.GetAsync($"/api/art-pieces/{createdArtPiece.Id}");
        getResponse.EnsureSuccessStatusCode();
        var loadedArtPiece = await getResponse.Content.ReadFromJsonAsync<ArtPieceResponseDto>();
        Assert.NotNull(loadedArtPiece);
        Assert.Equal(createdArtPiece.Id, loadedArtPiece!.Id);

        var updatedArtistId = Guid.NewGuid();
        var updateRequest = new UpdateArtPieceRequest(
            updatedArtistId,
            $"Steel Fox {uniqueId}",
            "This updated artwork description is also long enough.",
            ArtPieceAssetKind.Model3d,
            [SamplePngDataUrl]);

        var updateResponse = await _client.PutAsJsonAsync(
            $"/api/art-pieces/{createdArtPiece.Id}",
            updateRequest);

        updateResponse.EnsureSuccessStatusCode();
        var updatedArtPiece = await updateResponse.Content.ReadFromJsonAsync<ArtPieceResponseDto>();
        Assert.NotNull(updatedArtPiece);
        Assert.Equal(updatedArtistId, updatedArtPiece!.ArtistId);
        Assert.Equal(updateRequest.Title, updatedArtPiece.Title);
        Assert.Equal(ArtPieceAssetKind.Model3d, updatedArtPiece.AssetKind);
        Assert.False(updatedArtPiece.IsPublished);

        var publishResponse = await _client.PostAsync(
            $"/api/art-pieces/{createdArtPiece.Id}/publish",
            content: null);

        publishResponse.EnsureSuccessStatusCode();
        var publishedArtPiece = await _client.GetFromJsonAsync<ArtPieceResponseDto>(
            $"/api/art-pieces/{createdArtPiece.Id}");
        Assert.NotNull(publishedArtPiece);
        Assert.True(publishedArtPiece!.IsPublished);

        var deleteResponse = await _client.DeleteAsync($"/api/art-pieces/{createdArtPiece.Id}");
        deleteResponse.EnsureSuccessStatusCode();

        var deletedGetResponse = await _client.GetAsync($"/api/art-pieces/{createdArtPiece.Id}");
        Assert.Equal(System.Net.HttpStatusCode.NotFound, deletedGetResponse.StatusCode);
    }

    private sealed record ArtPieceResponseDto(
        Guid Id,
        Guid ArtistId,
        string Title,
        string Description,
        ArtPieceAssetKind AssetKind,
        bool IsPublished,
        IReadOnlyCollection<PhotoReferenceDto> Photos);

    private sealed record PhotoReferenceDto(Guid Id, string Url);
}
