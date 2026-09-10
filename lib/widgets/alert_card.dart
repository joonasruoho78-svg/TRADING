import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/alert.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;

  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final color = AppColors.forSource(alert.source, brightness);
    final label = kSourceLabels[alert.source] ?? alert.source.toUpperCase();
    final formatted = formatAlertText(alert.text);

    // Note: a BoxDecoration can't have a borderRadius with non-uniform
    // border-side colors (Flutter asserts on this at *paint* time only, so
    // it slips past `flutter analyze` -- caught here by the widget test
    // that actually renders a card). So the rounded outer border stays a
    // single color, and the per-source color instead becomes a thin strip
    // clipped to the same rounded corners.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        // IntrinsicHeight first measures the Row's natural height (from the
        // text column) so CrossAxisAlignment.stretch below has something
        // finite to stretch the accent bar to -- without it, Row+stretch
        // inside an unbounded-height context (a ListView item) demands
        // infinite height and throws at layout time.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            relativeTime(alert.ts),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatted.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (formatted.bodyLines.isNotEmpty) const SizedBox(height: 4),
                      ...formatted.bodyLines.map((line) => _BodyLine(line: line)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyLine extends StatelessWidget {
  final String line;
  const _BodyLine({required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.4,
    );

    if (isBareUrl(line)) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse(line.trim()), mode: LaunchMode.externalApplication),
          child: Text(
            line.trim(),
            style: style?.copyWith(decoration: TextDecoration.underline),
          ),
        ),
      );
    }

    // Render *bold* spans inline; everything else is plain text.
    final spans = <TextSpan>[];
    final boldPattern = RegExp(r'\*(.+?)\*');
    var lastEnd = 0;
    for (final match in boldPattern.allMatches(line)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(text: match.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      lastEnd = match.end;
    }
    if (lastEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastEnd)));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(text: TextSpan(style: style, children: spans)),
    );
  }
}
