import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/search_utils.dart';

/// Owns input state until the modal's closing animation is fully removed.
class StationPicker extends StatefulWidget {
  const StationPicker({super.key, required this.onUseLocation});
  final VoidCallback onUseLocation;
  @override
  State<StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<StationPicker> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String _query = '';
  String _filteredQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    _debounce?.cancel();
    setState(() {
      _query = '';
      _filteredQuery = '';
    });
    _focusNode.requestFocus();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Widget _sectionTitle(String title, int count) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700))),
        Text('$count',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _stationTile(Station station, AppState state,
      {bool favorite = false, bool recent = false}) {
    final colors = Theme.of(context).colorScheme;
    final selected = state.currentStation?.id == station.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color:
            selected ? colors.secondaryContainer : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          selected: selected,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            minVerticalPadding: 14,
            horizontalTitleGap: 12,
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: selected
                      ? colors.surface
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(
                  favorite
                      ? Icons.star_rounded
                      : recent
                          ? Icons.history_rounded
                          : Icons.train_rounded,
                  color: favorite ? colors.tertiary : colors.primary,
                  size: 23),
            ),
            title: Text(station.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? colors.onSecondaryContainer : null)),
            subtitle: selected
                ? Text('Wybrana stacja',
                    style: TextStyle(
                        fontSize: 12, color: colors.onSecondaryContainer))
                : null,
            trailing: Icon(
                selected ? Icons.check_circle_rounded : Icons.chevron_right,
                size: selected ? 23 : 20,
                color: selected ? colors.primary : colors.onSurfaceVariant),
            onTap: () => Navigator.pop(context, station),
          ),
        ),
      ),
    );
  }

  Widget _locationTile(AppState state) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: state.isDetectingLocation
            ? SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: colors.onPrimaryContainer))
            : Icon(Icons.my_location_rounded,
                color: colors.onPrimaryContainer, size: 27),
        title: Text('Najbliższa stacja',
            style: TextStyle(
                color: colors.onPrimaryContainer,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        subtitle: Text(
            state.isDetectingLocation
                ? 'Ustalam Twoją lokalizację…'
                : 'Znajdź stację w swojej okolicy',
            style: TextStyle(color: colors.onPrimaryContainer, fontSize: 12)),
        trailing: state.isDetectingLocation
            ? null
            : Icon(Icons.arrow_forward_rounded,
                color: colors.onPrimaryContainer, size: 21),
        onTap: state.isDetectingLocation
            ? null
            : () {
                Navigator.pop(context);
                widget.onUseLocation();
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final normalized = normalizeStationQuery(_filteredQuery);
    final matches = normalized.isEmpty
        ? <Station>[]
        : state.stations
            .where((s) => normalizeStationQuery(s.name).startsWith(normalized))
            .toList();
    // Exact names and city prefixes precede matches in the middle of a name.
    int rank(Station station) {
      final name = normalizeStationQuery(station.name);
      return name == normalized ? 0 : (name.startsWith(normalized) ? 1 : 2);
    }

    matches.sort((a, b) {
      final order = rank(a).compareTo(rank(b));
      return order != 0 ? order : a.name.compareTo(b.name);
    });
    final results = matches.take(20).toList();
    final favoriteIds = state.favoriteStations.map((s) => s.id).toSet();
    final favorites = state.favoriteStations
        .map((s) => Station(id: s.id, name: s.name))
        .toList();
    final recentIds = <int>{};
    final recent = state.recentStations
        .where((s) => !favoriteIds.contains(s.id) && recentIds.add(s.id))
        .toList();
    final current = state.currentStation;
    final content = <Widget>[
      if (normalized.isEmpty) ...[
        _locationTile(state),
        if (favorites.isNotEmpty) ...[
          _sectionTitle('Ulubione', favorites.length),
          ...favorites.map((s) => _stationTile(s, state, favorite: true)),
        ],
        if (recent.isNotEmpty) ...[
          _sectionTitle('Ostatnio wybierane', recent.length),
          ...recent.map((s) => _stationTile(s, state, recent: true)),
        ],
        if (current != null &&
            !favoriteIds.contains(current.id) &&
            !recentIds.contains(current.id)) ...[
          _sectionTitle('Na tablicy', 1),
          _stationTile(current, state),
        ],
        if (favorites.isEmpty && recent.isEmpty && current == null)
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 28, 12, 8),
              child: Text(
                  'Wpisz miasto lub nazwę stacji. Swoje stacje możesz zapisać gwiazdką na tablicy.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant))),
      ] else if (results.isNotEmpty) ...[
        _sectionTitle('Pasujące stacje', matches.length),
        ...results.map((s) =>
            _stationTile(s, state, favorite: favoriteIds.contains(s.id))),
        if (matches.length > results.length)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Wpisz więcej znaków, aby zawęzić wyniki.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant))),
      ] else
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
            child: Column(children: [
              Icon(
                  state.isLoading
                      ? Icons.train_outlined
                      : Icons.search_off_rounded,
                  size: 42,
                  color: colors.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                  state.isLoading
                      ? 'Wczytuję listę stacji…'
                      : state.stations.isEmpty
                          ? 'Lista stacji jest niedostępna'
                          : 'Nie znajduję takiej stacji',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  state.isLoading
                      ? 'Wyniki pojawią się za chwilę.'
                      : state.stations.isEmpty
                          ? 'Możesz wybrać zapisaną stację lub spróbować ponownie później.'
                          : 'Sprawdź nazwę lub wpisz samo miasto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant)),
              if (!state.isLoading)
                TextButton(
                    onPressed: _clearSearch,
                    child: const Text('Wyczyść wyszukiwanie')),
            ])),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      final height = math.min(MediaQuery.sizeOf(context).height * .88,
          math.max(0.0, constraints.maxHeight - keyboard));
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: height,
          child: CustomScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                  child: Column(children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 6),
                        decoration: BoxDecoration(
                            color: colors.outlineVariant,
                            borderRadius: BorderRadius.circular(4)))),
                Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 8, 12),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Wybierz stację',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Sprawdź odjazdy i przyjazdy',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant)),
                          ])),
                      IconButton(
                          tooltip: 'Zamknij wybór stacji',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded)),
                    ])),
              ])),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchHeader(
                  height: math.max(
                      80, 54 * MediaQuery.textScalerOf(context).scale(1) + 24),
                  child: ColoredBox(
                    color: colors.surface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _focusNode.unfocus(),
                        decoration: InputDecoration(
                          hintText: 'Miasto lub nazwa stacji',
                          filled: true,
                          fillColor: colors.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: colors.onSurfaceVariant),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Wyczyść wyszukiwanie',
                                  onPressed: _clearSearch,
                                  icon: const Icon(Icons.cancel_rounded)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  BorderSide(color: colors.primary, width: 2)),
                        ),
                        onChanged: (value) {
                          setState(() => _query = value);
                          _debounce?.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 180), () {
                            if (mounted) {
                              setState(() => _filteredQuery = value);
                              // A new query must start with its best matches.
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0);
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    20, 4, 20, 20 + MediaQuery.paddingOf(context).bottom),
                sliver: SliverList.list(children: content),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SearchHeader extends SliverPersistentHeaderDelegate {
  _SearchHeader({required this.child, required this.height});
  final Widget child;
  final double height;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);
  @override
  bool shouldRebuild(_SearchHeader oldDelegate) => true;
}
