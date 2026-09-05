import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';

class DisruptionsScreen extends StatefulWidget {
  const DisruptionsScreen({super.key});

  @override
  State<DisruptionsScreen> createState() => _DisruptionsScreenState();
}

class _DisruptionsScreenState extends State<DisruptionsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Disruption> _disruptions = [];
  Map<String, String> _disruptionTypes = {};
  Map<String, String> _stationsMap = {};

  @override
  void initState() {
    super.initState();
    _loadDisruptions();
  }

  Future<void> _loadDisruptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final data = await appState.getDisruptions();

      final rawList = data['disruptions'] as List<dynamic>? ?? [];
      final parsed = rawList
          .map((e) => Disruption.fromJson(e as Map<String, dynamic>))
          .toList();

      final rawTypes = data['disruptionTypes'] as Map<String, dynamic>? ?? {};
      final types = rawTypes.map((k, v) => MapEntry(k, v.toString()));

      final rawStations = data['stations'] as Map<String, dynamic>? ?? {};
      final stations = rawStations.map((k, v) => MapEntry(k, v.toString()));

      if (mounted) {
        setState(() {
          _disruptions = parsed;
          _disruptionTypes = types;
          _stationsMap = stations;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Nie udało się pobrać utrudnień: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getStationName(int? stationId, AppState appState) {
    if (stationId == null) return '';
    final idStr = stationId.toString();
    if (_stationsMap.containsKey(idStr)) return _stationsMap[idStr]!;
    return appState.getStationName(stationId);
  }

  void _showDetails(BuildContext context, Disruption item, AppState appState) {
    final typeName = _disruptionTypes[item.disruptionTypeCode] ??
        item.disruptionTypeCode ??
        'Utrudnienie w ruchu';
    final startName = _getStationName(item.startStationId, appState);
    final endName = _getStationName(item.endStationId, appState);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          typeName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (startName.isNotEmpty || endName.isNotEmpty) ...[
                    Card(
                      color: Colors.grey.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.linear_scale, color: Color(0xFF003366)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                [
                                  if (startName.isNotEmpty) startName,
                                  if (endName.isNotEmpty) endName,
                                ].join(' ↔ '),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text(
                    'Treść komunikatu:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message ?? 'Brak szczegółowego komunikatu.',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  if (item.affectedRoutes.isNotEmpty) ...[
                    Text(
                      'Dotknięte pociągi (${item.affectedRoutes.length}):',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.affectedRoutes.take(15).map((r) {
                        final toid = r['trainOrderId'] ?? r['orderId'] ?? '';
                        return Chip(
                          label: Text('Pociąg $toid', style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Raw API JSON
                  ExpansionTile(
                    title: const Text('Pełne dane API (JSON)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ').convert(item.raw),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utrudnienia w ruchu', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDisruptions,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: _buildBody(appState),
    );
  }

  Widget _buildBody(AppState appState) {
    if (_isLoading && _disruptions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _disruptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadDisruptions,
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }

    if (_disruptions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadDisruptions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Brak aktualnych utrudnień',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ruch pociągów odbywa się bez zakłóceń.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDisruptions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        itemCount: _disruptions.length,
        itemBuilder: (context, index) {
          final item = _disruptions[index];
          final typeName = _disruptionTypes[item.disruptionTypeCode] ??
              item.disruptionTypeCode ??
              'Utrudnienie w ruchu';
          final startName = _getStationName(item.startStationId, appState);
          final endName = _getStationName(item.endStationId, appState);
          final msg = item.message ?? '';
          final preview = msg.length > 120 ? '${msg.substring(0, 120)}...' : msg;

          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showDetails(context, item, appState),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            typeName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (startName.isNotEmpty || endName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (startName.isNotEmpty) startName,
                          if (endName.isNotEmpty) endName,
                        ].join(' ↔ '),
                        style: const TextStyle(
                          color: Color(0xFF003366),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        preview,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.affectedRoutes.isNotEmpty)
                          Text(
                            'Dotyczy ${item.affectedRoutes.length} pociągów',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          )
                        else
                          const SizedBox(),
                        const Text(
                          'Więcej szczegółów →',
                          style: TextStyle(fontSize: 12, color: Color(0xFF003366), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
