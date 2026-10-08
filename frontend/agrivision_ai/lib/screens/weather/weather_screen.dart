import 'package:flutter/material.dart';
import '../../core/services/weather_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';

/// Maps English crop names (as stored in WeatherService's crop
/// profiles) to translation keys, so the Crop Risk list can show a
/// translated crop name even though the underlying data is English.
/// Falls back to the original English name if not found here.
const Map<String, String> _cropNameKeys = {
  'Tomato': 'crop_tomato',
  'Potato': 'crop_potato',
  'Corn': 'crop_corn',
  'Rice': 'crop_rice',
  'Grape': 'crop_grape',
  'Apple': 'crop_apple',
  'Sugarcane': 'crop_sugarcane',
  'Wheat': 'crop_wheat',
  'Citrus': 'crop_citrus',
};

String _translatedCropName(BuildContext context, String englishName) {
  final key = _cropNameKeys[englishName];
  return key != null ? context.tr(key) : englishName;
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();

  bool _isLoading = true;
  String? _error;
  CurrentWeather? _current;
  List<ForecastSlot> _slots = [];
  List<DailyForecast> _dailyForecasts = [];
  bool _showToday = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await _weatherService.getCurrentLocation();
      final current = await _weatherService.fetchCurrentWeather(
        lat: position.latitude,
        lon: position.longitude,
      );
      final slots = await _weatherService.fetchForecastSlots(
        lat: position.latitude,
        lon: position.longitude,
      );
      final daily = _weatherService.aggregateDailyForecasts(slots);

      if (!mounted) return;
      setState(() {
        _current = current;
        _slots = slots;
        _dailyForecasts = daily;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _iconForCondition(String condition) {
    switch (condition) {
      case 'Clear':
        return Icons.wb_sunny_outlined;
      case 'Rain':
      case 'Drizzle':
      case 'Thunderstorm':
        return Icons.cloudy_snowing;
      case 'Clouds':
        return Icons.cloud_outlined;
      default:
        return Icons.cloud_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              color: AppColors.greenDark,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).maybePop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          context.tr('weather_title'),
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (!_isLoading)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                          onPressed: _loadWeather,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_current != null)
                    Row(
                      children: [
                        Icon(_iconForCondition(_current!.condition), color: AppColors.blueLight, size: 28),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_current!.tempC.round()}°', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1)),
                            // NOTE: description/locationName come straight
                            // from the weather API in English — a full
                            // translation would need a weather-condition
                            // lookup table in weather_service.dart.
                            Text(
                              '${_current!.description} · Feels like ${_current!.feelsLikeC.round()}° · ${_current!.locationName}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 9),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(child: _ToggleTab(label: context.tr('tab_today'), active: _showToday, onTap: () => setState(() => _showToday = true))),
                    Expanded(child: _ToggleTab(label: context.tr('tab_calendar'), active: !_showToday, onTap: () => setState(() => _showToday = false))),
                  ],
                ),
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.greenAccent),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadWeather, child: Text(context.tr('try_again'))),
            ],
          ),
        ),
      );
    }
    return _showToday
        ? _TodayView(current: _current!, slots: _slots, dailyForecasts: _dailyForecasts, weatherService: _weatherService)
        : _CalendarView(dailyForecasts: _dailyForecasts);
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppColors.greenMain : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TodayView extends StatelessWidget {
  final CurrentWeather current;
  final List<ForecastSlot> slots;
  final List<DailyForecast> dailyForecasts;
  final WeatherService weatherService;

  const _TodayView({required this.current, required this.slots, required this.dailyForecasts, required this.weatherService});

  Color _sprayColor(SprayCondition c) {
    switch (c) {
      case SprayCondition.optimal:
        return AppColors.success;
      case SprayCondition.moderate:
        return AppColors.orange;
      case SprayCondition.unfavorable:
        return AppColors.red;
    }
  }

  IconData _sprayIcon(SprayCondition c) {
    switch (c) {
      case SprayCondition.optimal:
        return Icons.check;
      case SprayCondition.moderate:
        return Icons.warning_amber_rounded;
      case SprayCondition.unfavorable:
        return Icons.close;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todaySlots = slots.take(6).toList();
    final todayRisk = dailyForecasts.isNotEmpty ? dailyForecasts.first.riskLevel : DiseaseRiskLevel.low;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            (Icons.water_drop_outlined, AppColors.blue, '${current.humidity}%', context.tr('metric_humidity')),
            (Icons.air, theme.textTheme.bodyMedium?.color ?? Colors.grey, '${current.windKmh.round()} km/h', context.tr('metric_wind')),
            (Icons.visibility_outlined, theme.textTheme.bodyMedium?.color ?? Colors.grey, '${current.visibilityKm.toStringAsFixed(1)} km', context.tr('metric_visibility')),
          ].map((m) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(m.$1, size: 16, color: m.$2),
                      const SizedBox(height: 2),
                      Text(m.$3, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                      Text(m.$4, style: theme.textTheme.bodySmall?.copyWith(fontSize: 7.5)),
                    ],
                  ),
                ),
              )).toList(),
        ),
        const SizedBox(height: 16),
        if (todaySlots.isNotEmpty) ...[
          Text(
            '${context.tr('spray_conditions_prefix')} ${todaySlots.length * 3} ${context.tr('hours_suffix')}',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...todaySlots.map((s) {
            final color = _sprayColor(s.sprayCondition);
            final timeLabel = '${s.time.hour.toString().padLeft(2, '0')}:00';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Text(timeLabel, style: theme.textTheme.bodySmall)),
                  Expanded(child: Container(height: 5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(width: 8),
                  Icon(_sprayIcon(s.sprayCondition), size: 15, color: color),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
        ],
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.brownBg,
            border: Border.all(color: AppColors.orange),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.brown, size: 16),
              const SizedBox(width: 8),
              // NOTE: riskSummary() text comes from WeatherService in
              // English only — translating this fully needs the
              // summary sentences moved into weather_service.dart
              // with their own language lookup.
              Expanded(
                child: Text(weatherService.riskSummary(todayRisk), style: const TextStyle(color: AppColors.brown, fontSize: 10.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(context.tr('crop_risk_today'), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          context.tr('weather_humidity_temp_template')
              .replaceAll('{humidity}', '${current.humidity}')
              .replaceAll('{temp}', '${current.tempC.round()}'),
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 8.5),
        ),
        const SizedBox(height: 8),
        ...weatherService
            .computeAllCropRisks(humidity: current.humidity, tempC: current.tempC)
            .map((risk) {
          final color = risk.level == DiseaseRiskLevel.high
              ? AppColors.red
              : risk.level == DiseaseRiskLevel.moderate
                  ? AppColors.orange
                  : AppColors.success;
          final label = risk.level == DiseaseRiskLevel.high
              ? context.tr('risk_high')
              : risk.level == DiseaseRiskLevel.moderate
                  ? context.tr('risk_moderate')
                  : context.tr('risk_low');
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_translatedCropName(context, risk.profile.cropName), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                      // NOTE: primaryDisease stays in English — same
                      // untranslated source data as the disease
                      // catalog. " risk" suffix is translated.
                      Text('${risk.profile.primaryDisease} ${context.tr('risk_suffix')}', style: theme.textTheme.bodySmall?.copyWith(fontSize: 8.5)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            context.tr('weather_model_disclaimer'),
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 8.5, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

class _CalendarView extends StatelessWidget {
  final List<DailyForecast> dailyForecasts;
  const _CalendarView({required this.dailyForecasts});

  Color _riskColor(DiseaseRiskLevel level) {
    switch (level) {
      case DiseaseRiskLevel.high:
        return AppColors.red;
      case DiseaseRiskLevel.moderate:
        return AppColors.orange;
      case DiseaseRiskLevel.low:
        return AppColors.success;
    }
  }

  static const List<String> _weekdayKeys = [
    'weekday_mon', 'weekday_tue', 'weekday_wed', 'weekday_thu', 'weekday_fri', 'weekday_sat', 'weekday_sun',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (dailyForecasts.isEmpty) {
      return Center(child: Text(context.tr('no_forecast_data'), style: theme.textTheme.bodyMedium));
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          context.tr('calendar_intro'),
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 9.5),
        ),
        const SizedBox(height: 12),
        ...dailyForecasts.map((day) {
          final weekday = context.tr(_weekdayKeys[day.date.weekday - 1]);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(width: 70, child: Text('$weekday ${day.date.day}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                Text('${day.maxTempC.round()}° / ${day.minTempC.round()}°', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10)),
                const Spacer(),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _riskColor(day.riskLevel), shape: BoxShape.circle)),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children: [
            _LegendDot(color: AppColors.success, label: context.tr('risk_low')),
            _LegendDot(color: AppColors.orange, label: context.tr('risk_moderate')),
            _LegendDot(color: AppColors.red, label: context.tr('legend_high_risk')),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8.5)),
      ],
    );
  }
}