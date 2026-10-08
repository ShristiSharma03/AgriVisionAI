import 'package:flutter/material.dart';
import '../../core/services/disease_service.dart';
import '../../core/services/voice_service.dart';
import '../../core/theme/app_colors.dart';
import '../suppliers/suppliers_screen.dart';

class ResultScreen extends StatefulWidget {
  final ScanResult scanResult;

  const ResultScreen({super.key, required this.scanResult});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final VoiceService _voiceService = VoiceService();
  bool _isSpeaking = false;

  ScanResult get scanResult => widget.scanResult;

  @override
  void dispose() {
    _voiceService.stopSpeaking();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _toggleListen() async {
    if (_isSpeaking) {
      await _voiceService.stopSpeaking();
      setState(() => _isSpeaking = false);
      return;
    }

    setState(() => _isSpeaking = true);
    final spokenText =
        '${scanResult.diagnosis}. $_severityLabel. Symptoms: ${scanResult.symptoms}. Recommended treatment: ${scanResult.treatment}';
    // English only for now — the diagnosis/treatment content itself is
    // only written in English (see disease_classifier.dart), so
    // reading it with a Hindi or Marathi voice would mispronounce
    // every word rather than actually translate it. This becomes
    // multi-language once the disease content itself is translated.
    await _voiceService.speak(spokenText, languageCode: 'en');
    if (mounted) setState(() => _isSpeaking = false);
  }

  Color get _severityColor {
    switch (scanResult.severity) {
      case 'high':
        return AppColors.red;
      case 'moderate':
        return AppColors.orange;
      default:
        return AppColors.success;
    }
  }

  String get _severityLabel {
    switch (scanResult.severity) {
      case 'high':
        return 'High severity — act within 2-3 days';
      case 'moderate':
        return 'Moderate severity — monitor closely';
      default:
        return 'Low severity — routine care recommended';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidencePercent = (scanResult.confidence * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnosis Result')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: ListView(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: double.infinity,
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (scanResult.imageUrl.isNotEmpty)
                      Image.network(
                        scanResult.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.greenLightBg,
                          child: const Icon(Icons.broken_image_outlined, size: 40, color: AppColors.greenAccent),
                        ),
                      )
                    else
                      Container(color: AppColors.greenLightBg, child: const Icon(Icons.image_outlined, size: 40, color: AppColors.greenAccent)),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.greenDark.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 11, color: AppColors.success),
                            SizedBox(width: 3),
                            Text('Saved to History', style: TextStyle(color: Colors.white, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ---- Low-confidence state: don't confidently show a
            // possibly-wrong diagnosis. Be upfront instead. ----
            if (scanResult.isLowConfidence) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brownBg,
                  border: Border.all(color: AppColors.orange),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline, color: AppColors.brown, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Couldn't confidently identify this",
                            style: TextStyle(color: AppColors.brown, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(scanResult.symptoms, style: const TextStyle(color: AppColors.brown, fontSize: 11.5, height: 1.5)),
                    const SizedBox(height: 4),
                    Text(
                      'Model confidence: $confidencePercent% (below the reliability threshold)',
                      style: const TextStyle(color: AppColors.brown, fontSize: 10, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
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
                    const Text('This model currently supports:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['Apple', 'Corn', 'Grape', 'Potato', 'Tomato']
                          .map((c) => Chip(
                                label: Text(c, style: const TextStyle(fontSize: 10)),
                                backgroundColor: AppColors.greenLightBg,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retake Photo'),
              ),
            ] else ...[
              // ---- Normal, confident diagnosis display ----
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scanResult.diagnosis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.greenDark)),
                        Text(scanResult.cropType, style: const TextStyle(fontSize: 11, color: AppColors.greenMid)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.brownBg, borderRadius: BorderRadius.circular(10)),
                    child: Text('$confidencePercent% match', style: const TextStyle(color: AppColors.brown, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _severityColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_severityLabel, style: TextStyle(color: AppColors.brown, fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('SYMPTOMS DETECTED', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(scanResult.symptoms, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11.5, height: 1.5)),
              if ((scanResult.userNotes ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('YOUR NOTES', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(scanResult.userNotes!, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 16),
              Container(
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
                        const Icon(Icons.medical_services_outlined, color: AppColors.greenMain, size: 15),
                        const SizedBox(width: 6),
                        const Text('Recommended Treatment', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(scanResult.treatment, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prediction from an on-device model, evaluated at 95.3% accuracy on a held-out '
                'test set. Not a substitute for expert diagnosis in uncertain or severe cases.',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 8.5, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _toggleListen,
                icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up_outlined, size: 16),
                label: Text(_isSpeaking ? 'Stop' : 'Listen to Result (English)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SuppliersScreen(
                      initialSearchQuery: scanResult.treatmentKeyword.isNotEmpty
                          ? scanResult.treatmentKeyword
                          : null,
                    ),
                  ),
                ),
                icon: const Icon(Icons.storefront_outlined, size: 17),
                label: const Text('Find Suppliers for Treatment'),
              ),
            ],
            const SizedBox(height: 10),
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    const WidgetSpan(
                      child: Icon(Icons.history, size: 12, color: AppColors.greenMid),
                      alignment: PlaceholderAlignment.middle,
                    ),
                    TextSpan(text: '  View this scan anytime in ', style: theme.textTheme.bodySmall),
                    const TextSpan(text: 'History', style: TextStyle(color: AppColors.greenMain, fontWeight: FontWeight.w700)),
                  ],
                ),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}