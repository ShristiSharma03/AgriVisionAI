import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class Supplier {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double distanceKm;

  Supplier({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  String get distanceLabel =>
      distanceKm < 1 ? '${(distanceKm * 1000).round()} m' : '${distanceKm.toStringAsFixed(1)} km';
}

class SupplierService {
  static const String _overpassEndpoint = 'https://overpass-api.de/api/interpreter';

  Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS to find nearby suppliers.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied. Enable it in Settings to find nearby suppliers.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Enable it from app settings.');
    }

    return Geolocator.getCurrentPosition();
  }

  /// Finds shops near the given location that a farmer could
  /// realistically get crop treatment from — agri-input dealers, farm
  /// shops, garden centres, and "medical"/chemist shops (which, in
  /// many Indian towns, are the actual local seller of pesticides and
  /// fungicides even though OSM tags them the same as a human
  /// pharmacy — there's no reliable way to separate the two from OSM
  /// data alone, so both show up and the category label + shop name
  /// are the farmer's best signal for which is which).
  ///
  /// Deliberately excludes hardware/DIY stores, which are unrelated to
  /// crop treatment.
  ///
  /// [radiusMeters] can be widened by the caller (e.g. via an "expand
  /// search" button) if the initial search comes back with too few
  /// results — useful in areas where OSM's local shop coverage is
  /// sparse.
  Future<List<Supplier>> searchSuppliers({
    required String query,
    required double lat,
    required double lon,
    int radiusMeters = 15000,
  }) async {
    final results = await _runOverpassSearch(
      shopTags: 'agrarian|farm|garden_centre|chemist',
      lat: lat,
      lon: lon,
      radiusMeters: radiusMeters,
    );

    var suppliers = results;

    // If the focused agri-relevant search comes back thin, broaden to
    // general stores as a fallback — in many rural areas, the actual
    // pesticide seller is just the local general store with no
    // specific OSM shop tag at all.
    if (suppliers.length < 3) {
      final generalResults = await _runOverpassSearch(
        shopTags: 'general|convenience',
        lat: lat,
        lon: lon,
        radiusMeters: radiusMeters,
      );
      final existingIds = suppliers.map((s) => s.id).toSet();
      suppliers = [...suppliers, ...generalResults.where((s) => !existingIds.contains(s.id))];
    }

    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isNotEmpty) {
      final nameMatches = suppliers.where((s) => s.name.toLowerCase().contains(trimmedQuery)).toList();
      if (nameMatches.isNotEmpty) {
        suppliers = nameMatches;
      }
    }

    suppliers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return suppliers;
  }

  Future<List<Supplier>> _runOverpassSearch({
    required String shopTags,
    required double lat,
    required double lon,
    required int radiusMeters,
  }) async {
    final overpassQuery = '''
[out:json][timeout:25];
(
  node["shop"~"$shopTags"](around:$radiusMeters,$lat,$lon);
  way["shop"~"$shopTags"](around:$radiusMeters,$lat,$lon);
);
out center;
''';

    final response = await http.post(
      Uri.parse(_overpassEndpoint),
      headers: {
        'User-Agent': 'AgriVisionAI/1.0 (Flutter app; farmer disease-detection assistant)',
        'Accept': 'application/json',
      },
      body: {'data': overpassQuery},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to search suppliers (${response.statusCode}). The map data service may be busy — try again shortly.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['elements'] != null ? 'OK' : null;
    if (status == null) return [];

    final elements = (data['elements'] as List<dynamic>? ?? []);

    return elements.map((e) {
      final el = e as Map<String, dynamic>;
      final tags = (el['tags'] as Map<String, dynamic>?) ?? {};

      final elLat = (el['lat'] as num?)?.toDouble() ?? (el['center']?['lat'] as num?)?.toDouble();
      final elLon = (el['lon'] as num?)?.toDouble() ?? (el['center']?['lon'] as num?)?.toDouble();
      if (elLat == null || elLon == null) return null;

      final distanceMeters = Geolocator.distanceBetween(lat, lon, elLat, elLon);
      final shopType = tags['shop'] as String? ?? 'shop';

      return Supplier(
        id: '${el['type']}_${el['id']}',
        name: (tags['name'] as String?) ?? _friendlyShopLabel(shopType),
        category: _friendlyShopLabel(shopType),
        latitude: elLat,
        longitude: elLon,
        distanceKm: distanceMeters / 1000,
      );
    }).whereType<Supplier>().toList();
  }

  /// Farmer-facing category label — plain wording, not OSM's internal
  /// tag names, and honest about the chemist-tag ambiguity.
  String _friendlyShopLabel(String shopTag) {
    switch (shopTag) {
      case 'agrarian':
        return 'Agricultural Supplies';
      case 'farm':
        return 'Farm Shop';
      case 'garden_centre':
        return 'Garden Centre';
      case 'chemist':
        return 'Medical / Pesticide Store';
      case 'general':
      case 'convenience':
        return 'General Store';
      default:
        return 'Shop';
    }
  }
}