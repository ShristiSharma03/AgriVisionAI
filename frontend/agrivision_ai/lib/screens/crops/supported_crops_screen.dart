import 'package:flutter/material.dart';
import '../../core/data/disease_catalog.dart';
import '../../core/theme/app_colors.dart';
import 'crop_diseases_screen.dart';

class SupportedCropsScreen extends StatelessWidget {
  const SupportedCropsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiSupportedCount = kCropDiseaseCatalog.where((c) => c.aiSupported).length;
    final totalDiseases = kCropDiseaseCatalog.fold<int>(0, (sum, c) => sum + c.diseases.length);

    return Scaffold(
      appBar: AppBar(title: const Text('All Crops')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greenLightBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.apps, color: AppColors.greenMid, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.greenDark, fontSize: 11.5, height: 1.5),
                        children: [
                          const TextSpan(text: 'AgriVision AI\'s camera scanner currently detects diseases for '),
                          TextSpan(text: '$aiSupportedCount crops', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: '. This screen also includes '),
                          TextSpan(text: '${kCropDiseaseCatalog.length - aiSupportedCount} more crops', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' as reference information — '),
                          TextSpan(text: '$totalDiseases conditions', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' covered in total.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                itemCount: kCropDiseaseCatalog.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final crop = kCropDiseaseCatalog[index];
                  return Material(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CropDiseasesScreen(crop: crop)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.greenLightBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.eco_outlined,
                                color: crop.aiSupported ? AppColors.greenAccent : Colors.grey,
                                size: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              crop.name,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${crop.diseases.length} disease${crop.diseases.length == 1 ? '' : 's'}',
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 8),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!crop.aiSupported) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Reference',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 7, color: Colors.grey),
                                maxLines: 1,
                              ),
                            ],
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
      ),
    );
  }
}