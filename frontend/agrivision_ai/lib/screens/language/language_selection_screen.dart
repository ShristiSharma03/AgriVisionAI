import 'package:flutter/material.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  static const List<(String code, String label, String native)> _languages = [
    ('en', 'English', 'English'),
    ('hi', 'Hindi', 'हिंदी'),
    ('mr', 'Marathi', 'मराठी'),
  ];

  String? _selectedCode;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // InheritedWidget lookups (LocalizationScope.of) aren't safe to
    // call in initState() — Flutter explicitly requires them to happen
    // here or later, once dependencies are actually available. The
    // _selectedCode == null guard ensures this only runs once, not on
    // every dependency change.
    _selectedCode ??= LocalizationScope.of(context).languageCode;
  }

  Future<void> _save() async {
    if (_selectedCode == null) return;
    setState(() => _isSaving = true);
    await LocalizationScope.of(context).setLanguage(_selectedCode!);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_selectedCode == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _languages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final (code, label, native) = _languages[index];
                final selected = _selectedCode == code;
                return Material(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selectedCode = code),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: selected ? AppColors.greenMain : theme.dividerColor, width: selected ? 1.5 : 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(native, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                Text(label, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          if (selected) const Icon(Icons.check_circle, color: AppColors.greenMain, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}