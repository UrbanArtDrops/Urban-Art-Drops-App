using Microsoft.AspNetCore.Mvc.Testing;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class HealthEndpointTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly WebApplicationFactory<Program> _factory;

    public HealthEndpointTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task HealthEndpoint_ReturnsOk()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/health");

        Assert.True(response.IsSuccessStatusCode);
    }
}
