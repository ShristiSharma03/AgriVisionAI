import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _noteController = TextEditingController();

  bool _pushNotifications = true;
  bool _dataSharing = true;
  bool _prefsLoaded = false;
  bool _noteDirty = false;
  bool _reminderSessionDirty = false;

  int _reminderHour = 7;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _noteController.addListener(() {
      if (!_noteDirty) setState(() => _noteDirty = true);
    });
  }

  @override
  void dispose() {
    if (_reminderSessionDirty && _pushNotifications) {
      _notificationService.logReminderSummary(
        hour: _reminderHour,
        minute: _reminderMinute,
        note: _noteController.text,
      );
    }
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    final reminder = await _notificationService.getReminderSettings();
    if (!mounted) return;
    setState(() {
      _pushNotifications = enabled;
      _reminderHour = reminder.hour;
      _reminderMinute = reminder.minute;
      _noteController.text = reminder.note;
      _prefsLoaded = true;
      _noteDirty = false;
    });
  }

  Future<void> _togglePushNotifications(bool value) async {
    setState(() => _pushNotifications = value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationService.pushNotificationsPrefKey, value);

    if (value) {
      await _notificationService.scheduleDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
        note: _noteController.text,
      );
      await _notificationService.logReminderTurnedOn(_reminderHour, _reminderMinute);
      if (mounted) {
        final canSchedule = await _notificationService.canScheduleExactAlarms();
        if (canSchedule == false && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('alarms_permission_warning')),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      await _notificationService.cancelDailyReminder();
      _reminderSessionDirty = false;
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    setState(() {
      _reminderHour = picked.hour;
      _reminderMinute = picked.minute;
    });

    if (_pushNotifications) {
      await _notificationService.scheduleDailyReminder(
        hour: picked.hour,
        minute: picked.minute,
        note: _noteController.text,
      );
      _reminderSessionDirty = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('reminder_time_updated'))),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    await _notificationService.saveReminderNote(_noteController.text);

    if (_pushNotifications) {
      await _notificationService.scheduleDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
        note: _noteController.text,
      );
      _reminderSessionDirty = true;
    }

    if (mounted) {
      setState(() => _noteDirty = false);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('note_saved'))),
      );
    }
  }

  Future<void> _showChangePasswordSheet() async {
    final emailController = TextEditingController(text: AuthService().currentUser?.email ?? '');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('change_password_sheet_title'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                context.tr('change_password_sheet_body'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                readOnly: true,
                decoration: InputDecoration(labelText: context.tr('email'), prefixIcon: const Icon(Icons.mail_outline)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final result = await AuthService().sendPasswordReset(emailController.text);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.isSuccess ? context.tr('login_password_reset_sent') : context.tr(result.errorKey!)),
                    ),
                  );
                },
                child: Text(context.tr('send_reset_link')),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUpdateEmailSheet() async {
    final passwordController = TextEditingController();
    final newEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSending = false;
    bool obscurePassword = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('update_email_sheet_title'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(context.tr('update_email_sheet_body'), style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: context.tr('current_password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setSheetState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return context.tr('login_password_required');
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: newEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: context.tr('new_email'),
                        prefixIcon: const Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return context.tr('login_email_required');
                        if (!value.contains('@')) return context.tr('login_email_invalid');
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSending
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isSending = true);
                              final result = await AuthService().updateEmail(
                                currentPassword: passwordController.text,
                                newEmail: newEmailController.text,
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.isSuccess ? context.tr('update_email_link_sent') : context.tr(result.errorKey!),
                                  ),
                                ),
                              );
                            },
                      child: isSending
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(context.tr('send_verification_link')),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(context.tr('appearance'), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    icon: Icons.wb_sunny_outlined,
                    label: context.tr('light'),
                    active: !themeProvider.isDarkMode,
                    onTap: () => context.read<ThemeProvider>().setTheme(ThemeMode.light),
                  ),
                ),
                Expanded(
                  child: _ModeButton(
                    icon: Icons.nightlight_outlined,
                    label: context.tr('dark'),
                    active: themeProvider.isDarkMode,
                    onTap: () => context.read<ThemeProvider>().setTheme(ThemeMode.dark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(context.tr('account'), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _Row(icon: Icons.lock_outline, label: context.tr('change_password'), onTap: _showChangePasswordSheet),
          const SizedBox(height: 6),
          _Row(
            icon: Icons.mail_outline,
            label: context.tr('update_email'),
            onTap: _showUpdateEmailSheet,
          ),
          const SizedBox(height: 20),
          Text(context.tr('preferences'), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _SwitchRow(
            icon: Icons.notifications_outlined,
            label: context.tr('push_notifications'),
            value: _pushNotifications,
            onChanged: _prefsLoaded ? _togglePushNotifications : null,
          ),
          if (_pushNotifications) ...[
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: _prefsLoaded ? _pickReminderTime : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.greenMain, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(context.tr('reminder_time'), style: const TextStyle(fontSize: 11)),
                    ),
                    Text(
                      _notificationService.formatTime(_reminderHour, _reminderMinute),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 15),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('reminder_note_label'),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 9.5),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: context.tr('reminder_note_hint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _noteDirty ? _saveNote : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      child: Text(context.tr('save_note')),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          _SwitchRow(
            icon: Icons.water_drop_outlined,
            label: context.tr('data_sharing'),
            value: _dataSharing,
            onChanged: (v) => setState(() => _dataSharing = v),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeButton({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppColors.greenMain : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Row({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
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
            const Icon(Icons.chevron_right, size: 15),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.greenMain, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 10.5))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.greenMain,
          ),
        ],
      ),
    );
  }
}