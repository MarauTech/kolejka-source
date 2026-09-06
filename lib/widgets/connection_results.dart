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
  @override
  void didUpdateWidget(ConnectionResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results) _showEarlier = false;
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 12),
      Text('Wyniki połączeń',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
      const Divider(),
      if (widget.results.isEmpty) ...[
        const Text('Nie znaleziono połączeń'),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Zmień godzinę, datę lub stacje i spróbuj ponownie.')),
      ],
      ...upcoming.map(row),
      if (earlier.isNotEmpty) ...[
        TextButton.icon(
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
                    ? [const Divider(thickness: 2), ...earlier.map(row)]
                    : [])),
      ],
    ]);
  }
}
