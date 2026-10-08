import 'package:flutter/material.dart';
import '../../core/services/disease_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';
import '../disease_detection/result_screen.dart';

/// Maps the English crop values stored on scan records to their
/// display translation key. Mirrors the same mapping used on the
/// Community screen for its crop filter chips.
String _cropLabelKey(String englishCrop) {
  switch (englishCrop) {
    case 'Tomato':
      return 'crop_tomato';
    case 'Rice':
      return 'crop_rice';
    case 'Potato':
      return 'crop_potato';
    case 'Wheat':
      return 'crop_wheat';
    case 'Corn':
      return 'crop_corn';
    case 'Apple':
      return 'crop_apple';
    case 'Grape':
      return 'crop_grape';
    case 'Sugarcane':
      return 'crop_sugarcane';
    case 'Citrus':
      return 'crop_citrus';
    default:
      return englishCrop; // unknown/legacy tag — show as-is
  }
}

/// Looks up [key] and substitutes `{name}`-style placeholders in [args].
String _trArgs(BuildContext context, String key, Map<String, String> args) {
  var text = context.tr(key);
  args.forEach((k, v) => text = text.replaceAll('{$k}', v));
  return text;
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Color _statusColor(ScanResult entry) {
    if (entry.isLowConfidence) return AppColors.orange;
    switch (entry.severity) {
      case 'high':
        return AppColors.red;
      case 'moderate':
        return AppColors.orange;
      default:
        return AppColors.success;
    }
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final time = '$h:$m';

    if (isToday) return _trArgs(context, 'history_today', {'time': time});
    if (isYesterday) return _trArgs(context, 'history_yesterday', {'time': time});
    final daysAgo = now.difference(dt).inDays;
    return _trArgs(context, 'history_days_ago', {'days': '$daysAgo', 'time': time});
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('history_delete_title')),
        content: Text(context.tr('history_delete_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('delete'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diseaseService = DiseaseService();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('scan_history_title'))),
      body: StreamBuilder<List<ScanResult>>(
        stream: diseaseService.streamUserHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                _trArgs(context, 'something_went_wrong', {'error': '${snapshot.error}'}),
                style: theme.textTheme.bodyMedium,
              ),
            );
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.tr('history_empty'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) async {
                  try {
                    await diseaseService.deleteScan(entry);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_trArgs(context, 'history_failed_to_delete', {'error': '$e'}))),
                      );
                    }
                  }
                },
                background: Container(
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ResultScreen(scanResult: entry)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: entry.imageUrl.isNotEmpty
                              ? Image.network(entry.imageUrl, width: 46, height: 46, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _fallbackThumb())
                              : _fallbackThumb(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      // entry.diagnosis is disease-catalog
                                      // content, outside LocalizationService's
                                      // scope — left untranslated by design.
                                      entry.isLowConfidence ? context.tr('unclear_photo') : entry.diagnosis,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusColor(entry), shape: BoxShape.circle)),
                                ],
                              ),
                              Text(
                                entry.isLowConfidence
                                    ? _trArgs(context, 'history_confidence_label', {'percent': '${(entry.confidence * 100).round()}'})
                                    : _trArgs(context, 'history_crop_match_label', {
                                        'crop': context.tr(_cropLabelKey(entry.cropType)),
                                        'percent': '${(entry.confidence * 100).round()}',
                                      }),
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 8.5),
                              ),
                              const SizedBox(height: 2),
                              Text(_formatTime(context, entry.createdAt), style: theme.textTheme.bodySmall?.copyWith(fontSize: 7.5)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () async {
                            final confirmed = await _confirmDelete(context);
                            if (!confirmed) return;
                            try {
                              await diseaseService.deleteScan(entry);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_trArgs(context, 'history_failed_to_delete', {'error': '$e'}))),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _fallbackThumb() {
    return Container(
      width: 46,
      height: 46,
      color: AppColors.greenLightBg,
      child: const Icon(Icons.eco_outlined, color: AppColors.greenAccent, size: 20),
    );
  }
}