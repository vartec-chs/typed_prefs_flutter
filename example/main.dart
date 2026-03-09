import 'package:flutter/material.dart';
import 'package:typed_prefs/typed_prefs.dart';

import 'lib/app_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final service = await PreferencesService.initialize(
    writePolicies: {
      'writeOnce': const WriteOncePolicy(),
      'auditLog': const AuditLogPolicy(),
    },
  );
  final prefs = service.appPrefs;
  final themeMode = await prefs.settings.getThemeMode();

  runApp(
    TypedPrefsExample(
      service: service,
      initialThemeMode: themeMode ?? ThemeMode.system,
    ),
  );
}

class TypedPrefsExample extends StatefulWidget {
  final PreferencesService service;
  final ThemeMode initialThemeMode;

  const TypedPrefsExample({
    super.key,
    required this.service,
    required this.initialThemeMode,
  });

  @override
  State<TypedPrefsExample> createState() => _TypedPrefsExampleState();
}

class _TypedPrefsExampleState extends State<TypedPrefsExample> {
  late ThemeMode _themeMode = widget.initialThemeMode;

  AppPrefsStore get _prefs => widget.service.appPrefs;

  Future<void> _toggleTheme() async {
    final nextMode = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };

    await _prefs.settings.setThemeMode(nextMode);
    await _prefs.auth.setLastSyncAt(DateTime.now());

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = nextMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('typed_prefs example')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current theme: ${_themeMode.name}'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _toggleTheme,
                child: const Text('Rotate Theme Mode'),
              ),
              const SizedBox(height: 24),
              StreamBuilder<DateTime?>(
                stream: _prefs.auth.watchLastSyncAt(),
                builder: (context, snapshot) {
                  final value = snapshot.data;
                  return Text(
                    value == null
                        ? 'No sync yet'
                        : 'Last sync: ${value.toIso8601String()}',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
