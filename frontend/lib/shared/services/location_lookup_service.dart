import "dart:convert";

import "package:http/http.dart" as http;

class LocationLookupSuggestion {
  const LocationLookupSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}

abstract interface class LocationLookupService {
  Future<List<LocationLookupSuggestion>> searchLocations({
    required String query,
    required String localeTag,
  });

  Future<String?> reverseLookupLabel({
    required double latitude,
    required double longitude,
    required String localeTag,
  });
}

class OpenStreetMapLocationLookupService implements LocationLookupService {
  OpenStreetMapLocationLookupService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  Future<List<LocationLookupSuggestion>> searchLocations({
    required String query,
    required String localeTag,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return const [];
    }

    final uri = Uri.https("nominatim.openstreetmap.org", "/search", {
      "q": trimmedQuery,
      "format": "jsonv2",
      "limit": "6",
      "addressdetails": "1",
      "accept-language": localeTag,
    });

    final response = await _httpClient.get(uri, headers: _headers("search"));
    if (response.statusCode != 200) {
      return const [];
    }

    final payload = jsonDecode(response.body);
    if (payload is! List<dynamic>) {
      return const [];
    }

    return payload
        .whereType<Map<dynamic, dynamic>>()
        .map(_mapSearchSuggestion)
        .whereType<LocationLookupSuggestion>()
        .toList(growable: false);
  }

  @override
  Future<String?> reverseLookupLabel({
    required double latitude,
    required double longitude,
    required String localeTag,
  }) async {
    final uri = Uri.https("nominatim.openstreetmap.org", "/reverse", {
      "lat": latitude.toString(),
      "lon": longitude.toString(),
      "format": "jsonv2",
      "addressdetails": "1",
      "accept-language": localeTag,
    });

    final response = await _httpClient.get(uri, headers: _headers("reverse"));
    if (response.statusCode != 200) {
      return null;
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<dynamic, dynamic>) {
      return null;
    }

    return _mapReverseLabel(payload);
  }

  Map<String, String> _headers(String context) => {
    "Accept": "application/json",
    "User-Agent": "UrbanArtDropsApp/1.0 ($context)",
  };
}

LocationLookupSuggestion? _mapSearchSuggestion(Map<dynamic, dynamic> entry) {
  final displayName = entry["display_name"]?.toString().trim() ?? "";
  final latitude = double.tryParse(entry["lat"]?.toString() ?? "");
  final longitude = double.tryParse(entry["lon"]?.toString() ?? "");
  if (displayName.isEmpty || latitude == null || longitude == null) {
    return null;
  }

  final address = entry["address"];
  final postcode = address is Map<dynamic, dynamic>
      ? address["postcode"]?.toString().trim() ?? ""
      : "";
  final label = postcode.isEmpty ? displayName : "$displayName ($postcode)";

  return LocationLookupSuggestion(
    label: label,
    latitude: latitude,
    longitude: longitude,
  );
}

String? _mapReverseLabel(Map<dynamic, dynamic> payload) {
  final address = payload["address"];
  final displayName = payload["display_name"]?.toString().trim() ?? "";
  if (address is! Map<dynamic, dynamic>) {
    return displayName.isEmpty ? null : displayName;
  }

  final locality =
      [
            address["city"],
            address["town"],
            address["village"],
            address["hamlet"],
            address["municipality"],
            address["county"],
          ]
          .map((value) => value?.toString().trim() ?? "")
          .firstWhere((value) => value.isNotEmpty, orElse: () => "");
  final postcode = address["postcode"]?.toString().trim() ?? "";

  if (locality.isNotEmpty && postcode.isNotEmpty) {
    return "$locality ($postcode)";
  }
  if (locality.isNotEmpty) {
    return locality;
  }
  if (postcode.isNotEmpty) {
    return postcode;
  }
  return displayName.isEmpty ? null : displayName;
}
