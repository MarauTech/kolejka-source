import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';

class StationSearchField extends StatefulWidget {
  final String label;
  final List<Station> stations;
  final Station? selectedStation;
  final ValueChanged<Station?> onStationSelected;

  const StationSearchField({
    super.key,
    required this.label,
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
      if (_controller.text != newText) {
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

        final query = textEditingValue.text.toLowerCase().trim();
        final startsWithList = <Station>[];
        final containsList = <Station>[];

        for (final station in widget.stations) {
          final sName = station.name.toLowerCase();
          if (sName.startsWith(query)) {
            startsWithList.add(station);
          } else if (sName.contains(query)) {
            containsList.add(station);
          }
          if (startsWithList.length + containsList.length >= 25) break;
        }

        return [...startsWithList, ...containsList].take(20);
      },
      onSelected: (Station selection) {
        widget.onStationSelected(selection);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(Icons.location_on_outlined,
                color: theme.colorScheme.primary),
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              if (value.isEmpty) {
                widget.onStationSelected(null);
              }
            });
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
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
              child: ListView.builder(
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
                      style: TextStyle(color: theme.colorScheme.onSurface),
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
