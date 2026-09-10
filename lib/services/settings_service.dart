import 'package:shared_preferences/shared_preferences.dart';

/// Persists the one setting this app needs: where to fetch the alert feed
/// from. Point it at your GitHub Pages URL (https://you.github.io/repo/data/alerts.json)
/// or the raw GitHub URL (https://raw.githubusercontent.com/you/repo/main/docs/data/alerts.json) --
/// either works, since both just serve the same JSON file the bot writes.
class SettingsService {
  static const _feedUrlKey = 'feed_url';

  Future<String?> getFeedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_feedUrlKey);
  }

  Future<void> setFeedUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_feedUrlKey, url.trim());
  }
}
