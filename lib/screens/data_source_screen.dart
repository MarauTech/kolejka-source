import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/date_utils.dart' as app_date;

class DataSourceScreen extends StatefulWidget {
  const DataSourceScreen({super.key});
  @override
  State<DataSourceScreen> createState() => _DataSourceScreenState();
}

class _DataSourceScreenState extends State<DataSourceScreen> {
  bool _loading = true;
  bool _failed = false;
  DataVersion? _version;
  DateTime? _checkedAt;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final data = await context.read<AppState>().api.getDataVersion();
      if (!mounted) return;
      setState(() {
        _version = DataVersion.fromJson(data);
        _checkedAt = DateTime.now();
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Usługa i źródło danych'), actions: [
          IconButton(
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Odśwież status'),
        ]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          if (_loading) const LinearProgressIndicator(),
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(_failed ? Icons.cloud_off : Icons.cloud_done_outlined),
              title: const Text('Status połączenia'),
              subtitle: Text(_loading
                  ? 'Sprawdzanie połączenia…'
                  : _failed
                      ? 'Nie udało się połączyć. Spróbuj ponownie.'
                      : 'Połączono z API PLK')),
          if (_checkedAt != null)
            Text(
                'Ostatnie sprawdzenie: ${app_date.formatDateTime(_checkedAt!.toIso8601String())}'),
          const SizedBox(height: 12),
          Text(_version?.timestamp == null
              ? 'Czas aktualizacji danych jest niedostępny.'
              : 'Ostatnia aktualizacja danych: ${app_date.formatDate(_version!.timestamp)} ${app_date.formatDateTime(_version!.timestamp)}'),
          const Divider(height: 32),
          const Text(
              'Dane rozkładowe i dane o kursowaniu są pobierane z API PKP PLK.'),
        ]),
      );
}
