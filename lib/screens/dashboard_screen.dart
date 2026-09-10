import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../services/feed_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_tile.dart';
import '../widgets/alert_card.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final FeedService? feedService;
  final SettingsService? settingsService;

  const DashboardScreen({super.key, this.feedService, this.settingsService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  late final FeedService _feedService = widget.feedService ?? FeedService();
  late final SettingsService _settingsService = widget.settingsService ?? SettingsService();

  String? _feedUrl;
  List<Alert> _alerts = [];
  String _filter = 'all';
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _bootstrap() async {
    final url = await _settingsService.getFeedUrl();
    setState(() => _feedUrl = url);
    await _load();
  }

  Future<void> _load() async {
    if (_feedUrl == null || _feedUrl!.trim().isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _alerts = [];
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final alerts = await _feedService.fetchAlerts(_feedUrl!);
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => SettingsScreen(initialUrl: _feedUrl ?? '')),
    );
    if (result != null) {
      setState(() => _feedUrl = result);
      _load();
    }
  }

  Map<String, int> _countsLast24h() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final counts = <String, int>{};
    for (final source in kSourceOrder) {
      counts[source] = _alerts.where((a) => a.source == source && a.ts.isAfter(cutoff)).length;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = _countsLast24h();
    final visible = _filter == 'all' ? _alerts : _alerts.where((a) => a.source == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Signals'),
        actions: [
          // Pull-to-refresh (below) needs a touch drag, which a desktop
          // mouse user has no reason to try -- give them an explicit button.
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: _openSettings),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(theme, counts, visible),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, Map<String, int> counts, List<Alert> visible) {
    if (_feedUrl == null || _feedUrl!.trim().isEmpty) {
      return _centeredMessage(
        icon: Icons.link_off,
        title: 'No feed set up yet',
        message: 'Tell the app where your bot publishes alerts.json.',
        actionLabel: 'Open Settings',
        onAction: _openSettings,
      );
    }

    if (_error != null && _alerts.isEmpty) {
      return _centeredMessage(
        icon: Icons.cloud_off,
        title: 'Couldn\'t load the feed',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    // On a wide desktop window, a full-bleed list of cards reads oddly --
    // pin the content to a comfortable reading width and center it, same as
    // it would sit on a phone. Below the cap this is a no-op: ConstrainedBox
    // only ever shrinks the available width, never grows it.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          children: [
            if (_loading && _alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _StatsRow(counts: counts),
              const SizedBox(height: 12),
              _FilterRow(
                selected: _filter,
                onSelect: (s) => setState(() => _filter = s),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No alerts yet. The bot checks every 15 minutes -- pull down to refresh.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ...visible.map((a) => AlertCard(alert: a)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _centeredMessage({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, int> counts;
  const _StatsRow({required this.counts});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: kSourceOrder.map((source) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: StatTile(
              label: kSourceLabels[source]!,
              count: counts[source] ?? 0,
              color: AppColors.forSource(source, brightness),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _FilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = ['all', ...kSourceOrder];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final key = items[i];
          final label = key == 'all' ? 'All' : kSourceLabels[key]!;
          final active = key == selected;
          return ChoiceChip(
            label: Text(label),
            selected: active,
            onSelected: (_) => onSelect(key),
            labelStyle: TextStyle(
              color: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            selectedColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            side: BorderSide(color: theme.dividerColor),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}
