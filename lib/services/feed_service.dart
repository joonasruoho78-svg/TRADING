import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert.dart';

class FeedException implements Exception {
  final String message;
  FeedException(this.message);
  @override
  String toString() => message;
}

class FeedService {
  final http.Client _client;

  /// Accepts an injectable [http.Client] so tests can supply a mock instead
  /// of hitting the network (see test/widget_test.dart).
  FeedService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches and parses the alert feed. Cache-busts with a timestamp query
  /// param since some CDNs (GitHub Pages included) cache aggressively.
  Future<List<Alert>> fetchAlerts(String url) async {
    if (url.trim().isEmpty) {
      throw FeedException('No feed URL configured yet -- set one in Settings.');
    }

    Uri uri;
    try {
      uri = Uri.parse(url.trim());
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    } catch (_) {
      throw FeedException('That feed URL doesn\'t look valid.');
    }

    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 20));
    } catch (e) {
      throw FeedException('Couldn\'t reach the feed -- check your connection or the URL.');
    }

    if (response.statusCode != 200) {
      throw FeedException('Feed returned ${response.statusCode} -- check the URL in Settings.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw FeedException('Feed didn\'t return valid JSON -- check the URL points at alerts.json.');
    }

    if (decoded is! List) {
      throw FeedException('Unexpected feed format.');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Alert.fromJson)
        .toList();
  }
}
