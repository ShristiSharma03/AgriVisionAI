import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// The official AgriVision AI logo mark — a viewfinder frame (4 corner
/// brackets, no circle) with a plant icon centered inside it, on a
/// dark green background. This matches the finalized design: deep
/// green background, pale plant, subtle mid-green frame.
///
/// Use this everywhere the logo appears (Splash, Login, Registration,
/// Home header, Camera screen) instead of recreating it inline, so
/// every screen stays visually consistent and future icon changes
/// only need to happen in one place.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Viewfinder frame — 4 corner brackets only, matching the
          // Tabler "viewfinder" icon shape (not a focus circle).
          Icon(
            Icons.crop_free,
            size: size * 0.72,
            color: AppColors.greenMid,
          ),
          // Plant, centered inside the frame.
          Icon(
            Icons.eco,
            size: size * 0.38,
            color: AppColors.greenPale,
          ),
        ],
      ),
    );
  }
}