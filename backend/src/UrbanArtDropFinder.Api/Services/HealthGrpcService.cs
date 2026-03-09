using Grpc.Core;
using UrbanArtDropFinder.Grpc;

namespace UrbanArtDropFinder.Api.Services;

public sealed class HealthGrpcService : HealthService.HealthServiceBase
{
    public override Task<HealthResponse> CheckHealth(HealthRequest request, ServerCallContext context)
    {
        return Task.FromResult(new HealthResponse
        {
            Status = "ok",
            UtcNow = DateTimeOffset.UtcNow.ToString("O")
        });
    }
}
