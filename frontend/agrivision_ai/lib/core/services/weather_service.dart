import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Current weather conditions for the farmer's location.
class CurrentWeather {
  final double tempC;
  final double feelsLikeC;
  final String condition; // e.g. "Clouds", "Rain", "Clear"
  final String description;
  final int humidity;
  final double windKmh;
  final double visibilityKm;
  final String locationName;

  CurrentWeather({
    required this.tempC,
    required this.feelsLikeC,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windKmh,
    required this.visibilityKm,
    required this.locationName,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      tempC: (json['main']['temp'] as num).toDouble(),
      feelsLikeC: (json['main']['feels_like'] as num).toDouble(),
      condition: json['weather'][0]['main'],
      description: json['weather'][0]['description'],
      humidity: json['main']['humidity'],
      windKmh: (json['wind']['speed'] as num).toDouble() * 3.6, // m/s -> km/h
      visibilityKm: ((json['visibility'] ?? 10000) as num).toDouble() / 1000,
      locationName: json['name'] ?? 'Your location',
    );
  }
}

/// One 3-hour forecast slot, used both for the hourly spray timeline
/// and aggregated into daily forecast entries.
class ForecastSlot {
  final DateTime time;
  final double tempC;
  final String condition;
  final int humidity;
  final double windKmh;
  final double rainProbability; // 0.0 - 1.0

  ForecastSlot({
    required this.time,
    required this.tempC,
    required this.condition,
    required this.humidity,
    required this.windKmh,
    required this.rainProbability,
  });

  factory ForecastSlot.fromJson(Map<String, dynamic> json) {
    return ForecastSlot(
      time: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      tempC: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'],
      humidity: json['main']['humidity'],
      windKmh: (json['wind']['speed'] as num).toDouble() * 3.6,
      rainProbability: ((json['pop'] ?? 0) as num).toDouble(),
    );
  }

  /// Spray-condition rating for this specific time slot, following the
  /// same color+icon coding pattern used across the app (see the
  /// Weather screen's spray timeline and the AgriVision AI UI/UX
  /// design reference).
  SprayCondition get sprayCondition {
    if (rainProbability > 0.4 || windKmh > 20) return SprayCondition.unfavorable;
    if (rainProbability > 0.15 || windKmh > 12 || humidity > 85) return SprayCondition.moderate;
    return SprayCondition.optimal;
  }
}

/// One day's aggregated forecast (used for day chips and the calendar).
class DailyForecast {
  final DateTime date;
  final double maxTempC;
  final double minTempC;
  final String condition;
  final DiseaseRiskLevel riskLevel;

  DailyForecast({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.condition,
    required this.riskLevel,
  });
}

enum SprayCondition { optimal, moderate, unfavorable }

enum DiseaseRiskLevel { low, moderate, high }

/// A crop's typical disease-conducive weather profile, used to give
/// farmers a crop-specific risk read instead of one generic number.
/// Thresholds are simplified agronomic approximations (not a trained
/// model) representing the humidity/temperature range in which the
/// crop's most common disease tends to spread fastest.
class CropRiskProfile {
  final String cropName;
  final String primaryDisease;
  final int minHumidity;
  final double minTempC;
  final double maxTempC;

  const CropRiskProfile({
    required this.cropName,
    required this.primaryDisease,
    required this.minHumidity,
    required this.minTempC,
    required this.maxTempC,
  });

  // Keeps old code that uses diseaseName working
  String get diseaseName => primaryDisease;
}

const List<CropRiskProfile> kCropRiskProfiles = [
  CropRiskProfile(cropName: 'Tomato', primaryDisease: 'Late Blight', minHumidity: 85, minTempC: 10, maxTempC: 24),
  CropRiskProfile(cropName: 'Potato', primaryDisease: 'Late Blight', minHumidity: 85, minTempC: 10, maxTempC: 24),
  CropRiskProfile(cropName: 'Corn', primaryDisease: 'Northern Leaf Blight', minHumidity: 90, minTempC: 18, maxTempC: 27),
  CropRiskProfile(cropName: 'Rice', primaryDisease: 'Blast', minHumidity: 90, minTempC: 25, maxTempC: 30),
  CropRiskProfile(cropName: 'Grape', primaryDisease: 'Downy Mildew', minHumidity: 80, minTempC: 20, maxTempC: 30),
  CropRiskProfile(cropName: 'Apple', primaryDisease: 'Apple Scab', minHumidity: 90, minTempC: 6, maxTempC: 24),
  CropRiskProfile(cropName: 'Sugarcane', primaryDisease: 'Red Rot', minHumidity: 80, minTempC: 25, maxTempC: 35),
  CropRiskProfile(cropName: 'Wheat', primaryDisease: 'Rust', minHumidity: 70, minTempC: 15, maxTempC: 22),
  CropRiskProfile(cropName: 'Citrus', primaryDisease: 'Canker', minHumidity: 80, minTempC: 20, maxTempC: 32),
];

class CropRiskResult {
  final CropRiskProfile profile;
  final DiseaseRiskLevel level;
  const CropRiskResult({required this.profile, required this.level});
}

class WeatherService {
  // TODO: replace with your own free OpenWeather API key from
  // https://openweathermap.org/api — the free tier covers current
  // weather + 5-day/3-hour forecast, which is all this screen uses.
  static const String _apiKey =
    String.fromEnvironment('OPENWEATHER_API_KEY');
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Requests location permission (if needed) and returns the
  /// device's current GPS position.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Enable it in phone settings.');
    }

    return Geolocator.getCurrentPosition();
  }

  Future<CurrentWeather> fetchCurrentWeather({required double lat, required double lon}) async {
    final uri = Uri.parse('$_baseUrl/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load weather (${response.statusCode}): ${response.body}');
    }
    return CurrentWeather.fromJson(jsonDecode(response.body));
  }

  Future<List<ForecastSlot>> fetchForecastSlots({required double lat, required double lon}) async {
    final uri = Uri.parse('$_baseUrl/forecast?lat=$lat&lon=$lon&units=metric&appid=$_apiKey');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load forecast (${response.statusCode}): ${response.body}');
    }
    final data = jsonDecode(response.body);
    final list = data['list'] as List;
    return list.map((e) => ForecastSlot.fromJson(e)).toList();
  }

  /// Aggregates raw 3-hour forecast slots into one entry per day,
  /// computing a simple rule-based disease-risk level from humidity
  /// and temperature (high humidity + warm temperature is the
  /// classic condition for fungal blight-type diseases).
  ///
  /// NOTE: this is a heuristic, not a trained model. It exists to
  /// give farmers a directional signal today; the project's longer-
  /// term plan is to replace this with weather-conditioned outputs
  /// from the disease-detection model itself.
  List<DailyForecast> aggregateDailyForecasts(List<ForecastSlot> slots) {
    final Map<String, List<ForecastSlot>> byDay = {};
    for (final slot in slots) {
      final key = '${slot.time.year}-${slot.time.month}-${slot.time.day}';
      byDay.putIfAbsent(key, () => []).add(slot);
    }

    return byDay.entries.map((entry) {
      final daySlots = entry.value;
      final maxTemp = daySlots.map((s) => s.tempC).reduce((a, b) => a > b ? a : b);
      final minTemp = daySlots.map((s) => s.tempC).reduce((a, b) => a < b ? a : b);
      final avgHumidity = daySlots.map((s) => s.humidity).reduce((a, b) => a + b) / daySlots.length;
      final middaySlot = daySlots[daySlots.length ~/ 2];

      DiseaseRiskLevel risk;
      if (avgHumidity > 80 && maxTemp > 22 && maxTemp < 32) {
        risk = DiseaseRiskLevel.high;
      } else if (avgHumidity > 65) {
        risk = DiseaseRiskLevel.moderate;
      } else {
        risk = DiseaseRiskLevel.low;
      }

      return DailyForecast(
        date: daySlots.first.time,
        maxTempC: maxTemp,
        minTempC: minTemp,
        condition: middaySlot.condition,
        riskLevel: risk,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Human-readable overall risk summary for today, used in the
  /// risk-alert banner on the Weather screen.
  String riskSummary(DiseaseRiskLevel level) {
    switch (level) {
      case DiseaseRiskLevel.high:
        return 'Moderate blight risk — high humidity increases fungal risk this week';
      case DiseaseRiskLevel.moderate:
        return 'Some fungal risk — monitor humidity levels over the next few days';
      case DiseaseRiskLevel.low:
        return 'Low disease risk — conditions are currently unfavorable for fungal spread';
    }
  }

  /// Quick spray-condition label derived from current conditions only
  /// (no forecast needed) — used for the compact Home screen widget.
  SprayCondition quickSprayCondition({required int humidity, required double windKmh}) {
    if (windKmh > 20) return SprayCondition.unfavorable;
    if (humidity > 85 || windKmh > 12) return SprayCondition.moderate;
    return SprayCondition.optimal;
  }

  /// Computes today's disease-risk level for every supported crop by
  /// comparing current humidity and temperature against each crop's
  /// disease-conducive profile. Returned sorted highest-risk first,
  /// so a farmer can see at a glance which of their crops need
  /// attention today.
  List<CropRiskResult> computeAllCropRisks({required int humidity, required double tempC}) {
    final results = kCropRiskProfiles.map((profile) {
      final tempInRange = tempC >= profile.minTempC && tempC <= profile.maxTempC;
      final humidityAtRisk = humidity >= profile.minHumidity;
      final humidityNearRisk = humidity >= profile.minHumidity - 12;

      DiseaseRiskLevel level;
      if (humidityAtRisk && tempInRange) {
        level = DiseaseRiskLevel.high;
      } else if (humidityNearRisk && tempInRange) {
        level = DiseaseRiskLevel.moderate;
      } else {
        level = DiseaseRiskLevel.low;
      }
      return CropRiskResult(profile: profile, level: level);
    }).toList();

    const order = {DiseaseRiskLevel.high: 0, DiseaseRiskLevel.moderate: 1, DiseaseRiskLevel.low: 2};
    results.sort((a, b) => order[a.level]!.compareTo(order[b.level]!));
    return results;
  }

  /// Per-crop disease favorability profile: the humidity and
  /// temperature range in which that crop's most common disease
  /// tends to spread fastest. These are general agronomic rules of
  /// thumb (not derived from the app's own trained model) used to
  /// give farmers a crop-specific signal instead of one generic
  /// risk message.
  static const List<CropRiskProfile> kCropRiskProfiles = [
  CropRiskProfile(
    cropName: 'Tomato',
    primaryDisease: 'Late Blight',
    minHumidity: 85,
    minTempC: 10,
    maxTempC: 24,
  ),

  CropRiskProfile(
    cropName: 'Potato',
    primaryDisease: 'Late Blight',
    minHumidity: 85,
    minTempC: 10,
    maxTempC: 24,
  ),

  CropRiskProfile(
    cropName: 'Corn',
    primaryDisease: 'Northern Leaf Blight',
    minHumidity: 90,
    minTempC: 18,
    maxTempC: 27,
  ),

  CropRiskProfile(
    cropName: 'Rice',
    primaryDisease: 'Blast',
    minHumidity: 90,
    minTempC: 25,
    maxTempC: 30,
  ),

  CropRiskProfile(
    cropName: 'Grape',
    primaryDisease: 'Downy Mildew',
    minHumidity: 80,
    minTempC: 20,
    maxTempC: 30,
  ),

  CropRiskProfile(
    cropName: 'Apple',
    primaryDisease: 'Apple Scab',
    minHumidity: 90,
    minTempC: 6,
    maxTempC: 24,
  ),

  CropRiskProfile(
    cropName: 'Sugarcane',
    primaryDisease: 'Red Rot',
    minHumidity: 80,
    minTempC: 25,
    maxTempC: 35,
  ),

  CropRiskProfile(
    cropName: 'Wheat',
    primaryDisease: 'Rust',
    minHumidity: 70,
    minTempC: 15,
    maxTempC: 22,
  ),

  CropRiskProfile(
    cropName: 'Citrus',
    primaryDisease: 'Canker',
    minHumidity: 80,
    minTempC: 20,
    maxTempC: 32,
  ),
];
  /// Computes a crop-specific risk level for the given crop under
  /// the given current weather conditions.
  DiseaseRiskLevel cropRiskLevel({
    required String cropName,
    required int humidity,
    required double tempC,
  }) {
    final profile = kCropRiskProfiles.firstWhere((p) => p.cropName == cropName, orElse: () => const CropRiskProfile(cropName: '', primaryDisease: '', minHumidity: 0, minTempC: 0, maxTempC: 0));
    if (profile == const CropRiskProfile(cropName: '', primaryDisease: '', minHumidity: 0, minTempC: 0, maxTempC: 0)) return DiseaseRiskLevel.low;

    final tempInRange = tempC >= profile.minTempC && tempC <= profile.maxTempC;
    final humidityHigh = humidity >= profile.minHumidity;

    if (humidityHigh && tempInRange) return DiseaseRiskLevel.high;
    if (humidityHigh || (tempInRange && humidity >= profile.minHumidity - 15)) {
      return DiseaseRiskLevel.moderate;
    }
    return DiseaseRiskLevel.low;
  }

  String cropDiseaseName(String cropName) =>
    kCropRiskProfiles
        .firstWhere(
          (profile) => profile.cropName == cropName,
          orElse: () => const CropRiskProfile(
            cropName: '',
            primaryDisease: 'fungal disease',
            minHumidity: 0,
            minTempC: 0,
            maxTempC: 0,
          ),
        )
        .primaryDisease;
}