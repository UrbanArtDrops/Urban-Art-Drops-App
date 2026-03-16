import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:urban_art_drops_app/shared/services/location_lookup_service.dart";

void main() {
  test(
    "searchLocations maps OSM search results with postcode labels",
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, "/search");
        return http.Response("""
[
  {
    "display_name": "Berlin, Deutschland",
    "lat": "52.5200",
    "lon": "13.4050",
    "address": { "postcode": "10115" }
  }
]
""", 200);
      });
      final service = OpenStreetMapLocationLookupService(httpClient: client);

      final results = await service.searchLocations(
        query: "Berlin",
        localeTag: "de-DE",
      );

      expect(results, hasLength(1));
      expect(results.first.label, "Berlin, Deutschland (10115)");
      expect(results.first.latitude, 52.52);
      expect(results.first.longitude, 13.405);
    },
  );

  test("reverseLookupLabel prefers locality and postcode", () async {
    final client = MockClient((request) async {
      expect(request.url.path, "/reverse");
      return http.Response("""
{
  "display_name": "Alexanderplatz, Berlin, Deutschland",
  "address": {
    "city": "Berlin",
    "postcode": "10178"
  }
}
""", 200);
    });
    final service = OpenStreetMapLocationLookupService(httpClient: client);

    final label = await service.reverseLookupLabel(
      latitude: 52.5219,
      longitude: 13.4132,
      localeTag: "de-DE",
    );

    expect(label, "Berlin (10178)");
  });
}
