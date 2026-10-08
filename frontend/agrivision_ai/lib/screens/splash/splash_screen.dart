import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../home/home_screen.dart';
import '../language/language_selection_screen.dart';

/// Shown briefly on app launch. Checks whether a user is already
/// signed in and routes accordingly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Small delay so the splash branding is actually visible.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final user = _authService.currentUser;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => user != null ? const HomeScreen() : const LanguageSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Splash always uses the brand dark-green background regardless
    // of light/dark mode — it's the app's identity screen, not a
    // themed content screen.
    return Scaffold(
      backgroundColor: AppColors.greenDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(size: 84),
            const SizedBox(height: 18),
            const Text(
              'AgriVision AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Smart crop care for every farmer',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenPale),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 24),
            // Language hint chip, matching the finalized design —
            // purely decorative here; actual language selection
            // happens on the next screen.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 13, color: AppColors.greenPale),
                  const SizedBox(width: 5),
                  const Text(
                    'EN • हिं • मराठी',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}