import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/localization_service.dart';

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _sendSupportEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@agrivisionai.app', // TODO: replace with your real support email
      query: 'subject=AgriVision AI Support Request',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  List<_FaqItem> _faqItems(BuildContext context) => [
        _FaqItem(context.tr('faq_1_q'), context.tr('faq_1_a')),
        _FaqItem(context.tr('faq_2_q'), context.tr('faq_2_a')),
        _FaqItem(context.tr('faq_3_q'), context.tr('faq_3_a')),
        _FaqItem(context.tr('faq_4_q'), context.tr('faq_4_a')),
        _FaqItem(context.tr('faq_5_q'), context.tr('faq_5_a')),
        _FaqItem(context.tr('faq_6_q'), context.tr('faq_6_a')),
        _FaqItem(context.tr('faq_7_q'), context.tr('faq_7_a')),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faqItems = _faqItems(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('help_support'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.tr('faq_section_title'), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...faqItems.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  title: Text(item.question, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  expandedAlignment: Alignment.centerLeft,
                  children: [
                    Text(item.answer, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11.5, height: 1.5)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(context.tr('still_need_help'), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _sendSupportEmail,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline, color: AppColors.greenMain, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('email_support'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        const Text('support@agrivisionai.app', style: TextStyle(fontSize: 10.5, color: AppColors.greenMid)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.greenLightBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.greenMid, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('help_disclaimer'),
                    style: const TextStyle(fontSize: 10.5, color: AppColors.greenDark, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(context.tr('app_version_label'), style: theme.textTheme.bodySmall?.copyWith(fontSize: 9)),
          ),
        ],
      ),
    );
  }
}