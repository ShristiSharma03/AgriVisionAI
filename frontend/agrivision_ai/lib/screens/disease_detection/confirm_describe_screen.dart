import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/services/disease_service.dart';
import '../../core/services/voice_service.dart';
import '../../core/theme/app_colors.dart';
import 'result_screen.dart';

class ConfirmDescribeScreen extends StatefulWidget {
  final String imagePath;
  const ConfirmDescribeScreen({super.key, required this.imagePath});

  @override
  State<ConfirmDescribeScreen> createState() => _ConfirmDescribeScreenState();
}

class _ConfirmDescribeScreenState extends State<ConfirmDescribeScreen> {
  final _descriptionController = TextEditingController();
  final DiseaseService _diseaseService = DiseaseService();
  final VoiceService _voiceService = VoiceService();

  bool _isAnalyzing = false;
  bool _isListening = false;
  String _voiceLanguageCode = 'en';
  // Text already in the field before this listening session started —
  // new speech gets appended after this, so tapping the mic again
  // doesn't erase what was already typed/spoken.
  String _textBeforeListening = '';

  @override
  void initState() {
    super.initState();
    _loadVoiceLanguage();
  }

  Future<void> _loadVoiceLanguage() async {
    final code = await _voiceService.getSavedLanguageCode();
    if (mounted) setState(() => _voiceLanguageCode = code);
  }

  Future<void> _selectVoiceLanguage(String code) async {
    setState(() => _voiceLanguageCode = code);
    await _voiceService.saveLanguageCode(code);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      // Mark listening as stopped immediately (before awaiting the
      // actual stop call) so the onResult guard below starts ignoring
      // results right away. The speech engine can occasionally send
      // one more "corrected" transcript slightly after stop() is
      // called, sometimes shorter than what was already captured —
      // without this guard, that stray result was overwriting the
      // farmer's full spoken text with just a fragment.
      setState(() => _isListening = false);
      await _voiceService.stopListening();
      return;
    }

    _textBeforeListening = _descriptionController.text;
    final started = await _voiceService.startListening(
      languageCode: _voiceLanguageCode,
      onResult: (text) {
        if (!_isListening) return; // ignore stray results after manual stop
        final combined = _textBeforeListening.isEmpty ? text : '$_textBeforeListening $text';
        _descriptionController.text = combined;
        _descriptionController.selection = TextSelection.collapsed(offset: combined.length);
      },
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice input error: $error')),
          );
        }
      },
    );

    if (!started) return;

    setState(() => _isListening = true);
  }

  Future<void> _analyze() async {
    if (_isListening) {
      setState(() => _isListening = false);
      await _voiceService.stopListening();
    }

    setState(() => _isAnalyzing = true);

    try {
      final result = await _diseaseService.analyzeAndSave(
        imageFile: File(widget.imagePath),
        userNotes: _descriptionController.text,
      );

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResultScreen(scanResult: result)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(widget.imagePath);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan a Crop')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 190,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (file.existsSync())
                            Image.file(file, fit: BoxFit.cover)
                          else
                            Container(color: AppColors.greenLightBg, child: const Icon(Icons.image_outlined, size: 40, color: AppColors.greenAccent)),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 12, color: AppColors.success),
                                  SizedBox(width: 3),
                                  Text('Photo captured', style: TextStyle(color: Colors.white, fontSize: 9)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('ADD MORE DETAILS (OPTIONAL)', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Describing symptoms helps improve accuracy', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Leaves are curling and turning yellow near the edges...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: theme.dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('OR', style: theme.textTheme.bodySmall),
                      ),
                      Expanded(child: Divider(color: theme.dividerColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('SPEAK IN', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 9.5)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: kVoiceLanguages.map((lang) {
                      final selected = lang.code == _voiceLanguageCode;
                      return ChoiceChip(
                        label: Text(lang.label, style: const TextStyle(fontSize: 10.5)),
                        selected: selected,
                        onSelected: (_) => _selectVoiceLanguage(lang.code),
                        selectedColor: AppColors.greenMain,
                        labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _toggleVoiceInput,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: _isListening ? AppColors.greenMain : theme.dividerColor, width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                        color: _isListening ? AppColors.greenLightBg : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _isListening ? AppColors.red : AppColors.greenMain,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_isListening ? Icons.stop : Icons.mic_none, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isListening ? 'Listening... tap to stop' : 'Speak instead',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  _isListening ? 'Say your symptoms now' : 'Tap and describe in your language',
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 9.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pinned footer — always visible, never gets pushed off-screen
          // by content length or the keyboard.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyze,
              child: _isAnalyzing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Analyze Crop'),
            ),
          ),
        ],
      ),
    );
  }
}