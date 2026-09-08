import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/search_utils.dart';

class StationSearchField extends StatefulWidget {
  final String label;
  final String? marker;
  final List<Station> stations;
  final Station? selectedStation;
  final ValueChanged<Station?> onStationSelected;

  const StationSearchField({
    super.key,
    required this.label,
    this.marker,
    required this.stations,
    this.selectedStation,
    required this.onStationSelected,
  });

  @override
  State<StationSearchField> createState() => _StationSearchFieldState();
}

class _StationSearchFieldState extends State<StationSearchField> {
  late TextEditingController _controller;
  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();
  bool _queryHasMatch = true;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.selectedStation?.name ?? '');
  }

  @override
  void didUpdateWidget(covariant StationSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedStation != oldWidget.selectedStation) {
      final newText = widget.selectedStation?.name ?? '';
      if (_controller.text != newText &&
          !(widget.marker != null &&
              widget.selectedStation == null &&
              _focusNode.hasFocus)) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RawAutocomplete<Station>(
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (Station option) => option.name,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.trim().isEmpty) {
          return const Iterable<Station>.empty();
        }

        final query = normalizeStationQuery(textEditingValue.text);
        final startsWithList = <Station>[];

        for (final station in widget.stations) {
          final sName = normalizeStationQuery(station.name);
          if (sName.startsWith(query)) {
            startsWithList.add(station);
          }
          if (startsWithList.length >= 20) break;
        }

        return startsWithList;
      },
      onSelected: (Station selection) {
        widget.onStationSelected(selection);
        if (widget.marker != null) _focusNode.unfocus();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: widget.marker == null
                ? Icon(Icons.location_on_outlined,
                    color: theme.colorScheme.primary)
                : SizedBox(
                    width: 28,
                    child: Center(
                        child: Text(widget.marker!,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary)))),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 28, minHeight: 40),
            border: widget.marker == null
                ? const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)))
                : const UnderlineInputBorder(),
            enabledBorder: widget.marker == null
                ? null
                : UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: theme.colorScheme.outlineVariant)),
            focusedBorder: widget.marker == null
                ? null
                : UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: theme.colorScheme.primary, width: 1.5)),
            fillColor: widget.marker == null ? null : Colors.transparent,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            helperText: controller.text.trim().isNotEmpty && !_queryHasMatch
                ? 'Nie znaleziono stacji'
                : null,
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      widget.onStationSelected(null);
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            if (widget.marker != null &&
                widget.selectedStation != null &&
                value != widget.selectedStation!.name) {
              widget.onStationSelected(null);
            }
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            final query = normalizeStationQuery(value);
            final hasMatch = query.isEmpty ||
                widget.stations.any((station) =>
                    normalizeStationQuery(station.name).startsWith(query));
            if (hasMatch != _queryHasMatch) {
              setState(() => _queryHasMatch = hasMatch);
            } else {
              setState(() {});
            }
            _debounce = Timer(const Duration(milliseconds: 300), () {
              if (value.isEmpty) {
                widget.onStationSelected(null);
              }
            });
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final hasQuery = _controller.text.trim().isNotEmpty;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(10),
            color: theme.colorScheme.surfaceContainer,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 250,
                maxWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: options.isEmpty && hasQuery
                  ? const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text('Nie znaleziono stacji'),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.train,
                              size: 18, color: theme.colorScheme.primary),
                          title: Text(
                            option.name,
                            style:
                                TextStyle(color: theme.colorScheme.onSurface),
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
