import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'permissions_screen.dart';
import 'data_source_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showThemeDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Wybierz motyw'),
          content: RadioGroup<ThemeMode>(
            groupValue: appState.themeMode,
            onChanged: (mode) {
              if (mode != null) {
                appState.setThemeMode(mode);
                Navigator.pop(context);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('Systemowy'),
                  subtitle: Text('Zgodny z ustawieniami urządzenia'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Jasny'),
                  subtitle: Text('Białe tło i wysoki kontrast'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Ciemny'),
                  subtitle: Text('Ciemne tło, oszczędność baterii'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
          ],
        );
      },
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Systemowy';
      case ThemeMode.light:
        return 'Jasny';
      case ThemeMode.dark:
        return 'Ciemny';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Section: Wygląd
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'WYGLĄD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.brightness_6_outlined,
                color: theme.colorScheme.primary),
            title: const Text('Motyw aplikacji'),
            subtitle: Text(_themeModeLabel(appState.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, appState),
          ),

          const SizedBox(height: 12),
          // Section: Uprawnienia
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'UPRAWNIENIA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.location_on_outlined,
                color: theme.colorScheme.primary),
            title: const Text('Uprawnienia lokalizacji'),
            subtitle:
                const Text('Sprawdź status dostępu do GPS i zmień uprawnienia'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PermissionsScreen()),
              );
            },
          ),

          const SizedBox(height: 12),
          // Section: Dane i sieć
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'DANE I SIEĆ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dns_outlined, color: theme.colorScheme.primary),
            title: const Text('Usługa i źródło danych'),
            subtitle: const Text(
                'Status API PKP PLK, wersje rozkładu i limity zapytań'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DataSourceScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
