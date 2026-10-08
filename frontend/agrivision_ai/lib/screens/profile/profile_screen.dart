import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';
import '../language/language_selection_screen.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  String? _location;
  bool _isLoadingLocation = true;

  static const Map<String, String> _languageNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'mr': 'मराठी',
  };

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoadingLocation = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final location = doc.data()?['location'] as String?;
      if (mounted) {
        setState(() {
          _location = (location != null && location.trim().isNotEmpty) ? location.trim() : null;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final displayName = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : context.tr('farmer_fallback_name');
    final email = user?.email ?? '';
    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'F';

    // Rebuilds whenever the language changes, since this reads from
    // LocalizationScope — keeps the trailing label in sync with
    // whatever the farmer actually picked, instead of a fixed string.
    final localization = LocalizationScope.of(context);
    final currentLanguageLabel = _languageNames[localization.languageCode] ?? 'English';

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.greenDark,
            padding: const EdgeInsets.fromLTRB(4, 4, 18, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Text(context.tr('profile_title'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.greenAccent,
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9.5)),
                const SizedBox(height: 8),
                if (_isLoadingLocation)
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  )
                else if (_location != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(_location!, style: const TextStyle(color: Colors.white, fontSize: 9)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _SettingsRow(
                  icon: Icons.person_outline,
                  label: context.tr('edit_profile'),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    if (mounted) _loadLocation();
                  },
                ),
                _SettingsRow(
                  icon: Icons.settings_outlined,
                  label: context.tr('settings_title'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                _SettingsRow(
                  icon: Icons.language,
                  label: context.tr('language'),
                  trailing: currentLanguageLabel,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LanguageSelectionScreen())),
                ),
                _SettingsRow(
                  icon: Icons.help_outline,
                  label: context.tr('help_support'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                ),
                const SizedBox(height: 20),
                InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(context.tr('log_out')),
                        content: Text(context.tr('log_out_confirm')),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.tr('cancel'))),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(context.tr('log_out'), style: const TextStyle(color: AppColors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await _authService.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBEAEA),
                      border: Border.all(color: const Color(0xFFF3B4B4)),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: AppColors.red, size: 16),
                        const SizedBox(width: 9),
                        Text(context.tr('log_out'), style: const TextStyle(color: AppColors.red, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.greenMain, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
              if (trailing != null) ...[
                Text(trailing!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 9.5)),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}