import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/category_utils.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/search_utils.dart';

class DisruptionsScreen extends StatefulWidget {
  const DisruptionsScreen({super.key});

  @override
  State<DisruptionsScreen> createState() => _DisruptionsScreenState();
}

class _DisruptionsScreenState extends State<DisruptionsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _generatedAt;
  List<Disruption> _disruptions = [];
  Map<String, String> _disruptionTypes = {};
  Map<String, String> _stationsMap = {};
  String _filter = '';

  @override
  void initState() {
    super.initState();
    final saved = context.read<AppState>().cachedDisruptions;
    if (saved != null) _readData(saved);
    _loadDisruptions();
  }

  void _readData(Map<String, dynamic> data) {
    final types = (data['disruptionTypes'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));
    _disruptions = (data['disruptions'] as List<dynamic>? ?? [])
        .map((e) => Disruption.fromJson(e as Map<String, dynamic>))
        .where((item) => item.resolveDescription(types) != null)
        .toList();
    _disruptionTypes = (data['disruptionTypes'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));
    _stationsMap = (data['stations'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));
    _generatedAt = app_date
        .parsePdpDateTime((data['generatedAt'] ?? data['ts'])?.toString());
  }

  Future<void> _loadDisruptions() async {
    if (_isLoading) return;
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
      // This is the snapshot time, not the creation time of any disruption.
      final generatedAt = data['generatedAt'] ?? data['ts'];

      if (mounted) {
        setState(() {
          _disruptions = parsed
              .where((item) => item.resolveDescription(types) != null)
              .toList();
          _disruptionTypes = types;
          _stationsMap = stations;
          _generatedAt = generatedAt == null
              ? null
              : app_date.parsePdpDateTime(generatedAt.toString());
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Nie udało się pobrać utrudnień. Spróbuj ponownie.';
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

  Widget _buildAffectedTrainChip(Map<String, dynamic> ref, AppState appState,
      ThemeData theme, Future<bool> prepared) {
    return FutureBuilder<Map<String, dynamic>>(
      future: (() async =>
          await prepared ? await appState.resolveAffectedTrain(ref) : ref)(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? ref;
        final number = (data['nationalNumber'] ?? data['trainNumber'] ?? '')
            .toString()
            .trim();
        final category = (data['commercialCategorySymbol'] ??
                data['commercialCategory'] ??
                '')
            .toString()
            .trim();
        final name =
            (data['name'] ?? data['trainName'] ?? '').toString().trim();
        final label = [
          if (category.isNotEmpty) category,
          if (number.isNotEmpty) number,
          if (name.isNotEmpty) name
        ].join(' ');
        final dark = theme.brightness == Brightness.dark;
        return ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 72),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
                color: categoryColor(category, isDark: dark),
                borderRadius: BorderRadius.circular(6)),
            child: Text(
                label.isNotEmpty
                    ? label
                    : snapshot.connectionState == ConnectionState.waiting
                        ? 'Ustalanie numeru pociągu…'
                        : 'Numer pociągu niedostępny',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: categoryTextColor(category, isDark: dark)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        );
      },
    );
  }

  String _typeLabel(Disruption item) {
    final label = (_disruptionTypes[item.disruptionTypeCode] ??
            _disruptionTypes[item.message?.trim()])
        ?.trim();
    if (label == null ||
        label.isEmpty ||
        label.length > 80 ||
        label.contains('{')) {
      return 'Utrudnienie w ruchu';
    }
    return label;
  }

  String _message(Disruption item) {
    return item.resolveDescription(_disruptionTypes) ?? '';
  }

  String _headline(Disruption item, AppState appState) {
    final start = _getStationName(item.startStationId, appState);
    final end = _getStationName(item.endStationId, appState);
    if (start.isNotEmpty || end.isNotEmpty) {
      return [if (start.isNotEmpty) start, if (end.isNotEmpty) end].join(' – ');
    }
    final message = _message(item);
    if (!message.startsWith('Brak szczegółowego')) {
      final firstSentence = message.split(RegExp(r'\.\s')).first.trim();
      if (firstSentence.isNotEmpty && firstSentence.length <= 80) {
        return firstSentence;
      }
    }
    return _typeLabel(item);
  }

  String _preview(Disruption item, String headline) {
    var message = _message(item);
    if (message.startsWith(headline)) {
      message = message
          .substring(headline.length)
          .replaceFirst(RegExp(r'^[.\s]+'), '');
    }
    if (message.isEmpty) return 'Otwórz, aby zobaczyć szczegóły.';
    return message.length > 120 ? '${message.substring(0, 120)}…' : message;
  }

  String? _creationTimeLabel(Disruption item) {
    final dateTime = item.createdAt == null
        ? null
        : app_date.parsePdpDateTime(item.createdAt!);
    if (dateTime == null) return null;
    return app_date.formatTimeDisplay(dateTime.hour, dateTime.minute);
  }

  void _showDetails(BuildContext context, Disruption item, AppState appState) {
    final theme = Theme.of(context);
    final typeName = _typeLabel(item);
    final startName = _getStationName(item.startStationId, appState);
    final endName = _getStationName(item.endStationId, appState);
    // This belongs to the open sheet, not to a MediaQuery/theme rebuild.
    var visibleTrainCount = 20;
    final prepared = appState.prepareAffectedTrains(item.affectedRoutes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          final totalTrainCount = item.affectedRoutes.length;
          final visibleCount = visibleTrainCount.clamp(0, totalTrainCount);
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
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            typeName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (startName.isNotEmpty || endName.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.route_outlined,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  [
                                    if (startName.isNotEmpty) startName,
                                    if (endName.isNotEmpty) endName,
                                  ].join(' - '),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _message(item),
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _creationTimeLabel(item) == null
                          ? 'Godzina dodania: źródło nie udostępnia tej informacji.'
                          : 'Dodano o ${_creationTimeLabel(item)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    if (item.affectedRoutes.isNotEmpty) ...[
                      Text(
                        'Dotknięte pociągi ($totalTrainCount):',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.affectedRoutes
                            .take(visibleCount)
                            .map((r) => _buildAffectedTrainChip(
                                r, appState, theme, prepared))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Text('Wyświetlono $visibleCount z $totalTrainCount',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant)),
                      if (visibleCount < totalTrainCount)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: TextButton.icon(
                            key: const ValueKey('show-more-affected-trains'),
                            onPressed: () => setModalState(() {
                              visibleTrainCount = (visibleTrainCount + 20)
                                  .clamp(0, totalTrainCount);
                            }),
                            icon: const Icon(Icons.expand_more),
                            label: Text(
                                'Pokaż kolejne (${totalTrainCount - visibleCount})'),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utrudnienia w ruchu',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDisruptions,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null && _disruptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                  '$_errorMessage Wyświetlam ostatnio pobrane dane; mogą być nieaktualne.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_generatedAt case final generatedAt?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Dane z ${app_date.formatDateDisplay(generatedAt)}, '
                '${app_date.formatTimeDisplay(generatedAt.hour, generatedAt.minute)}',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          Expanded(child: _buildBody(appState)),
        ],
      ),
    );
  }

  Widget _buildBody(AppState appState) {
    final theme = Theme.of(context);

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
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
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
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Brak aktualnych utrudnień',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ruch pociągów odbywa się bez zakłóceń.',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final query = normalizeStationQuery(_filter);
    final visible = _disruptions.where((item) {
      if (query.isEmpty) return true;
      return normalizeStationQuery([
        _headline(item, appState),
        _typeLabel(item),
        _message(item),
      ].join(' '))
          .contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadDisruptions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        itemCount: visible.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Filtruj utrudnienia',
                      hintText: 'Stacja, odcinek lub treść komunikatu',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('Brak utrudnień pasujących do filtra.'),
                    ),
                ],
              ),
            );
          }
          final item = visible[index - 1];
          final typeName = _typeLabel(item);
          final startName = _getStationName(item.startStationId, appState);
          final endName = _getStationName(item.endStationId, appState);
          final headline = _headline(item, appState);
          final preview = _preview(item, headline);

          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            headline,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if ((startName.isNotEmpty || endName.isNotEmpty) &&
                        headline !=
                            [startName, endName]
                                .where((value) => value.isNotEmpty)
                                .join(' – ')) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (startName.isNotEmpty) startName,
                          if (endName.isNotEmpty) endName,
                        ].join(' - '),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        preview,
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (headline != typeName &&
                        typeName != 'Utrudnienie w ruchu')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(typeName,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    if (_creationTimeLabel(item) case final creationTime?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Dodano o $creationTime',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (item.affectedRoutes.isNotEmpty)
                          Text(
                            'Dotyczy ${item.affectedRoutes.length} pociągów',
                            style: TextStyle(
                                fontSize: 12, color: theme.colorScheme.outline),
                          )
                        else
                          const SizedBox(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Szczegóły',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 16, color: theme.colorScheme.primary),
                          ],
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
