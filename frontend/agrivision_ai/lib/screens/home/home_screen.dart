import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/weather_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../language/language_selection_screen.dart';
import '../weather/weather_screen.dart';
import '../crops/supported_crops_screen.dart';
import '../camera/camera_capture_screen.dart';
import '../community/community_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<CurrentWeather> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = _loadWeather();
  }

  Future<CurrentWeather> _loadWeather() async {
    final weatherService = WeatherService();
    final position = await weatherService.getCurrentLocation();
    return weatherService.fetchCurrentWeather(lat: position.latitude, lon: position.longitude);
  }


  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final displayName = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : 'Farmer';
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Dark green header — fixed brand color regardless of theme.
          SafeArea(
            bottom: false,
            child: Container(
              color: AppColors.greenDark,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const AppLogo(size: 30),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${context.tr('hi_greeting')} $displayName',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      _HeaderIconButton(
                        icon: Icons.smart_toy_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                        ),
                      ),
                      _HeaderIconButton(
                        icon: Icons.notifications_none,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                      ),
                      _HeaderIconButton(
                        icon: Icons.language,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 11,
                        child: FutureBuilder<CurrentWeather>(
                          future: _weatherFuture,
                          builder: (context, snapshot) {
                            final loading = snapshot.connectionState != ConnectionState.done;
                            final weather = snapshot.data;
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Icon(Icons.cloud_outlined, color: AppColors.blueLight, size: 20),
                                      Text(
                                        loading ? '--°C' : (weather != null ? '${weather.tempC.round()}°C' : '--°C'),
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    loading
                                        ? context.tr('loading_weather')
                                        : (weather != null ? '${weather.description} • ${weather.locationName}' : context.tr('weather_unavailable')),
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 9),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 10,
                        child: FutureBuilder<CurrentWeather>(
                          future: _weatherFuture,
                          builder: (context, snapshot) {
                            final weather = snapshot.data;
                            final weatherService = WeatherService();
                            final condition = weather != null
                                ? weatherService.quickSprayCondition(humidity: weather.humidity, windKmh: weather.windKmh)
                                : null;
                            final label = condition == null
                                ? '--'
                                : condition == SprayCondition.optimal
                                    ? context.tr('optimal')
                                    : condition == SprayCondition.moderate
                                        ? context.tr('moderate')
                                        : context.tr('unfavorable');
                            final color = condition == SprayCondition.optimal
                                ? AppColors.success
                                : condition == SprayCondition.moderate
                                    ? AppColors.orange
                                    : condition == SprayCondition.unfavorable
                                        ? AppColors.red
                                        : Colors.white70;
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.air, color: color, size: 15),
                                      const SizedBox(width: 4),
                                      Text(label, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(context.tr('tap_for_spray_timeline'), style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 8.5)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Body
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.all(14),
              child: ListView(
                children: [
                  Material(
                    color: AppColors.greenMain,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(context.tr('scan_a_crop'), style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 1),
                                  Text(context.tr('scan_a_crop_subtitle'), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(context.tr('quick_actions'), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.1,
                    children: [
                      _QuickAction(icon: Icons.history, label: context.tr('history'), color: AppColors.brown, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()))),
                      _QuickAction(icon: Icons.groups_outlined, label: context.tr('community'), color: AppColors.brown, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityScreen()))),
                      _QuickAction(icon: Icons.storefront_outlined, label: context.tr('suppliers'), color: const Color(0xFF6E56CF), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SuppliersScreen()))),
                      _QuickAction(icon: Icons.smart_toy_outlined, label: context.tr('ai_chat'), color: const Color(0xFF1D9E75), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiAssistantScreen()))),
                      _QuickAction(icon: Icons.cloud_outlined, label: context.tr('weather'), color: AppColors.blue, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeatherScreen()))),
                      _QuickAction(icon: Icons.apps, label: context.tr('all_crops'), color: AppColors.greenMain, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportedCropsScreen()))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CameraCaptureScreen()));
          } else if (index == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
          } else if (index == 3) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityScreen()));
          } else if (index == 4) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: context.tr('nav_home')),
          BottomNavigationBarItem(icon: const Icon(Icons.camera_alt_outlined), label: context.tr('nav_scan')),
          BottomNavigationBarItem(icon: const Icon(Icons.history), label: context.tr('nav_history')),
          BottomNavigationBarItem(icon: const Icon(Icons.groups_outlined), label: context.tr('nav_community')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: context.tr('nav_profile')),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 5),
              Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}