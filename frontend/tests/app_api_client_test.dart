import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";

void main() {
  tearDown(() {
    AppApiClient.configureAccessTokenProvider(() => null);
  });

  test("admin patch requests include the authenticated bearer token", () async {
    final requests = <http.BaseRequest>[];
    final mockHttpClient = MockClient((request) async {
      requests.add(request);
      return http.Response("", 204);
    });

    AppApiClient.configureAccessTokenProvider(() => "access-token");

    final apiClient = AppApiClient(
      httpClient: mockHttpClient,
      baseUrl: "http://localhost",
    );

    await apiClient.updateUserApproval("user-1", true);
    await apiClient.updateUserSuspension("user-1", false);
    await apiClient.updateUserRole("user-1", 1);

    expect(requests, hasLength(3));

    expect(requests[0].method, "PATCH");
    expect(requests[0].url.path, "/api/admin/users/user-1/approval");
    expect(requests[0].url.queryParameters["approved"], "true");

    expect(requests[1].method, "PATCH");
    expect(requests[1].url.path, "/api/admin/users/user-1/suspension");
    expect(requests[1].url.queryParameters["suspended"], "false");

    expect(requests[2].method, "PATCH");
    expect(requests[2].url.path, "/api/admin/users/user-1/role");
    expect(requests[2].url.queryParameters["role"], "1");

    for (final request in requests) {
      expect(request.headers["Accept"], "application/json");
      expect(request.headers["Authorization"], "Bearer access-token");
    }
  });
}
