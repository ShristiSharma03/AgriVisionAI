import 'package:flutter/material.dart';
import '../../core/data/disease_catalog.dart';
import '../../core/theme/app_colors.dart';

class DiseaseDetailScreen extends StatelessWidget {
  final DiseaseInfo disease;
  final String cropName;
  const DiseaseDetailScreen({super.key, required this.disease, required this.cropName});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(disease.name)),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.greenLightBg, borderRadius: BorderRadius.circular(8)),
            child: Text(
              cropName,
              style: const TextStyle(color: AppColors.greenMid, fontSize: 9.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          _DetailSection(
            icon: Icons.visibility_outlined,
            iconColor: AppColors.blue,
            title: 'What It Looks Like',
            body: disease.whatItLooksLike,
          ),
          const SizedBox(height: 10),
          _DetailSection(
            icon: Icons.help_outline,
            iconColor: AppColors.orange,
            title: 'Why It Happens',
            body: disease.whyItHappens,
          ),
          const SizedBox(height: 10),
          _DetailSection(
            icon: Icons.build_outlined,
            iconColor: AppColors.red,
            title: 'What To Do Now',
            body: disease.whatToDo,
          ),
          const SizedBox(height: 10),
          _DetailSection(
            icon: Icons.shield_outlined,
            iconColor: AppColors.success,
            title: 'How To Prevent It Next Time',
            body: disease.howToPrevent,
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _DetailSection({required this.icon, required this.iconColor, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, height: 1.55)),
        ],
      ),
    );
  }
}