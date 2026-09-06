import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Wygląd', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RadioGroup<ThemeMode>(
          groupValue: appState.themeMode,
          onChanged: (mode) {
            if (mode != null) appState.setThemeMode(mode);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'MOTYW APLIKACJI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Systemowy'),
                subtitle: const Text('Zgodny z ustawieniami urządzenia'),
                value: ThemeMode.system,
                activeColor: theme.colorScheme.primary,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Jasny'),
                subtitle: const Text('Białe tło i wysoki kontrast'),
                value: ThemeMode.light,
                activeColor: theme.colorScheme.primary,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Ciemny'),
                subtitle: const Text('Ciemne tło, oszczędność baterii'),
                value: ThemeMode.dark,
                activeColor: theme.colorScheme.primary,
              ),
            ],
          )),
    );
  }
}
