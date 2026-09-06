import 'package:flutter/material.dart';
import 'disruptions_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'permissions_screen.dart';
import 'data_source_screen.dart';
import 'about_screen.dart';

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
          // Section: Ustawienia
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'USTAWIENIA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading:
                Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
            title: const Text('Wygląd',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Motyw aplikacji i preferencje wyświetlania'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          Divider(
              indent: 16,
              endIndent: 16,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ListTile(
            leading:
                Icon(Icons.security_outlined, color: theme.colorScheme.primary),
            title: const Text('Uprawnienia',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Status dostępu do lokalizacji GPS'),
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
          // Section: Dane
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'DANE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
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
                Icon(Icons.cloud_outlined, color: theme.colorScheme.primary),
            title: const Text('Usługa i źródło danych',
                style: TextStyle(fontWeight: FontWeight.w600)),
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

          const SizedBox(height: 12),
          // Section: Informacje
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'INFORMACJE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            title: const Text('O aplikacji',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Kolejka - informacje, wersja i autorzy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
