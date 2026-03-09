import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:typed_prefs/typed_prefs.dart';

import 'app_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localAuth = LocalAuthentication();

  final service = await PreferencesService.initialize(
    writePolicies: {
      'writeOnce': const WriteOncePolicy(),
      'auditLog': const AuditLogPolicy(),
      'biometric': BiometricAuthPolicy(
        localAuth,
        localizedReason: 'Authenticate to change secure preferences',
      ),
    },
  );

  final initialThemeMode = await service.appPrefs.settings.getThemeMode();

  runApp(
    TypedPrefsApp(
      service: service,
      localAuth: localAuth,
      initialThemeMode: initialThemeMode,
    ),
  );
}

// ── App root ─────────────────────────────────────────────────────────────────

class TypedPrefsApp extends StatefulWidget {
  final PreferencesService service;
  final LocalAuthentication localAuth;
  final ThemeMode? initialThemeMode;

  const TypedPrefsApp({
    super.key,
    required this.service,
    required this.localAuth,
    required this.initialThemeMode,
  });

  @override
  State<TypedPrefsApp> createState() => _TypedPrefsAppState();
}

class _TypedPrefsAppState extends State<TypedPrefsApp> {
  late ThemeMode _themeMode = widget.initialThemeMode ?? ThemeMode.system;

  AppPrefsStore get _prefs => widget.service.appPrefs;

  @override
  void initState() {
    super.initState();
    // React to settings changes from anywhere in the app.
    _prefs.settings.watchThemeMode().listen(
          (mode) => setState(() => _themeMode = mode),
        );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'typed_prefs demo',
      themeMode: _themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: PrefsHomePage(service: widget.service, localAuth: widget.localAuth),
    );
  }
}

// ── Home page ─────────────────────────────────────────────────────────────────

class PrefsHomePage extends StatelessWidget {
  final PreferencesService service;
  final LocalAuthentication localAuth;

  const PrefsHomePage({
    super.key,
    required this.service,
    required this.localAuth,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('typed_prefs demo'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
              Tab(icon: Icon(Icons.lock), text: 'Auth'),
              Tab(icon: Icon(Icons.person), text: 'Profile'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SettingsTab(service: service),
            AuthTab(service: service),
            ProfileTab(service: service),
          ],
        ),
      ),
    );
  }
}

// ── Settings tab ─────────────────────────────────────────────────────────────

class SettingsTab extends StatefulWidget {
  final PreferencesService service;

  const SettingsTab({super.key, required this.service});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  SettingsPrefsStore get _settings => widget.service.appPrefs.settings;

  Future<void> _cycleTheme(ThemeMode current) async {
    final next = switch (current) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    // AuditLogPolicy logs this write to the console.
    await _settings.setThemeMode(next);
  }

  Future<void> _addLocale() async {
    final current = await _settings.getPreferredLocales();
    final next = [...current, 'fr'];
    await _settings.setPreferredLocales(next);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('Theme (auditLog write policy)'),
        StreamBuilder<ThemeMode>(
          stream: _settings.watchThemeMode(),
          builder: (context, snapshot) {
            final mode = snapshot.data ?? ThemeMode.system;
            return ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Theme mode'),
              subtitle: Text(mode.name),
              trailing: TextButton(
                onPressed: () => _cycleTheme(mode),
                child: const Text('Cycle'),
              ),
            );
          },
        ),
        const Divider(),
        _SectionHeader('Locales (auditLog write policy)'),
        StreamBuilder<List<String>>(
          stream: _settings.watchPreferredLocales(),
          builder: (context, snapshot) {
            final locales = snapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Preferred locales'),
                  subtitle: Text(locales.join(', ')),
                ),
                OverflowBar(
                  children: [
                    TextButton.icon(
                      onPressed: _addLocale,
                      icon: const Icon(Icons.add),
                      label: const Text('Add fr'),
                    ),
                    TextButton.icon(
                      onPressed: _settings.removePreferredLocales,
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Auth tab ──────────────────────────────────────────────────────────────────

class AuthTab extends StatefulWidget {
  final PreferencesService service;

  const AuthTab({super.key, required this.service});

  @override
  State<AuthTab> createState() => _AuthTabState();
}

class _AuthTabState extends State<AuthTab> {
  final _vaultController = TextEditingController();

  AuthPrefsStore get _auth => widget.service.appPrefs.auth;

  @override
  void dispose() {
    _vaultController.dispose();
    super.dispose();
  }

  Future<void> _saveVaultKey() async {
    final value = _vaultController.text.trim();
    if (value.isEmpty) return;
    try {
      // WriteOncePolicy — throws if already set.
      await _auth.setVaultKey(value);
      _vaultController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault key saved.')),
      );
    } on PreferenceWriteDeniedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleBiometrics(bool current) async {
    try {
      // BiometricAuthPolicy — prompts the user before writing.
      await _auth.setBiometricsEnabled(!current);
    } on PreferenceWriteDeniedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('Vault key (writeOnce policy)'),
        StreamBuilder<String?>(
          stream: _auth.watchVaultKey(),
          builder: (context, snapshot) {
            final key = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: const Text('Vault key'),
                  subtitle: Text(key == null ? 'Not set' : '••••••••'),
                ),
                if (key == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _vaultController,
                            decoration: const InputDecoration(
                              labelText: 'Enter vault key',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _saveVaultKey,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Write-once: key cannot be changed.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),
              ],
            );
          },
        ),
        const Divider(),
        _SectionHeader('Biometrics (biometric policy)'),
        StreamBuilder<bool>(
          stream: _auth.watchBiometricsEnabled(),
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? false;
            return SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric unlock'),
              subtitle: const Text('Requires authentication to toggle'),
              value: enabled,
              onChanged: (_) => _toggleBiometrics(enabled),
            );
          },
        ),
        const Divider(),
        _SectionHeader('Last sync'),
        StreamBuilder<DateTime?>(
          stream: _auth.watchLastSyncAt(),
          builder: (context, snapshot) {
            final ts = snapshot.data;
            return ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Last sync at'),
              subtitle: Text(ts?.toLocal().toString() ?? 'Never'),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Sync now',
                onPressed: () => _auth.setLastSyncAt(DateTime.now()),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Profile tab ───────────────────────────────────────────────────────────────

class ProfileTab extends StatefulWidget {
  final PreferencesService service;

  const ProfileTab({super.key, required this.service});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  AppPrefsStore get _prefs => widget.service.appPrefs;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    if (name.isEmpty || age == null) return;
    try {
      // BiometricAuthPolicy — prompts before overwriting an existing profile.
      await _prefs.setCurrentUser(UserProfile(name: name, age: age));
      _nameController.clear();
      _ageController.clear();
    } on PreferenceWriteDeniedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _clearProfile() async {
    try {
      await _prefs.removeCurrentUser();
    } on PreferenceWriteDeniedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('Current user (JsonPrefSerializer + biometric policy)'),
        StreamBuilder<UserProfile?>(
          stream: _prefs.watchCurrentUser(),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            return Column(
              children: [
                if (profile != null)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(profile.name[0])),
                      title: Text(profile.name),
                      subtitle: Text('Age: ${profile.age}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Clear profile',
                        onPressed: _clearProfile,
                      ),
                    ),
                  )
                else
                  const ListTile(
                    leading: Icon(Icons.person_outline),
                    title: Text('No profile saved'),
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.save),
                          label: Text(
                            profile == null ? 'Save profile' : 'Update profile',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Shared widget ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
