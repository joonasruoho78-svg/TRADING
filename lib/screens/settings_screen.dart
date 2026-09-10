import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final String initialUrl;
  const SettingsScreen({super.key, required this.initialUrl});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _controller;
  final _settings = SettingsService();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _settings.setFeedUrl(_controller.text);
    setState(() => _saved = true);
    if (!mounted) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Feed URL',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Point this at the alerts.json your bot publishes -- either your '
            'GitHub Pages URL (https://you.github.io/repo/data/alerts.json) or '
            'the raw GitHub URL '
            '(https://raw.githubusercontent.com/you/repo/main/docs/data/alerts.json).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'https://you.github.io/gov-trade-bot/data/alerts.json',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
          if (_saved) const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Saved.'),
          ),
        ],
      ),
    );
  }
}
