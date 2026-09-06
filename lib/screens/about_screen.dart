import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final version = _packageInfo?.version ?? '–';
    final buildNumber = _packageInfo?.buildNumber ?? '–';
    final packageName = _packageInfo?.packageName ?? '–';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'O aplikacji',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/branding/kolejka_icon.png',
                height: 80,
                width: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Kolejka',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kolejka to aplikacja do przeglądania rozkładów jazdy, tablic stacyjnych, tras pociągów oraz bieżących informacji o kursowaniu pociągów.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Źródłem danych kolejowych jest API PKP Polskich Linii Kolejowych S.A.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Divider(
              height: 32,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            _buildSectionHeader(theme, 'Autorzy'),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Adam W. & MarauTech',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Divider(
              height: 32,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            _buildSectionHeader(theme, 'Wersja i kompilacja'),
            Column(
              children: [
                _buildInfoRow(theme, 'Wersja', version),
                _buildInfoRow(theme, 'Kompilacja', buildNumber),
                _buildInfoRow(theme, 'Nazwa pakietu', packageName),
              ],
            ),
            Divider(
              height: 32,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            _buildSectionHeader(theme, 'Źródło danych'),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Dane o rozkładach jazdy i wykonaniu pociągów pochodzą z usługi Otwarte Dane Kolejowe PKP Polskie Linie Kolejowe S.A.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Divider(
              height: 32,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            Text(
              'Aplikacja nie jest oficjalną aplikacją PKP Polskich Linii Kolejowych S.A. ani przewoźników kolejowych.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
