import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_style.dart';

Future<DateTime?> showJourneyPicker({
  required BuildContext context,
  required DateTime initial,
  bool time = false,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<DateTime>(
    context: context,
    routeSettings:
        RouteSettings(name: time ? 'Wybierz godzinę' : 'Wybierz datę'),
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: reduceMotion
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 260),
            reverseDuration: Duration(milliseconds: 200)),
    builder: (_) => _JourneyPicker(
        initial: initial, time: time, firstDate: firstDate, lastDate: lastDate),
  );
}

class _JourneyPicker extends StatefulWidget {
  const _JourneyPicker(
      {required this.initial,
      required this.time,
      this.firstDate,
      this.lastDate});
  final DateTime initial;
  final bool time;
  final DateTime? firstDate, lastDate;
  @override
  State<_JourneyPicker> createState() => _JourneyPickerState();
}

class _JourneyPickerState extends State<_JourneyPicker> {
  late DateTime _value = _clamp(widget.initial);
  int _wheel = 0;
  DateTime _clamp(DateTime date) {
    if (widget.firstDate != null && date.isBefore(widget.firstDate!)) {
      return widget.firstDate!;
    }
    if (widget.lastDate != null && date.isAfter(widget.lastDate!)) {
      return widget.lastDate!;
    }
    return date;
  }

  void _shortcut(DateTime date) => setState(() {
        _value = _clamp(date);
        _wheel++;
      });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<SurfaceStyle>()?.glass ?? false;
    return GlassSurface(
        child: Container(
      decoration: BoxDecoration(
          color: glass
              ? Colors.transparent
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              Text(widget.time ? 'Wybierz godzinę' : 'Wybierz datę',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Anuluj')),
                TextButton(
                    key: const ValueKey('picker-done'),
                    onPressed: () => Navigator.pop(context, _value),
                    child: const Text('Gotowe',
                        style: TextStyle(fontWeight: FontWeight.w700))),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (widget.time)
                  ActionChip(
                      label: const Text('Teraz'),
                      onPressed: () => _shortcut(DateTime.now()))
                else ...[
                  ActionChip(
                      label: const Text('Dzisiaj'),
                      onPressed: () =>
                          _shortcut(DateUtils.dateOnly(DateTime.now()))),
                  const SizedBox(width: 12),
                  ActionChip(
                      label: const Text('Jutro'),
                      onPressed: () => _shortcut(
                          DateUtils.dateOnly(DateTime.now())
                              .add(const Duration(days: 1)))),
                ],
              ]),
              SizedBox(
                  height: 208,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                        brightness: theme.brightness,
                        primaryColor: theme.colorScheme.primary,
                        textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: TextStyle(
                                fontSize: 20,
                                color: theme.colorScheme.onSurface))),
                    child: CupertinoDatePicker(
                      key: ValueKey('journey-wheel-$_wheel'),
                      mode: widget.time
                          ? CupertinoDatePickerMode.time
                          : CupertinoDatePickerMode.date,
                      initialDateTime: _value,
                      minimumDate: widget.time ? null : widget.firstDate,
                      maximumDate: widget.time ? null : widget.lastDate,
                      minimumYear: widget.firstDate?.year ?? 1,
                      maximumYear: widget.lastDate?.year,
                      use24hFormat: true,
                      dateOrder: DatePickerDateOrder.dmy,
                      onDateTimeChanged: (value) => _value = value,
                    ),
                  )),
            ]),
          )),
    ));
  }
}

class JourneyField extends StatelessWidget {
  const JourneyField(
      {super.key,
      required this.label,
      required this.value,
      required this.icon,
      required this.onTap});
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(14)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 15, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Flexible(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant)))
              ]),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface)),
            ]),
          ),
        ));
  }
}
