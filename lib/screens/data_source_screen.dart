import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';

class DataSourceScreen extends StatefulWidget {
  const DataSourceScreen({super.key});

  @override
  State<DataSourceScreen> createState() => _DataSourceScreenState();
}

class _DataSourceScreenState extends State<DataSourceScreen> {
  DataVersion? _version;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final appState = context.read<AppState>();
    try {
      final data = await appState.api.getDataVersion();
      if (mounted) {
        setState(() {
          _version = DataVersion.fromJson(data);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Nie udało się połączyć z API: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostyka i status API',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadVersion,
            tooltip: 'Odśwież status',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API Status Card
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _error != null
                            ? Icons.error_outline
                            : Icons.cloud_done_outlined,
                        color: _error != null ? Colors.red : Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _error != null
                            ? 'Błąd połączenia'
                            : 'Połączono z API PLK',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (_isLoading) ...[
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator())),
                  ] else if (_error != null) ...[
                    Text(_error!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13)),
                  ] else if (_version != null) ...[
                    _buildRow('Wersja danych ogólnych:',
                        _version!.dataVersion ?? 'Brak danych'),
                    const SizedBox(height: 8),
                    _buildRow('Wersja rozkładu jazdy:',
                        _version!.schedulesVersion ?? 'Brak danych'),
                    const SizedBox(height: 8),
                    _buildRow('Wersja wykonania ruchu:',
                        _version!.operationsVersion ?? 'Brak danych'),
                    const SizedBox(height: 8),
                    _buildRow('Czas generowania danych:',
                        _version!.timestamp ?? 'Brak danych'),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Rate Limits Card
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed,
                          size: 22, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Limity zapytań (Rate Limits)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRow('Pozostało zapytań w bieżącej godzinie:',
                      '${appState.hourlyRemaining ?? "brak limitu / cache"}'),
                  const SizedBox(height: 8),
                  _buildRow('Pozostało zapytań w bieżącej dobie:',
                      '${appState.dailyRemaining ?? "brak limitu / cache"}'),
                  const SizedBox(height: 10),
                  Text(
                    'Słowniki stacji i relacji są buforowane lokalnie w pamięci urządzenia, aby minimalizować liczbę odpytań sieciowych.',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Security & Architecture Card
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security,
                          size: 22, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Bezpieczeństwo połączeń',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Wszystkie zapytania są szyfrowane (HTTPS / TLS). Klucze dostępu do API nie znajdują się w kodzie aplikacji mobilnej, lecz są bezpiecznie izolowane na serwerze pośredniczącym.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
