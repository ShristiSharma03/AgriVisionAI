import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide UI text translation for English, Hindi, and Marathi.
/// Separate from VoiceService's language handling (which is about
/// speech recognition locales) — this is about which language labels,
/// buttons, and messages are displayed in.
///
/// Does NOT cover: the disease catalog content, AI Assistant replies
/// (the LLM already replies in-language on its own), or any
/// Firestore-stored data like community posts — only static app UI text.
class LocalizationService extends ChangeNotifier {
  static const String _prefKey = 'app_language_code';
  String _languageCode = 'en';

  String get languageCode => _languageCode;

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_prefKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (code == _languageCode) return;
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    notifyListeners();
  }

  /// Looks up [key] in the current language's table, falling back to
  /// English, then to the key itself if truly nothing is found (so a
  /// missing translation shows up as an obvious placeholder rather
  /// than crashing).
  String translate(String key) {
    return _translations[_languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }
}

/// Convenience extension so call sites can write `context.tr('key')`
/// instead of the more verbose Provider lookup.
extension LocalizationContext on BuildContext {
  String tr(String key) => LocalizationScope.of(this).translate(key);
}

/// Small wrapper so widgets can access the LocalizationService without
/// importing `provider` directly in every file — keeps this swappable
/// later if the app's state management approach changes.
class LocalizationScope {
  static LocalizationService of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LocalizationInherited>()!.service;
  }
}

class _LocalizationInherited extends InheritedNotifier<LocalizationService> {
  const _LocalizationInherited({required LocalizationService service, required super.child})
      : super(notifier: service);

  LocalizationService get service => notifier!;

  @override
  bool updateShouldNotify(_LocalizationInherited oldWidget) => true;
}

/// Wrap the app's root with this, above MaterialApp, passing the same
/// LocalizationService instance used elsewhere.
class LocalizationProvider extends StatelessWidget {
  final LocalizationService service;
  final Widget child;
  const LocalizationProvider({super.key, required this.service, required this.child});

  @override
  Widget build(BuildContext context) {
    return _LocalizationInherited(service: service, child: child);
  }
}

/// Translation tables. Add new keys here as more screens get migrated.
/// Keep keys short, snake_case, and grouped by screen via comments so
/// this stays navigable as it grows.
final Map<String, Map<String, String>> _translations = {
  'en': {
    // ---- Home screen ----
    'hi_greeting': 'Hi,',
    'scan_a_crop': 'Scan a Crop',
    'scan_a_crop_subtitle': 'Crop Doctor - detect disease instantly',
    'quick_actions': 'QUICK ACTIONS',
    'history': 'History',
    'community': 'Community',
    'suppliers': 'Suppliers',
    'ai_chat': 'AI Chat',
    'weather': 'Weather',
    'all_crops': 'All Crops',
    'nav_home': 'Home',
    'nav_scan': 'Scan',
    'nav_history': 'History',
    'nav_community': 'Community',
    'nav_profile': 'Profile',
    'tap_for_spray_timeline': 'Tap for full spray timeline',
    'loading_weather': 'Loading weather...',
    'weather_unavailable': 'Weather unavailable',
    'coming_soon': 'coming soon',
    'optimal': 'Optimal',
    'moderate': 'Moderate',
    'unfavorable': 'Unfavorable',

    // ---- Settings screen ----
    'settings_title': 'Settings',
    'appearance': 'APPEARANCE',
    'light': 'Light',
    'dark': 'Dark',
    'account': 'ACCOUNT',
    'change_password': 'Change Password',
    'update_email': 'Update Email',
    'preferences': 'PREFERENCES',
    'push_notifications': 'Push Notifications',
    'reminder_time': 'Reminder time',
    'reminder_note_label': 'Why are you setting this reminder? (optional)',
    'reminder_note_hint': 'e.g. Remind me before my morning spray round',
    'save_note': 'Save Note',
    'note_saved': 'Note saved.',
    'data_sharing': 'Data Sharing for Model Improvement',
    'reminder_time_updated': 'Reminder time updated.',
    'alarms_permission_warning': 'Please allow "Alarms & reminders" for this app in system settings, or the reminder won\'t fire.',
    'change_password_sheet_title': 'Change Password',
    'change_password_sheet_body': "We'll send a password reset link to your email.",
    'send_reset_link': 'Send Reset Link',
    
    // ---- Weather screen ----
    'weather_title': 'Weather & Crop Risk',
    'tab_today': 'Today',
    'tab_calendar': 'Calendar',
    'try_again': 'Try Again',
    'spray_conditions_prefix': 'SPRAY CONDITIONS — NEXT',
    'hours_suffix': 'HOURS',
    'crop_risk_today': 'CROP RISK TODAY',
    'weather_humidity_temp_template': "Based on today's humidity ({humidity}%) and temperature ({temp}°C)",
    'risk_high': 'High',
    'risk_moderate': 'Moderate',
    'risk_low': 'Low',
    'risk_suffix': 'risk',
    'legend_high_risk': 'High risk',
    'weather_model_disclaimer': 'Spray timing and disease-risk indicators are calculated from live humidity, wind, and rain-probability data using a simple rule-based estimate, not a trained model.',
    'calendar_intro': "OpenWeather's free tier provides a 5-day forecast — shown below with disease-risk estimates.",
    'no_forecast_data': 'No forecast data available.',
    'metric_humidity': 'Humidity',
    'metric_wind': 'Wind',
    'metric_visibility': 'Visibility',
    'weekday_mon': 'Mon', 'weekday_tue': 'Tue', 'weekday_wed': 'Wed', 'weekday_thu': 'Thu', 'weekday_fri': 'Fri', 'weekday_sat': 'Sat', 'weekday_sun': 'Sun',
    'crop_tomato': 'Tomato', 'crop_potato': 'Potato', 'crop_corn': 'Corn', 'crop_rice': 'Rice', 'crop_grape': 'Grape', 'crop_apple': 'Apple', 'crop_sugarcane': 'Sugarcane', 'crop_wheat': 'Wheat', 'crop_citrus': 'Citrus',

        // ---- Community screen ----
    'cancel': 'Cancel',
    'delete': 'Delete',
    'comments': 'Comments',
    'something_went_wrong': 'Something went wrong: {error}',
    'community_new_post': 'New Post',
    'community_crop_label': 'Crop',
    'community_post_hint': 'Ask a question or share a tip with other farmers...',
    'community_post_button': 'Post',
    'community_failed_to_post': 'Failed to post: {error}',
    'community_filter_by_crop': 'Filter by crop',
    'community_delete_post_title': 'Delete post?',
    'community_delete_post_message': "This will remove your post and all its comments. This can't be undone.",
    'community_delete_comment_title': 'Delete comment?',
    'community_delete_comment_message': "This can't be undone.",
    'community_failed_delete_post': 'Failed to delete post: {error}',
    'community_failed_delete_comment': 'Failed to delete comment: {error}',
    'community_no_comments': 'No comments yet. Be the first to reply!',
    'community_write_reply_hint': 'Write a reply...',
    'community_failed_reply': 'Failed to reply: {error}',
    'community_no_posts_for': 'No posts for {crop} yet. Be the first to share!',
    'community_replies_suffix': 'replies',

        // ---- Profile screen ----
    'profile_title': 'Profile',
    'farmer_fallback_name': 'Farmer',
    'edit_profile': 'Edit Profile',
    'language': 'Language',
    'help_support': 'Help & Support',
    'log_out': 'Log Out',
    'log_out_confirm': 'Are you sure you want to log out?',

        // ---- Edit profile screen ----
    'edit_profile_updated': 'Profile updated',
    'edit_profile_save_error': 'Could not save changes: {error}',
    'edit_profile_full_name': 'Full name',
    'edit_profile_name_validator': 'Please enter your name',
    'email': 'Email',
    'edit_profile_email_helper': 'Email can be changed in Settings',
    'edit_profile_location_label': 'Location / District',
    'edit_profile_location_hint': 'e.g. Kolhapur District',
    'save_changes': 'Save Changes',

        // ---- Help & Support screen ----
    'faq_section_title': 'FREQUENTLY ASKED QUESTIONS',
    'faq_1_q': 'How accurate is the crop disease scanner?',
    'faq_1_a': 'The AI model is tested at about 95% accuracy on its training images, for the crops it currently supports: Apple, Corn, Grape, Potato, and Tomato. Real field photos can vary more, so if the app shows "Couldn\'t confidently identify this," try retaking the photo in better light or ask a local agriculture expert.',
    'faq_2_q': 'Which crops can the app currently detect diseases for?',
    'faq_2_a': 'Right now, the camera scanner supports Apple, Corn, Grape, Potato, and Tomato. Other crops shown in the "All Crops" section are for reference information only — disease detection for those is planned for a future update.',
    'faq_3_q': 'Does the app work without internet?',
    'faq_3_a': 'Disease scanning works offline once the app is installed, since the AI model runs directly on your phone. Weather, Community, and the AI Assistant chat need an internet connection.',
    'faq_4_q': 'How do I change the app language?',
    'faq_4_a': 'Go to Profile > Language, or tap the language icon on the Home screen. AgriVision AI currently supports English, Hindi, and Marathi.',
    'faq_5_q': 'Is my scan history private?',
    'faq_5_a': 'Yes. Your scan history and community posts are tied to your account and only visible to you, except for what you choose to post publicly in the Community section.',
    'faq_6_q': 'How do I delete a scan from my history?',
    'faq_6_a': 'Open Scan History, then swipe left on any scan or tap the trash icon on it, and confirm the deletion.',
    'faq_7_q': 'Can I switch between light and dark mode?',
    'faq_7_a': 'Yes — go to Profile > Settings > Appearance and choose Light or Dark.',
    'still_need_help': 'STILL NEED HELP?',
    'email_support': 'Email Support',
    'help_disclaimer': 'For urgent, severe crop disease outbreaks, please also contact your local agriculture extension office — the app is a helpful tool, but not a replacement for expert, in-person advice.',
    'app_version_label': 'AgriVision AI · Version 1.0.0',

        // ---- Login screen ----
    'login_enter_email_first': 'Enter your email above first.',
    'login_password_reset_sent': 'Password reset email sent.',
    'welcome_back': 'Welcome back',
    'login_subtitle': 'Log in to manage your farm',
    'login_email_required': 'Please enter your email',
    'login_email_invalid': 'Please enter a valid email',
    'password': 'Password',
    'login_password_required': 'Please enter your password',
    'forgot_password': 'Forgot password?',
    'log_in': 'Log in',
    'login_no_account': "Don't have an account?",
    'register': 'Register',

        // ---- Registration screen ----
    'create_account': 'Create account',
    'join_app': 'Join AgriVision AI',
    'registration_subtitle': 'Start protecting your crops today',
    'full_name': 'Full name',
    'registration_name_required': 'Please enter your name',
    'registration_password_required': 'Please enter a password',
    'registration_password_min_length': 'Password must be at least 6 characters',
    'confirm_password': 'Confirm password',
    'registration_passwords_mismatch': 'Passwords do not match',

        // ---- Auth errors ----
    'auth_error_registration_failed': 'Registration failed. Please try again.',
    'auth_error_generic': 'Something went wrong. Please try again.',
    'auth_error_email_in_use': 'An account already exists for that email.',
    'auth_error_invalid_email': 'That email address looks invalid.',
    'auth_error_weak_password': 'Password should be at least 6 characters.',
    'auth_error_invalid_credential': 'Incorrect email or password.',
    'auth_error_too_many_requests': 'Too many attempts. Please try again later.',
    'auth_error_network': 'Network error. Check your connection and try again.',

        // ---- Update email sheet ----
    'update_email_sheet_title': 'Update Email',
    'update_email_sheet_body': "Enter your current password and new email. We'll send a verification link to confirm the change.",
    'current_password': 'Current password',
    'new_email': 'New email',
    'send_verification_link': 'Send Verification Link',
    'update_email_link_sent': 'Verification link sent. Check your new email to confirm the change.',
    'auth_error_requires_recent_login': 'For security, please log out and log back in, then try again.',

        // ---- Suppliers screen ----
    'nearby_suppliers': 'Nearby Suppliers',
    'suppliers_search_hint': 'Search fungicide, seeds, tools...',
    'suppliers_looking_for': 'Looking for: {query}',
    'suppliers_shops_found_singular': '{count} shop found nearby',
    'suppliers_shops_found_plural': '{count} shops found nearby',
    'suppliers_search_failed': 'Search failed: {error}. Showing previous results.',
    'suppliers_none_found': 'No shops found within {radius} km. Map data coverage varies by area.',
    'suppliers_search_wider': 'Search wider ({radius} km)',
    'searching': 'Searching...',
    'suppliers_no_maps_app': 'Could not open a maps app on this device.',
    'away_suffix': 'away',
    'get_directions': 'Get Directions',

        // ---- Notifications screen ----
    'notifications_title': 'Notifications',
    'clear_all': 'Clear all',
    'notifications_clear_confirm_title': 'Clear all notifications?',
    'notifications_clear_confirm_body': "This can't be undone.",
    'clear': 'Clear',
    'notifications_empty': 'No notifications yet. Scan confirmations, weather alerts, and your daily reminder will show up here.',

        // ---- AI Assistant screen ----
    'ai_assistant_name': 'AgriVision Assistant',
    'ai_assistant_status': '● Online · Ask me anything',
    'new_chat': 'New Chat',
    'chat_history': 'Chat History',
    'no_conversations_yet': 'No conversations yet',
    'typing_indicator': 'Typing…',
    'stop_reading': 'Stop reading',
    'read_last_reply_aloud': 'Read last reply aloud',
    'open_scanner': 'Open Scanner',
    'treatment_tips_chip': 'Treatment tips',
    'treatment_tips_query': 'Give me general treatment tips for common crop diseases',
    'listening_hint': 'Listening...',
    'type_question_hint': 'Type your question...',
    'ai_welcome_message': "Namaste! I'm your AgriVision Assistant. Ask me about crop diseases, treatment, weather, or anything else — in English, Hindi, or Marathi.",
    'ai_voice_input_error': 'Voice input error: {error}',
    'ai_connection_error': "Sorry, I couldn't reach the assistant right now. Please check your connection and try again. ({error})",

        // ---- History screen ----
    'scan_history_title': 'Scan History',
    'history_today': 'Today, {time}',
    'history_yesterday': 'Yesterday, {time}',
    'history_days_ago': '{days} days ago, {time}',
    'history_delete_title': 'Delete this scan?',
    'history_delete_body': 'This will permanently remove the scan and its photo. This cannot be undone.',
    'history_empty': 'No scans yet — tap "Scan a Crop" on Home to get started.',
    'history_failed_to_delete': 'Failed to delete: {error}',
    'unclear_photo': 'Unclear photo',
    'history_confidence_label': '{percent}% confidence',
    'history_crop_match_label': '{crop} · {percent}% match',
  },

  'hi': {
    // ---- Home screen ----
    'hi_greeting': 'नमस्ते,',
    'scan_a_crop': 'फसल स्कैन करें',
    'scan_a_crop_subtitle': 'क्रॉप डॉक्टर - तुरंत बीमारी पहचानें',
    'quick_actions': 'त्वरित कार्य',
    'history': 'इतिहास',
    'community': 'समुदाय',
    'suppliers': 'आपूर्तिकर्ता',
    'ai_chat': 'एआई चैट',
    'weather': 'मौसम',
    'all_crops': 'सभी फसलें',
    'nav_home': 'होम',
    'nav_scan': 'स्कैन',
    'nav_history': 'इतिहास',
    'nav_community': 'समुदाय',
    'nav_profile': 'प्रोफ़ाइल',
    'tap_for_spray_timeline': 'पूरा स्प्रे समय देखने के लिए टैप करें',
    'loading_weather': 'मौसम लोड हो रहा है...',
    'weather_unavailable': 'मौसम उपलब्ध नहीं',
    'coming_soon': 'जल्द आ रहा है',
    'optimal': 'उपयुक्त',
    'moderate': 'मध्यम',
    'unfavorable': 'प्रतिकूल',

    // ---- Settings screen ----
    'settings_title': 'सेटिंग्स',
    'appearance': 'दिखावट',
    'light': 'लाइट',
    'dark': 'डार्क',
    'account': 'खाता',
    'change_password': 'पासवर्ड बदलें',
    'update_email': 'ईमेल अपडेट करें',
    'preferences': 'प्राथमिकताएं',
    'push_notifications': 'पुश सूचनाएं',
    'reminder_time': 'याद दिलाने का समय',
    'reminder_note_label': 'आप यह याद क्यों सेट कर रहे हैं? (वैकल्पिक)',
    'reminder_note_hint': 'जैसे, सुबह की स्प्रे से पहले याद दिलाएं',
    'save_note': 'नोट सहेजें',
    'note_saved': 'नोट सहेजा गया।',
    'data_sharing': 'मॉडल सुधार के लिए डेटा साझा करना',
    'reminder_time_updated': 'याद दिलाने का समय अपडेट हुआ।',
    'alarms_permission_warning': 'कृपया सिस्टम सेटिंग्स में इस ऐप के लिए "अलार्म और अनुस्मारक" की अनुमति दें, अन्यथा रिमाइंडर काम नहीं करेगा।',
    'change_password_sheet_title': 'पासवर्ड बदलें',
    'change_password_sheet_body': 'हम आपके ईमेल पर पासवर्ड रीसेट लिंक भेजेंगे।',
    'send_reset_link': 'रीसेट लिंक भेजें',

     // ---- Weather screen ----
    'weather_title': 'मौसम और फसल जोखिम',
    'tab_today': 'आज',
    'tab_calendar': 'कैलेंडर',
    'try_again': 'फिर कोशिश करें',
    'spray_conditions_prefix': 'स्प्रे की स्थिति — अगले',
    'hours_suffix': 'घंटे',
    'crop_risk_today': 'आज फसल जोखिम',
    'weather_humidity_temp_template': 'आज की आर्द्रता ({humidity}%) और तापमान ({temp}°C) के आधार पर',
    'risk_high': 'उच्च',
    'risk_moderate': 'मध्यम',
    'risk_low': 'कम',
    'risk_suffix': 'जोखिम',
    'legend_high_risk': 'उच्च जोखिम',
    'weather_model_disclaimer': 'स्प्रे का समय और रोग-जोखिम संकेतक लाइव आर्द्रता, हवा और वर्षा-संभावना डेटा से एक सरल नियम-आधारित अनुमान का उपयोग करके निकाले जाते हैं, प्रशिक्षित मॉडल से नहीं।',
    'calendar_intro': 'OpenWeather का मुफ़्त संस्करण 5-दिन का पूर्वानुमान देता है — नीचे रोग-जोखिम अनुमानों के साथ दिखाया गया है।',
    'no_forecast_data': 'कोई पूर्वानुमान डेटा उपलब्ध नहीं है।',
    'metric_humidity': 'आर्द्रता',
    'metric_wind': 'हवा',
    'metric_visibility': 'दृश्यता',
    'weekday_mon': 'सोम', 'weekday_tue': 'मंगल', 'weekday_wed': 'बुध', 'weekday_thu': 'गुरु', 'weekday_fri': 'शुक्र', 'weekday_sat': 'शनि', 'weekday_sun': 'रवि',
    'crop_tomato': 'टमाटर', 'crop_potato': 'आलू', 'crop_corn': 'मक्का', 'crop_rice': 'चावल', 'crop_grape': 'अंगूर', 'crop_apple': 'सेब', 'crop_sugarcane': 'गन्ना', 'crop_wheat': 'गेहूं', 'crop_citrus': 'खट्टे फल',

        // ---- Community screen ----
    'cancel': 'रद्द करें',
    'delete': 'हटाएं',
    'comments': 'टिप्पणियां',
    'something_went_wrong': 'कुछ गलत हो गया: {error}',
    'community_new_post': 'नई पोस्ट',
    'community_crop_label': 'फसल',
    'community_post_hint': 'अन्य किसानों से सवाल पूछें या सुझाव साझा करें...',
    'community_post_button': 'पोस्ट करें',
    'community_failed_to_post': 'पोस्ट करने में विफल: {error}',
    'community_filter_by_crop': 'फसल के अनुसार फ़िल्टर करें',
    'community_delete_post_title': 'पोस्ट हटाएं?',
    'community_delete_post_message': 'इससे आपकी पोस्ट और उसकी सभी टिप्पणियां हट जाएंगी। यह पूर्ववत नहीं किया जा सकता।',
    'community_delete_comment_title': 'टिप्पणी हटाएं?',
    'community_delete_comment_message': 'यह पूर्ववत नहीं किया जा सकता।',
    'community_failed_delete_post': 'पोस्ट हटाने में विफल: {error}',
    'community_failed_delete_comment': 'टिप्पणी हटाने में विफल: {error}',
    'community_no_comments': 'अभी तक कोई टिप्पणी नहीं। सबसे पहले जवाब दें!',
    'community_write_reply_hint': 'जवाब लिखें...',
    'community_failed_reply': 'जवाब भेजने में विफल: {error}',
    'community_no_posts_for': '{crop} के लिए अभी कोई पोस्ट नहीं है। सबसे पहले साझा करें!',
    'community_replies_suffix': 'जवाब',

        // ---- Profile screen ----
    'profile_title': 'प्रोफ़ाइल',
    'farmer_fallback_name': 'किसान',
    'edit_profile': 'प्रोफ़ाइल संपादित करें',
    'language': 'भाषा',
    'help_support': 'सहायता और समर्थन',
    'log_out': 'लॉग आउट',
    'log_out_confirm': 'क्या आप वाकई लॉग आउट करना चाहते हैं?',

        // ---- Edit profile screen ----
    'edit_profile_updated': 'प्रोफ़ाइल अपडेट हो गई',
    'edit_profile_save_error': 'बदलाव सहेजे नहीं जा सके: {error}',
    'edit_profile_full_name': 'पूरा नाम',
    'edit_profile_name_validator': 'कृपया अपना नाम दर्ज करें',
    'email': 'ईमेल',
    'edit_profile_email_helper': 'ईमेल सेटिंग्स में बदला जा सकता है',
    'edit_profile_location_label': 'स्थान / जिला',
    'edit_profile_location_hint': 'जैसे, कोल्हापुर जिला',
    'save_changes': 'बदलाव सहेजें',

        // ---- Help & Support screen ----
    'faq_section_title': 'अक्सर पूछे जाने वाले प्रश्न',
    'faq_1_q': 'फसल रोग स्कैनर कितना सटीक है?',
    'faq_1_a': 'एआई मॉडल अपनी प्रशिक्षण छवियों पर लगभग 95% सटीकता के साथ परखा गया है, उन फसलों के लिए जो यह फिलहाल समर्थित करता है: सेब, मक्का, अंगूर, आलू और टमाटर। असली खेत की तस्वीरें अधिक भिन्न हो सकती हैं, इसलिए यदि ऐप "इसे भरोसे के साथ पहचान नहीं पाया" दिखाता है, तो बेहतर रोशनी में फिर से फोटो लें या किसी स्थानीय कृषि विशेषज्ञ से पूछें।',
    'faq_2_q': 'ऐप फिलहाल किन फसलों के लिए रोग पहचान सकता है?',
    'faq_2_a': 'अभी, कैमरा स्कैनर सेब, मक्का, अंगूर, आलू और टमाटर का समर्थन करता है। "सभी फसलें" सेक्शन में दिखाई गई अन्य फसलें केवल जानकारी के लिए हैं — उनके लिए रोग पहचान भविष्य के अपडेट में लाई जाएगी।',
    'faq_3_q': 'क्या ऐप बिना इंटरनेट के काम करता है?',
    'faq_3_a': 'ऐप इंस्टॉल होने के बाद रोग स्कैनिंग बिना इंटरनेट के काम करती है, क्योंकि एआई मॉडल सीधे आपके फोन पर चलता है। मौसम, समुदाय और एआई असिस्टेंट चैट के लिए इंटरनेट कनेक्शन ज़रूरी है।',
    'faq_4_q': 'मैं ऐप की भाषा कैसे बदलूं?',
    'faq_4_a': 'प्रोफ़ाइल > भाषा में जाएं, या होम स्क्रीन पर भाषा आइकन टैप करें। एग्रीविज़न एआई फिलहाल अंग्रेज़ी, हिंदी और मराठी का समर्थन करता है।',
    'faq_5_q': 'क्या मेरा स्कैन इतिहास निजी है?',
    'faq_5_a': 'हां। आपका स्कैन इतिहास और समुदाय पोस्ट आपके खाते से जुड़े हैं और केवल आपको दिखाई देते हैं, सिवाय उसके जो आप समुदाय सेक्शन में सार्वजनिक रूप से पोस्ट करना चुनते हैं।',
    'faq_6_q': 'मैं अपने इतिहास से कोई स्कैन कैसे हटाऊं?',
    'faq_6_a': 'स्कैन इतिहास खोलें, फिर किसी भी स्कैन पर बाईं ओर स्वाइप करें या उस पर ट्रैश आइकन टैप करें, और हटाने की पुष्टि करें।',
    'faq_7_q': 'क्या मैं लाइट और डार्क मोड के बीच बदल सकता हूं?',
    'faq_7_a': 'हां — प्रोफ़ाइल > सेटिंग्स > दिखावट में जाएं और लाइट या डार्क चुनें।',
    'still_need_help': 'फिर भी मदद चाहिए?',
    'email_support': 'ईमेल सहायता',
    'help_disclaimer': 'गंभीर और तत्काल फसल रोग प्रकोप के लिए, कृपया अपने स्थानीय कृषि विस्तार कार्यालय से भी संपर्क करें — यह ऐप एक सहायक उपकरण है, लेकिन विशेषज्ञ, व्यक्तिगत सलाह का विकल्प नहीं है।',
    'app_version_label': 'एग्रीविज़न एआई · संस्करण 1.0.0',

        // ---- Login screen ----
    'login_enter_email_first': 'पहले ऊपर अपना ईमेल दर्ज करें।',
    'login_password_reset_sent': 'पासवर्ड रीसेट ईमेल भेज दिया गया है।',
    'welcome_back': 'वापसी पर स्वागत है',
    'login_subtitle': 'अपने खेत को प्रबंधित करने के लिए लॉग इन करें',
    'login_email_required': 'कृपया अपना ईमेल दर्ज करें',
    'login_email_invalid': 'कृपया एक मान्य ईमेल दर्ज करें',
    'password': 'पासवर्ड',
    'login_password_required': 'कृपया अपना पासवर्ड दर्ज करें',
    'forgot_password': 'पासवर्ड भूल गए?',
    'log_in': 'लॉग इन करें',
    'login_no_account': 'खाता नहीं है?',
    'register': 'रजिस्टर करें',

        // ---- Registration screen ----
    'create_account': 'खाता बनाएं',
    'join_app': 'एग्रीविज़न एआई से जुड़ें',
    'registration_subtitle': 'आज ही अपनी फसलों की सुरक्षा शुरू करें',
    'full_name': 'पूरा नाम',
    'registration_name_required': 'कृपया अपना नाम दर्ज करें',
    'registration_password_required': 'कृपया एक पासवर्ड दर्ज करें',
    'registration_password_min_length': 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
    'confirm_password': 'पासवर्ड की पुष्टि करें',
    'registration_passwords_mismatch': 'पासवर्ड मेल नहीं खाते',

        // ---- Auth errors ----
    'auth_error_registration_failed': 'पंजीकरण विफल रहा। कृपया फिर से कोशिश करें।',
    'auth_error_generic': 'कुछ गलत हो गया। कृपया फिर से कोशिश करें।',
    'auth_error_email_in_use': 'उस ईमेल के लिए पहले से एक खाता मौजूद है।',
    'auth_error_invalid_email': 'वह ईमेल पता अमान्य लगता है।',
    'auth_error_weak_password': 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए।',
    'auth_error_invalid_credential': 'गलत ईमेल या पासवर्ड।',
    'auth_error_too_many_requests': 'बहुत सारे प्रयास। कृपया बाद में फिर कोशिश करें।',
    'auth_error_network': 'नेटवर्क त्रुटि। अपना कनेक्शन जांचें और फिर कोशिश करें।',

        // ---- Update email sheet ----
    'update_email_sheet_title': 'ईमेल अपडेट करें',
    'update_email_sheet_body': 'अपना वर्तमान पासवर्ड और नया ईमेल दर्ज करें। बदलाव की पुष्टि के लिए हम एक सत्यापन लिंक भेजेंगे।',
    'current_password': 'वर्तमान पासवर्ड',
    'new_email': 'नया ईमेल',
    'send_verification_link': 'सत्यापन लिंक भेजें',
    'update_email_link_sent': 'सत्यापन लिंक भेज दिया गया है। बदलाव की पुष्टि के लिए अपना नया ईमेल जांचें।',
    'auth_error_requires_recent_login': 'सुरक्षा कारणों से, कृपया लॉग आउट करके फिर से लॉग इन करें और पुनः प्रयास करें।',

        // ---- Suppliers screen ----
    'nearby_suppliers': 'नज़दीकी आपूर्तिकर्ता',
    'suppliers_search_hint': 'फफूंदनाशक, बीज, उपकरण खोजें...',
    'suppliers_looking_for': 'खोज रहे हैं: {query}',
    'suppliers_shops_found_singular': 'नज़दीक {count} दुकान मिली',
    'suppliers_shops_found_plural': 'नज़दीक {count} दुकानें मिलीं',
    'suppliers_search_failed': 'खोज विफल: {error}। पिछले परिणाम दिखाए जा रहे हैं।',
    'suppliers_none_found': '{radius} किमी के भीतर कोई दुकान नहीं मिली। नक्शा डेटा कवरेज क्षेत्र के अनुसार अलग-अलग है।',
    'suppliers_search_wider': 'व्यापक खोजें ({radius} किमी)',
    'searching': 'खोजा जा रहा है...',
    'suppliers_no_maps_app': 'इस डिवाइस पर कोई मानचित्र ऐप नहीं खोला जा सका।',
    'away_suffix': 'दूर',
    'get_directions': 'दिशा-निर्देश पाएं',

        // ---- Notifications screen ----
    'notifications_title': 'सूचनाएं',
    'clear_all': 'सभी साफ़ करें',
    'notifications_clear_confirm_title': 'सभी सूचनाएं साफ़ करें?',
    'notifications_clear_confirm_body': 'यह पूर्ववत नहीं किया जा सकता।',
    'clear': 'साफ़ करें',
    'notifications_empty': 'अभी तक कोई सूचना नहीं है। स्कैन पुष्टि, मौसम अलर्ट, और आपका दैनिक रिमाइंडर यहां दिखाई देंगे।',

        // ---- AI Assistant screen ----
    'ai_assistant_name': 'एग्रीविज़न असिस्टेंट',
    'ai_assistant_status': '● ऑनलाइन · मुझसे कुछ भी पूछें',
    'new_chat': 'नई चैट',
    'chat_history': 'चैट इतिहास',
    'no_conversations_yet': 'अभी तक कोई बातचीत नहीं',
    'typing_indicator': 'टाइप कर रहा है…',
    'stop_reading': 'पढ़ना बंद करें',
    'read_last_reply_aloud': 'अंतिम जवाब ज़ोर से पढ़ें',
    'open_scanner': 'स्कैनर खोलें',
    'treatment_tips_chip': 'उपचार सुझाव',
    'treatment_tips_query': 'सामान्य फसल रोगों के लिए मुझे सामान्य उपचार सुझाव दें',
    'listening_hint': 'सुन रहा हूं...',
    'type_question_hint': 'अपना सवाल टाइप करें...',
    'ai_welcome_message': 'नमस्ते! मैं आपका एग्रीविज़न असिस्टेंट हूं। फसल रोगों, उपचार, मौसम, या किसी भी अन्य विषय के बारे में मुझसे पूछें — अंग्रेज़ी, हिंदी, या मराठी में।',
    'ai_voice_input_error': 'आवाज़ इनपुट त्रुटि: {error}',
    'ai_connection_error': 'क्षमा करें, मैं अभी असिस्टेंट तक नहीं पहुंच सका। कृपया अपना कनेक्शन जांचें और फिर कोशिश करें। ({error})',

        // ---- History screen ----
    'scan_history_title': 'स्कैन इतिहास',
    'history_today': 'आज, {time}',
    'history_yesterday': 'कल, {time}',
    'history_days_ago': '{days} दिन पहले, {time}',
    'history_delete_title': 'यह स्कैन हटाएं?',
    'history_delete_body': 'इससे स्कैन और उसकी तस्वीर स्थायी रूप से हट जाएगी। यह पूर्ववत नहीं किया जा सकता।',
    'history_empty': 'अभी तक कोई स्कैन नहीं है — शुरू करने के लिए होम पर "फसल स्कैन करें" पर टैप करें।',
    'history_failed_to_delete': 'हटाने में विफल: {error}',
    'unclear_photo': 'अस्पष्ट तस्वीर',
    'history_confidence_label': '{percent}% विश्वास',
    'history_crop_match_label': '{crop} · {percent}% मेल',
  },
  'mr': {
    // ---- Home screen ----
    'hi_greeting': 'नमस्कार,',
    'scan_a_crop': 'पीक स्कॅन करा',
    'scan_a_crop_subtitle': 'क्रॉप डॉक्टर - त्वरित रोग ओळखा',
    'quick_actions': 'त्वरित कृती',
    'history': 'इतिहास',
    'community': 'समुदाय',
    'suppliers': 'पुरवठादार',
    'ai_chat': 'एआय चॅट',
    'weather': 'हवामान',
    'all_crops': 'सर्व पिके',
    'nav_home': 'मुख्यपृष्ठ',
    'nav_scan': 'स्कॅन',
    'nav_history': 'इतिहास',
    'nav_community': 'समुदाय',
    'nav_profile': 'प्रोफाइल',
    'tap_for_spray_timeline': 'संपूर्ण फवारणी वेळापत्रक पाहण्यासाठी टॅप करा',
    'loading_weather': 'हवामान लोड होत आहे...',
    'weather_unavailable': 'हवामान उपलब्ध नाही',
    'coming_soon': 'लवकरच येत आहे',
    'optimal': 'योग्य',
    'moderate': 'मध्यम',
    'unfavorable': 'प्रतिकूल',

    // ---- Settings screen ----
    'settings_title': 'सेटिंग्ज',
    'appearance': 'स्वरूप',
    'light': 'लाइट',
    'dark': 'डार्क',
    'account': 'खाते',
    'change_password': 'पासवर्ड बदला',
    'update_email': 'ईमेल अपडेट करा',
    'preferences': 'प्राधान्ये',
    'push_notifications': 'पुश सूचना',
    'reminder_time': 'स्मरणपत्र वेळ',
    'reminder_note_label': 'तुम्ही हे स्मरणपत्र का सेट करत आहात? (ऐच्छिक)',
    'reminder_note_hint': 'उदा. सकाळच्या फवारणीपूर्वी आठवण करा',
    'save_note': 'नोंद जतन करा',
    'note_saved': 'नोंद जतन झाली.',
    'data_sharing': 'मॉडेल सुधारण्यासाठी डेटा शेअरिंग',
    'reminder_time_updated': 'स्मरणपत्र वेळ अपडेट झाली.',
    'alarms_permission_warning': 'कृपया सिस्टम सेटिंग्जमध्ये या अ‍ॅपसाठी "अलार्म आणि स्मरणपत्रे" ला परवानगी द्या, अन्यथा स्मरणपत्र वाजणार नाही.',
    'change_password_sheet_title': 'पासवर्ड बदला',
    'change_password_sheet_body': 'आम्ही तुमच्या ईमेलवर पासवर्ड रीसेट लिंक पाठवू.',
    'send_reset_link': 'रीसेट लिंक पाठवा',

    // ---- Weather screen ----
    'weather_title': 'हवामान आणि पीक धोका',
    'tab_today': 'आज',
    'tab_calendar': 'कॅलेंडर',
    'try_again': 'पुन्हा प्रयत्न करा',
    'spray_conditions_prefix': 'फवारणीची स्थिती — पुढील',
    'hours_suffix': 'तास',
    'crop_risk_today': 'आजचा पीक धोका',
    'weather_humidity_temp_template': 'आजच्या आर्द्रतेवर ({humidity}%) आणि तापमानावर ({temp}°C) आधारित',
    'risk_high': 'उच्च',
    'risk_moderate': 'मध्यम',
    'risk_low': 'कमी',
    'risk_suffix': 'धोका',
    'legend_high_risk': 'उच्च धोका',
    'weather_model_disclaimer': 'फवारणीची वेळ आणि रोग-धोका निर्देशक थेट आर्द्रता, वारा आणि पर्जन्य-शक्यता डेटावरून एक सोप्या नियम-आधारित अंदाजाने काढले जातात, प्रशिक्षित मॉडेलवरून नाही.',
    'calendar_intro': "OpenWeather ची मोफत आवृत्ती 5-दिवसांचा अंदाज देते — खाली रोग-धोका अंदाजांसह दाखवले आहे.",
    'no_forecast_data': 'कोणताही अंदाज डेटा उपलब्ध नाही.',
    'metric_humidity': 'आर्द्रता',
    'metric_wind': 'वारा',
    'metric_visibility': 'दृश्यमानता',
    'weekday_mon': 'सोम', 'weekday_tue': 'मंगळ', 'weekday_wed': 'बुध', 'weekday_thu': 'गुरु', 'weekday_fri': 'शुक्र', 'weekday_sat': 'शनि', 'weekday_sun': 'रवि',
    'crop_tomato': 'टोमॅटो', 'crop_potato': 'बटाटा', 'crop_corn': 'मका', 'crop_rice': 'तांदूळ', 'crop_grape': 'द्राक्ष', 'crop_apple': 'सफरचंद', 'crop_sugarcane': 'ऊस', 'crop_wheat': 'गहू', 'crop_citrus': 'लिंबूवर्गीय फळे',

        // ---- Community screen ----
    'cancel': 'रद्द करा',
    'delete': 'हटवा',
    'comments': 'टिप्पण्या',
    'something_went_wrong': 'काहीतरी चूक झाली: {error}',
    'community_new_post': 'नवीन पोस्ट',
    'community_crop_label': 'पीक',
    'community_post_hint': 'इतर शेतकऱ्यांना प्रश्न विचारा किंवा टिप्स शेअर करा...',
    'community_post_button': 'पोस्ट करा',
    'community_failed_to_post': 'पोस्ट करण्यात अयशस्वी: {error}',
    'community_filter_by_crop': 'पिकानुसार फिल्टर करा',
    'community_delete_post_title': 'पोस्ट हटवायची?',
    'community_delete_post_message': 'यामुळे तुमची पोस्ट आणि तिच्या सर्व टिप्पण्या काढल्या जातील. हे पूर्ववत करता येणार नाही.',
    'community_delete_comment_title': 'टिप्पणी हटवायची?',
    'community_delete_comment_message': 'हे पूर्ववत करता येणार नाही.',
    'community_failed_delete_post': 'पोस्ट हटवण्यात अयशस्वी: {error}',
    'community_failed_delete_comment': 'टिप्पणी हटवण्यात अयशस्वी: {error}',
    'community_no_comments': 'अजून कोणतीही टिप्पणी नाही. सर्वप्रथम उत्तर द्या!',
    'community_write_reply_hint': 'उत्तर लिहा...',
    'community_failed_reply': 'उत्तर पाठवण्यात अयशस्वी: {error}',
    'community_no_posts_for': '{crop} साठी अजून पोस्ट नाहीत. सर्वप्रथम शेअर करा!',
    'community_replies_suffix': 'उत्तरे',

        // ---- Profile screen ----
    'profile_title': 'प्रोफाइल',
    'farmer_fallback_name': 'शेतकरी',
    'edit_profile': 'प्रोफाइल संपादित करा',
    'language': 'भाषा',
    'help_support': 'मदत आणि समर्थन',
    'log_out': 'लॉग आउट',
    'log_out_confirm': 'तुम्हाला खरोखर लॉग आउट करायचे आहे का?',

        // ---- Edit profile screen ----
    'edit_profile_updated': 'प्रोफाइल अपडेट झाली',
    'edit_profile_save_error': 'बदल जतन करता आले नाहीत: {error}',
    'edit_profile_full_name': 'पूर्ण नाव',
    'edit_profile_name_validator': 'कृपया तुमचे नाव प्रविष्ट करा',
    'email': 'ईमेल',
    'edit_profile_email_helper': 'ईमेल सेटिंग्जमध्ये बदलता येईल',
    'edit_profile_location_label': 'ठिकाण / जिल्हा',
    'edit_profile_location_hint': 'उदा. कोल्हापूर जिल्हा',
    'save_changes': 'बदल जतन करा',

        // ---- Help & Support screen ----
    'faq_section_title': 'वारंवार विचारले जाणारे प्रश्न',
    'faq_1_q': 'पीक रोग स्कॅनर किती अचूक आहे?',
    'faq_1_a': 'एआय मॉडेलची त्याच्या प्रशिक्षण प्रतिमांवर सुमारे 95% अचूकतेने चाचणी केली आहे, सध्या समर्थित असलेल्या पिकांसाठी: सफरचंद, मका, द्राक्ष, बटाटा आणि टोमॅटो. प्रत्यक्ष शेतातील फोटो अधिक वेगळे असू शकतात, त्यामुळे अ‍ॅपने "याची खात्रीने ओळख होऊ शकली नाही" असे दाखवल्यास, चांगल्या प्रकाशात पुन्हा फोटो घ्या किंवा स्थानिक कृषी तज्ज्ञांना विचारा.',
    'faq_2_q': 'अ‍ॅप सध्या कोणत्या पिकांसाठी रोग ओळखू शकते?',
    'faq_2_a': 'सध्या, कॅमेरा स्कॅनर सफरचंद, मका, द्राक्ष, बटाटा आणि टोमॅटोला समर्थन देतो. "सर्व पिके" विभागात दाखवलेली इतर पिके फक्त माहितीसाठी आहेत — त्यांच्यासाठी रोग ओळख भविष्यातील अपडेटमध्ये येईल.',
    'faq_3_q': 'अ‍ॅप इंटरनेटशिवाय काम करते का?',
    'faq_3_a': 'अ‍ॅप इंस्टॉल झाल्यावर रोग स्कॅनिंग ऑफलाइन काम करते, कारण एआय मॉडेल थेट तुमच्या फोनवर चालते. हवामान, समुदाय आणि एआय सहाय्यक चॅटसाठी इंटरनेट कनेक्शन आवश्यक आहे.',
    'faq_4_q': 'मी अ‍ॅपची भाषा कशी बदलू?',
    'faq_4_a': 'प्रोफाइल > भाषा येथे जा, किंवा मुख्यपृष्ठावरील भाषा चिन्हावर टॅप करा. अ‍ॅग्रीव्हिजन एआय सध्या इंग्रजी, हिंदी आणि मराठीला समर्थन देते.',
    'faq_5_q': 'माझा स्कॅन इतिहास खाजगी आहे का?',
    'faq_5_a': 'होय. तुमचा स्कॅन इतिहास आणि समुदाय पोस्ट तुमच्या खात्याशी जोडलेले असतात आणि फक्त तुम्हालाच दिसतात, समुदाय विभागात तुम्ही सार्वजनिकरित्या पोस्ट करण्याचे निवडलेले वगळता.',
    'faq_6_q': 'मी माझ्या इतिहासातून स्कॅन कसा हटवू?',
    'faq_6_a': 'स्कॅन इतिहास उघडा, नंतर कोणत्याही स्कॅनवर डावीकडे स्वाइप करा किंवा त्यावरील कचरापेटी चिन्हावर टॅप करा, आणि हटवण्याची पुष्टी करा.',
    'faq_7_q': 'मी लाइट आणि डार्क मोडमध्ये बदल करू शकतो का?',
    'faq_7_a': 'होय — प्रोफाइल > सेटिंग्ज > स्वरूप येथे जा आणि लाइट किंवा डार्क निवडा.',
    'still_need_help': 'अजूनही मदत हवी आहे?',
    'email_support': 'ईमेल सहाय्य',
    'help_disclaimer': 'गंभीर आणि तातडीच्या पीक रोग उद्रेकांसाठी, कृपया तुमच्या स्थानिक कृषी विस्तार कार्यालयाशीही संपर्क साधा — हे अ‍ॅप उपयुक्त साधन आहे, पण तज्ज्ञ, प्रत्यक्ष सल्ल्याचा पर्याय नाही.',
    'app_version_label': 'अ‍ॅग्रीव्हिजन एआय · आवृत्ती 1.0.0',

        // ---- Login screen ----
    'login_enter_email_first': 'आधी वरती तुमचा ईमेल टाका.',
    'login_password_reset_sent': 'पासवर्ड रीसेट ईमेल पाठवला आहे.',
    'welcome_back': 'पुन्हा स्वागत आहे',
    'login_subtitle': 'तुमचे शेत व्यवस्थापित करण्यासाठी लॉग इन करा',
    'login_email_required': 'कृपया तुमचा ईमेल टाका',
    'login_email_invalid': 'कृपया वैध ईमेल टाका',
    'password': 'पासवर्ड',
    'login_password_required': 'कृपया तुमचा पासवर्ड टाका',
    'forgot_password': 'पासवर्ड विसरलात?',
    'log_in': 'लॉग इन करा',
    'login_no_account': 'खाते नाही?',
    'register': 'नोंदणी करा',

        // ---- Registration screen ----
    'create_account': 'खाते तयार करा',
    'join_app': 'अ‍ॅग्रीव्हिजन एआयमध्ये सामील व्हा',
    'registration_subtitle': 'आजच तुमच्या पिकांचे संरक्षण सुरू करा',
    'full_name': 'पूर्ण नाव',
    'registration_name_required': 'कृपया तुमचे नाव प्रविष्ट करा',
    'registration_password_required': 'कृपया पासवर्ड प्रविष्ट करा',
    'registration_password_min_length': 'पासवर्ड किमान 6 अक्षरांचा असावा',
    'confirm_password': 'पासवर्डची पुष्टी करा',
    'registration_passwords_mismatch': 'पासवर्ड जुळत नाहीत',

        // ---- Auth errors ----
    'auth_error_registration_failed': 'नोंदणी अयशस्वी झाली. कृपया पुन्हा प्रयत्न करा.',
    'auth_error_generic': 'काहीतरी चूक झाली. कृपया पुन्हा प्रयत्न करा.',
    'auth_error_email_in_use': 'त्या ईमेलसाठी आधीच एक खाते अस्तित्वात आहे.',
    'auth_error_invalid_email': 'तो ईमेल पत्ता अवैध वाटतो.',
    'auth_error_weak_password': 'पासवर्ड किमान 6 अक्षरांचा असावा.',
    'auth_error_invalid_credential': 'चुकीचा ईमेल किंवा पासवर्ड.',
    'auth_error_too_many_requests': 'खूप जास्त प्रयत्न. कृपया नंतर पुन्हा प्रयत्न करा.',
    'auth_error_network': 'नेटवर्क त्रुटी. तुमचे कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.',

        // ---- Update email sheet ----
    'update_email_sheet_title': 'ईमेल अपडेट करा',
    'update_email_sheet_body': 'तुमचा सध्याचा पासवर्ड आणि नवीन ईमेल टाका. बदलाची पुष्टी करण्यासाठी आम्ही एक पडताळणी लिंक पाठवू.',
    'current_password': 'सध्याचा पासवर्ड',
    'new_email': 'नवीन ईमेल',
    'send_verification_link': 'पडताळणी लिंक पाठवा',
    'update_email_link_sent': 'पडताळणी लिंक पाठवली आहे. बदलाची पुष्टी करण्यासाठी तुमचा नवीन ईमेल तपासा.',
    'auth_error_requires_recent_login': 'सुरक्षिततेसाठी, कृपया लॉग आउट करून पुन्हा लॉग इन करा आणि पुन्हा प्रयत्न करा.',

        // ---- Suppliers screen ----
    'nearby_suppliers': 'जवळचे पुरवठादार',
    'suppliers_search_hint': 'बुरशीनाशक, बियाणे, अवजारे शोधा...',
    'suppliers_looking_for': 'शोधत आहात: {query}',
    'suppliers_shops_found_singular': 'जवळ {count} दुकान सापडले',
    'suppliers_shops_found_plural': 'जवळ {count} दुकाने सापडली',
    'suppliers_search_failed': 'शोध अयशस्वी: {error}. मागील निकाल दाखवत आहे.',
    'suppliers_none_found': '{radius} किमी मध्ये कोणतेही दुकान सापडले नाही. नकाशा डेटा कव्हरेज भागानुसार वेगळे असते.',
    'suppliers_search_wider': 'विस्तृत शोध घ्या ({radius} किमी)',
    'searching': 'शोधत आहे...',
    'suppliers_no_maps_app': 'या डिव्हाइसवर नकाशा अ‍ॅप उघडता आले नाही.',
    'away_suffix': 'दूर',
    'get_directions': 'दिशा मिळवा',

        // ---- Notifications screen ----
    'notifications_title': 'सूचना',
    'clear_all': 'सर्व साफ करा',
    'notifications_clear_confirm_title': 'सर्व सूचना साफ करायच्या?',
    'notifications_clear_confirm_body': 'हे पूर्ववत करता येणार नाही.',
    'clear': 'साफ करा',
    'notifications_empty': 'अजून कोणतीही सूचना नाही. स्कॅन पुष्टीकरण, हवामान इशारे आणि तुमचे दैनंदिन स्मरणपत्र इथे दिसेल.',

        // ---- AI Assistant screen ----
    'ai_assistant_name': 'अ‍ॅग्रीव्हिजन सहाय्यक',
    'ai_assistant_status': '● ऑनलाइन · मला काहीही विचारा',
    'new_chat': 'नवीन चॅट',
    'chat_history': 'चॅट इतिहास',
    'no_conversations_yet': 'अजून कोणतेही संभाषण नाही',
    'typing_indicator': 'टाइप करत आहे…',
    'stop_reading': 'वाचणे थांबवा',
    'read_last_reply_aloud': 'शेवटचे उत्तर मोठ्याने वाचा',
    'open_scanner': 'स्कॅनर उघडा',
    'treatment_tips_chip': 'उपचार टिप्स',
    'treatment_tips_query': 'सामान्य पीक रोगांसाठी मला सामान्य उपचार टिप्स द्या',
    'listening_hint': 'ऐकत आहे...',
    'type_question_hint': 'तुमचा प्रश्न टाइप करा...',
    'ai_welcome_message': 'नमस्कार! मी तुमचा अ‍ॅग्रीव्हिजन सहाय्यक आहे. पीक रोग, उपचार, हवामान किंवा इतर कशाबद्दलही मला विचारा — इंग्रजी, हिंदी किंवा मराठीत.',
    'ai_voice_input_error': 'आवाज इनपुट त्रुटी: {error}',
    'ai_connection_error': 'माफ करा, मी सध्या सहाय्यकापर्यंत पोहोचू शकलो नाही. कृपया तुमचे कनेक्शन तपासा आणि पुन्हा प्रयत्न करा. ({error})',

        // ---- History screen ----
    'scan_history_title': 'स्कॅन इतिहास',
    'history_today': 'आज, {time}',
    'history_yesterday': 'काल, {time}',
    'history_days_ago': '{days} दिवसांपूर्वी, {time}',
    'history_delete_title': 'हा स्कॅन हटवायचा?',
    'history_delete_body': 'यामुळे स्कॅन आणि त्याचा फोटो कायमचा काढला जाईल. हे पूर्ववत करता येणार नाही.',
    'history_empty': 'अजून कोणतेही स्कॅन नाही — सुरू करण्यासाठी मुख्यपृष्ठावर "पीक स्कॅन करा" वर टॅप करा.',
    'history_failed_to_delete': 'हटवण्यात अयशस्वी: {error}',
    'unclear_photo': 'अस्पष्ट फोटो',
    'history_confidence_label': '{percent}% विश्वास',
    'history_crop_match_label': '{crop} · {percent}% जुळणी',
  },
};