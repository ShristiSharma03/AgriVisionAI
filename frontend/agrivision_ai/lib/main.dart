import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/localization_service.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // TODO: these are your project's real Supabase URL and anon/publishable
  // key from Project Settings > API in the Supabase dashboard. Used only
  // for Storage (scan photo uploads) — Auth and Firestore stay on Firebase.
  await Supabase.initialize(
    url: 'https://sclkcogxkgmjrvxbsezd.supabase.co',
    anonKey: 'sb_publishable_AtnwEhEDo4ifPtNj4G7bnw_SSKrv_uz',
  );

  // Required before any zonedSchedule() calls (daily reminders).
  // Without setLocalLocation, tz.local defaults to UTC, causing
  // scheduled reminders to fire at the wrong wall-clock time on the
  // device (e.g. 5.5 hours off in India).
  tz.initializeTimeZones();
  try {
    final deviceTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTimeZone));
  } catch (e) {
    // Fallback — shouldn't normally happen, but avoid crashing if the
    // device's timezone name can't be resolved.
  }

  // Sets up local notifications + FCM token registration. Safe to
  // call even if the user isn't logged in yet — token registration
  // just no-ops until after login.
  await NotificationService().initialize();

  // Loads the farmer's previously saved app-language choice (English/
  // Hindi/Marathi), defaulting to English if never set. Must load
  // before runApp so the very first frame renders in the correct
  // language rather than flashing English first.
  final localizationService = LocalizationService();
  await localizationService.loadSavedLanguage();

  runApp(
    LocalizationProvider(
      service: localizationService,
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriVision AI',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
      builder: (context, child) {
        // Clamp text scaling so a phone with a larger system font size
        // setting can't blow up layouts and cause overflow — this is
        // the single most common cause of "fits on my phone but
        // overflows on others" bugs.
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.15,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: child!,
        );
      },
    );
  }
}