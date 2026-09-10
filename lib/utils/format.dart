String relativeTime(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[ts.month - 1]} ${ts.day}';
}

/// Drops a leading emoji (our alert texts always start with one, e.g. "🏛️")
/// without needing Unicode-property regex support: emoji/symbol codepoints
/// used here all sit well above U+2100, so skipping runes above that
/// threshold (plus the variation-selector U+FE0F and plain spaces) is a
/// reliable, engine-agnostic way to strip them.
String stripLeadingEmoji(String s) {
  final runes = s.runes.toList();
  var i = 0;
  while (i < runes.length && (runes[i] > 0x2100 || runes[i] == 0xFE0F || runes[i] == 0x20)) {
    i++;
  }
  return String.fromCharCodes(runes.sublist(i)).trimLeft();
}

class FormattedAlert {
  final String title;
  final List<String> bodyLines;
  FormattedAlert(this.title, this.bodyLines);
}

/// Splits the notifier's telegram-formatted text into a clean title (first
/// line, emoji and *bold* markers stripped) and the remaining lines for the
/// card body.
FormattedAlert formatAlertText(String text) {
  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) return FormattedAlert('Alert', const []);
  final title = stripLeadingEmoji(lines.first).replaceAll('*', '').trim();
  return FormattedAlert(title, lines.skip(1).toList());
}

final RegExp _urlPattern = RegExp(r'^https?://\S+$');

bool isBareUrl(String line) => _urlPattern.hasMatch(line.trim());
