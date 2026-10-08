import 'package:flutter/material.dart';
import '../../core/data/disease_catalog.dart';
import '../../core/theme/app_colors.dart';
import 'disease_detail_screen.dart';

class CropDiseasesScreen extends StatelessWidget {
  final CropInfo crop;
  const CropDiseasesScreen({super.key, required this.crop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${crop.name} Diseases')),
      body: Column(
        children: [
          if (!crop.aiSupported)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brownBg,
                border: Border.all(color: AppColors.orange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.brown, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The camera scanner can\'t detect ${crop.name} diseases yet — this is reference information only.',
                      style: const TextStyle(color: AppColors.brown, fontSize: 9.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: crop.diseases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final disease = crop.diseases[index];
                return Material(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DiseaseDetailScreen(disease: disease, cropName: crop.name)),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(color: AppColors.greenLightBg, borderRadius: BorderRadius.circular(9)),
                            child: const Icon(Icons.coronavirus_outlined, color: AppColors.greenMid, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(disease.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                          const Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}