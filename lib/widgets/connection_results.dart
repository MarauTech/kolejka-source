import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/date_utils.dart' as app_date;
import '../screens/train_details_screen.dart';
import 'train_card.dart';

/// Inline results, grouped against the departure selected in the form.
class ConnectionResults extends StatefulWidget {
  final List<ConnectionResult> results;
  final DateTime selectedDeparture;
  final bool showSearchDate;
  final Object? searchKey;
  final VoidCallback? onLoadNextDay;
  final DateTime? nextDay;
  final bool loadingMore;
  final String? moreMessage;
  final bool moreFailed;
  const ConnectionResults(
      {super.key,
      required this.results,
      required this.selectedDeparture,
      this.showSearchDate = true,
      this.searchKey,
      this.onLoadNextDay,
      this.nextDay,
      this.loadingMore = false,
      this.moreMessage,
      this.moreFailed = false});
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
    if (oldWidget.searchKey != widget.searchKey ||
        (widget.searchKey == null && oldWidget.results != widget.results) ||
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
              settings: const RouteSettings(name: 'Szczegóły pociągu'),
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
    DateTime? departure(ConnectionResult r) => r.effectiveDeparture(
        fallbackDate: app_date.formatDateForApi(widget.selectedDeparture));
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
    List<Widget> rowsWithDates(List<ConnectionResult> results) {
      var previousDay = DateUtils.dateOnly(widget.selectedDeparture);
      final rows = <Widget>[];
      for (final result in results) {
        final time = departure(result);
        final day = time == null ? previousDay : DateUtils.dateOnly(time);
        if (day != previousDay) {
          rows.add(Padding(
              key: ValueKey('connection-day-${app_date.formatDateForApi(day)}'),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(children: [
                Expanded(
                    child: Divider(
                        thickness: 1.2,
                        color: theme.colorScheme.outlineVariant)),
                Expanded(
                    flex: 5,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                            '${day.isAfter(previousDay) ? 'Kolejny dzień · ' : ''}${app_date.formatDateDisplay(day)}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600)))),
                Expanded(
                    child: Divider(
                        thickness: 1.2,
                        color: theme.colorScheme.outlineVariant)),
              ])));
        }
        previousDay = day;
        rows.add(row(result));
      }
      return rows;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Text('Wyniki połączeń',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ),
      if (widget.showSearchDate)
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
        const Padding(
            padding: EdgeInsets.fromLTRB(8, 20, 8, 8),
            child: Icon(Icons.search_off_rounded, size: 32)),
        const Text('Nie znaleziono połączeń',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600)),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text('Zmień godzinę, datę lub stacje i spróbuj ponownie.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
      ],
      if (earlier.isNotEmpty) ...[
        TextButton.icon(
            key: const ValueKey('earlier-connections'),
            style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
            onPressed: () => setState(() => _showEarlier = !_showEarlier),
            icon: Icon(_showEarlier ? Icons.expand_less : Icons.expand_more),
            label: Text(_showEarlier
                ? 'Ukryj wcześniejsze połączenia'
                : 'Pokaż wcześniejsze połączenia (${earlier.length})')),
        AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Column(
                children: _showEarlier
                    ? [...rowsWithDates(earlier), const Divider(thickness: 2)]
                    : [])),
      ],
      if (upcoming.isEmpty && earlier.isNotEmpty && !_showEarlier)
        Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
            child: Text(
                'Brak późniejszych połączeń w tym dniu. Sprawdź kolejny dzień lub wcześniejsze kursy.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
      ...rowsWithDates(visible),
      if (widget.moreMessage != null)
        Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: Text(widget.moreMessage!,
                style: TextStyle(
                    color: widget.moreFailed
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant))),
      if (upcoming.length > visible.length)
        TextButton.icon(
          key: const ValueKey('later-connections'),
          onPressed: () => setState(() => _visibleCount += _pageSize),
          icon: const Icon(Icons.expand_more),
          label: Text(
              'Pokaż późniejsze połączenia (${upcoming.length - visible.length})'),
        ),
      if (upcoming.length <= visible.length && widget.onLoadNextDay != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton.icon(
              key: const ValueKey('next-day-connections'),
              onPressed: widget.loadingMore
                  ? null
                  : () {
                      setState(
                          () => _visibleCount = upcoming.length + _pageSize);
                      widget.onLoadNextDay!();
                    },
              icon: widget.loadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(widget.moreFailed ? Icons.refresh : Icons.expand_more),
              label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                      widget.loadingMore
                          ? 'Wczytywanie kolejnego dnia…'
                          : widget.moreFailed
                              ? 'Spróbuj ponownie'
                              : 'Pokaż połączenia na ${widget.nextDay == null ? 'kolejny dzień' : app_date.formatDateDisplay(widget.nextDay!)}',
                      textAlign: TextAlign.center))),
        ),
    ]);
  }
}
