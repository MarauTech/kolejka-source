import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/date_utils.dart' as app_date;
import '../screens/train_details_screen.dart';
import 'train_card.dart';

/// Inline results, grouped against the departure selected in the form.
class ConnectionResults extends StatefulWidget {
  final List<ConnectionResult> results;
  final DateTime selectedDeparture;
  const ConnectionResults(
      {super.key, required this.results, required this.selectedDeparture});
  @override
  State<ConnectionResults> createState() => _ConnectionResultsState();
}

class _ConnectionResultsState extends State<ConnectionResults> {
  bool _showEarlier = false;
  static const _pageSize = 8;
  int _visibleCount = _pageSize;
  @override
  void didUpdateWidget(ConnectionResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results ||
        oldWidget.selectedDeparture != widget.selectedDeparture) {
      _showEarlier = false;
      _visibleCount = _pageSize;
    }
  }

  void _open(ConnectionResult result) {
    if (result.secondLeg == null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TrainDetailsScreen(result: result)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Szczegóły połączenia')),
                  body: ListView(children: [
                    for (final leg in [result, result.secondLeg!])
                      ListTile(
                        title: Text(
                            '${leg.route.commercialCategorySymbol ?? leg.commercialCategory} ${leg.trainNumber}'),
                        subtitle: Text(
                            '${leg.fromStationName} → ${leg == result ? result.secondLeg!.fromStationName : leg.toStationName}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    TrainDetailsScreen(result: leg))),
                      ),
                  ]))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final earlier = <ConnectionResult>[], upcoming = <ConnectionResult>[];
    DateTime? departure(ConnectionResult r) => app_date.scheduleDateTime(
        r.departureTime,
        r.operatingDate.isEmpty
            ? app_date.formatDateForApi(widget.selectedDeparture)
            : r.operatingDate,
        day: r.fromStop.departureDay);
    final sorted = [...widget.results]..sort((a, b) =>
        (departure(a) ?? widget.selectedDeparture)
            .compareTo(departure(b) ?? widget.selectedDeparture));
    for (final result in sorted) {
      final time = departure(result);
      (time != null && time.isBefore(widget.selectedDeparture)
              ? earlier
              : upcoming)
          .add(result);
    }
    Widget row(ConnectionResult r) =>
        TrainCard(connection: r, onTap: () => _open(r));
    final theme = Theme.of(context);
    final visible = upcoming.take(_visibleCount).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text('Wyniki połączeń',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Wrap(spacing: 8, runSpacing: 4, children: [
          Icon(Icons.calendar_today_outlined,
              size: 14, color: theme.colorScheme.onSurfaceVariant),
          Text(app_date.formatDateDisplay(widget.selectedDeparture),
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          Text(
              'Od ${app_date.formatTimeDisplay(widget.selectedDeparture.hour, widget.selectedDeparture.minute)}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary)),
        ]),
      ),
      if (widget.results.isEmpty) ...[
        const Text('Nie znaleziono połączeń'),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Zmień godzinę, datę lub stacje i spróbuj ponownie.')),
      ],
      if (earlier.isNotEmpty) ...[
        TextButton.icon(
            key: const ValueKey('earlier-connections'),
            onPressed: () => setState(() => _showEarlier = !_showEarlier),
            icon: Icon(_showEarlier ? Icons.expand_less : Icons.expand_more),
            label: Text(_showEarlier
                ? 'Ukryj wcześniejsze połączenia'
                : 'Pokaż wcześniejsze połączenia (${earlier.length})')),
        AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Column(
                children: _showEarlier
                    ? [...earlier.map(row), const Divider(thickness: 2)]
                    : [])),
      ],
      ...visible.map(row),
      if (upcoming.length > visible.length)
        TextButton.icon(
          key: const ValueKey('later-connections'),
          onPressed: () => setState(() => _visibleCount += _pageSize),
          icon: const Icon(Icons.expand_more),
          label: Text(
              'Pokaż późniejsze połączenia (${upcoming.length - visible.length})'),
        ),
    ]);
  }
}
