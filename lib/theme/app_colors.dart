import 'package:flutter/material.dart';

/// Categorical palette for the 5 signal sources, fixed slot order (never
/// cycled/reassigned): senate=1(blue), form4=2(orange), 13f=3(aqua),
/// volume=4(yellow), news=5(magenta). Light/dark steps both validated for
/// CVD-safety and contrast per the reference palette this app shares with
/// the web dashboard.
class AppColors {
  AppColors._();

  static const Map<String, Color> _light = {
    'senate': Color(0xFF2A78D6),
    'form4': Color(0xFFEB6834),
    '13f': Color(0xFF1BAF7A),
    'volume_spike': Color(0xFFEDA100),
    'deal_news': Color(0xFFE87BA4),
  };

  static const Map<String, Color> _dark = {
    'senate': Color(0xFF3987E5),
    'form4': Color(0xFFD95926),
    '13f': Color(0xFF199E70),
    'volume_spike': Color(0xFFC98500),
    'deal_news': Color(0xFFD55181),
  };

  static const Color mutedLight = Color(0xFF898781);
  static const Color mutedDark = Color(0xFF898781);

  static Color forSource(String source, Brightness brightness) {
    final map = brightness == Brightness.dark ? _dark : _light;
    return map[source] ?? (brightness == Brightness.dark ? mutedDark : mutedLight);
  }
}

const Map<String, String> kSourceLabels = {
  'senate': 'Senate',
  'form4': 'Form 4',
  '13f': '13F',
  'volume_spike': 'Volume',
  'deal_news': 'News',
};

/// Fixed display order -- matches the categorical slot order above.
const List<String> kSourceOrder = ['senate', 'form4', '13f', 'volume_spike', 'deal_news'];
