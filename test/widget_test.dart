import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_signals/main.dart';
import 'package:trade_signals/models/alert.dart';
import 'package:trade_signals/screens/dashboard_screen.dart';
import 'package:trade_signals/services/feed_service.dart';
import 'package:trade_signals/services/settings_service.dart';
import 'package:trade_signals/utils/format.dart';

void main() {
  testWidgets('App launches to the dashboard with no feed configured', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TradeSignalsApp());
    await tester.pumpAndSettle();

    expect(find.text('Trade Signals'), findsWidgets);
    // No feed URL saved yet (SharedPreferences starts empty in tests) ->
    // the empty-state prompt should show instead of a crash or spinner.
    expect(find.text('No feed set up yet'), findsOneWidget);
  });

  testWidgets('Dashboard renders stat tiles, filters, and cards from a real feed response', (tester) async {
    SharedPreferences.setMockInitialValues({'feed_url': 'https://example.test/alerts.json'});

    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    final sampleFeed = [
      {
        'ts': now - 120,
        'source': 'senate',
        'text': '🏛️ *Senate PTR filed* — Ron Wyden\n  • Purchase NVDA — \$50,001 - \$100,000 (Self, 09/05/2026)\nhttps://efdsearch.senate.gov/search/view/ptr/abc/',
      },
      {
        'ts': now - 3600,
        'source': 'form4',
        'text': '📝 *New Form 4 (insider filing)*\n4 - NVIDIA Corp (0001045810) (Issuer)\nFiled: 2026-09-08T10:00:00-04:00\nhttps://www.sec.gov/Archives/edgar/data/example',
      },
      {
        'ts': now - 7200,
        'source': 'deal_news',
        'text': '📰 *Deal news*\nAcme Corp to acquire Widget Inc\nhttps://news.example.com/story',
      },
    ];

    final mockClient = MockClient((request) async {
      expect(request.url.toString(), startsWith('https://example.test/alerts.json'));
      return http.Response(jsonEncode(sampleFeed), 200, headers: {'content-type': 'application/json'});
    });

    await tester.pumpWidget(MaterialApp(
      home: DashboardScreen(
        feedService: FeedService(client: mockClient),
        settingsService: SettingsService(),
      ),
    ));
    await tester.pumpAndSettle();

    // Stat tiles: senate/form4/news should each show 1 (within last 24h).
    expect(find.text('Senate PTR filed — Ron Wyden'), findsOneWidget);
    expect(find.text('New Form 4 (insider filing)'), findsOneWidget);
    expect(find.text('Deal news'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    // "SENATE" appears twice by design: the stat tile label and the card's badge.
    expect(find.text('SENATE'), findsNWidgets(2));

    // Filter down to Senate only.
    await tester.tap(find.text('Senate').first);
    await tester.pumpAndSettle();
    expect(find.text('Senate PTR filed — Ron Wyden'), findsOneWidget);
    expect(find.text('New Form 4 (insider filing)'), findsNothing);
  });

  test('formatAlertText strips the leading emoji and *bold* markers from the title', () {
    final formatted = formatAlertText(
      '🏛️ *Senate PTR filed* — Ron Wyden\n'
      '  • Purchase NVDA — \$50,001 - \$100,000 (Self, 09/05/2026)\n'
      'https://efdsearch.senate.gov/search/view/ptr/abc/',
    );
    expect(formatted.title, 'Senate PTR filed — Ron Wyden');
    expect(formatted.bodyLines.length, 2);
    expect(isBareUrl(formatted.bodyLines[1]), isTrue);
  });

  test('Alert.fromJson parses unix-seconds timestamps', () {
    final alert = Alert.fromJson({
      'ts': 1757300000.5,
      'source': 'form4',
      'text': '📝 *New Form 4*\nhello',
    });
    expect(alert.source, 'form4');
    expect(alert.ts.millisecondsSinceEpoch, 1757300000500);
  });

  test('relativeTime buckets correctly', () {
    final now = DateTime.now();
    expect(relativeTime(now.subtract(const Duration(seconds: 10))), 'just now');
    expect(relativeTime(now.subtract(const Duration(minutes: 5))), '5m ago');
    expect(relativeTime(now.subtract(const Duration(hours: 3))), '3h ago');
  });
}
