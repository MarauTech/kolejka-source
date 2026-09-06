import 'package:flutter/material.dart';
import 'disruptions_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Więcej', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: Icon(Icons.warning_amber_rounded,
                color: theme.colorScheme.primary),
            title: const Text('Utrudnienia w ruchu',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Komunikaty o utrudnieniach i awariach na liniach kolejowych'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DisruptionsScreen()),
              );
            },
          ),
          Divider(
              indent: 16,
              endIndent: 16,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ListTile(
            leading: Icon(Icons.bar_chart_outlined,
                color: theme.colorScheme.primary),
            title: const Text('Status sieci kolejowej',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Dzisiejsze statystyki kursowania pociągów w Polsce'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const StatisticsScreen()),
              );
            },
          ),
          Divider(
              indent: 16,
              endIndent: 16,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ListTile(
            leading:
                Icon(Icons.settings_outlined, color: theme.colorScheme.primary),
            title: const Text('Ustawienia',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Motyw aplikacji, uprawnienia i konfiguracja'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
