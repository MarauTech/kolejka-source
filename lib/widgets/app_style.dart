import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

@immutable
class SurfaceStyle extends ThemeExtension<SurfaceStyle> {
  const SurfaceStyle({this.glass = false, this.blur = true});
  final bool glass;
  final bool blur;
  @override
  SurfaceStyle copyWith({bool? glass, bool? blur}) =>
      SurfaceStyle(glass: glass ?? this.glass, blur: blur ?? this.blur);
  @override
  SurfaceStyle lerp(covariant SurfaceStyle? other, double t) =>
      t < .5 ? this : other ?? this;
}

/// Blur is removed for this session after sustained expensive frames. A single
/// network response or first-frame shader compilation must not trigger this.
class GlassFrameBudget {
  int _warmup = 20;
  int _frames = 0;
  int _slow = 0;
  bool allowBlur = true;
  void add({required Duration raster, required Duration total}) {
    if (!allowBlur) return;
    if (_warmup > 0) {
      _warmup--;
      return;
    }
    _frames++;
    if (raster.inMicroseconds > 24000 || total.inMicroseconds > 50000) _slow++;
    if (_frames == 40) {
      if (_slow >= 12) allowBlur = false;
      _frames = 0;
      _slow = 0;
    }
  }
}

class GlassPerformance extends StatefulWidget {
  const GlassPerformance(
      {super.key, required this.enabled, required this.builder});
  final bool enabled;
  final Widget Function(BuildContext, bool) builder;
  @override
  State<GlassPerformance> createState() => _GlassPerformanceState();
}

class _GlassPerformanceState extends State<GlassPerformance> {
  final _budget = GlassFrameBudget();
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timings);
  }

  void _timings(List<FrameTiming> timings) {
    if (!mounted || !widget.enabled || !_budget.allowBlur) return;
    for (final timing in timings) {
      _budget.add(raster: timing.rasterDuration, total: timing.totalSpan);
    }
    if (!_budget.allowBlur) setState(() {});
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _budget.allowBlur);
}

/// Only for navigation and modal surfaces, never individual list rows.
class GlassSurface extends StatelessWidget {
  const GlassSurface({super.key, required this.child, this.radius = 24});
  final Widget child;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<SurfaceStyle>() ?? const SurfaceStyle();
    if (!style.glass) return child;
    final accessible = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.highContrastOf(context);
    final base = theme.colorScheme.surface
        .withValues(alpha: style.blur && !accessible ? .94 : 1);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: .65)),
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              // BoxDecoration's gradient replaces its color paint. Blend the
              // reflection into the base so fallback never exposes text below.
              Color.alphaBlend(
                  Colors.white.withValues(
                      alpha: theme.brightness == Brightness.dark ? .07 : .3),
                  base),
              base
            ]),
      ),
      child: child,
    );
    return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: style.blur && !accessible
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: surface)
            : surface);
  }
}

class SoftPageTransitions extends PageTransitionsBuilder {
  const SoftPageTransitions();
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
        opacity: animation,
        child: SlideTransition(
            position: animation.drive(
                Tween(begin: const Offset(.025, 0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeOutCubic))),
            child: child));
  }
}

ThemeData kolejkaTheme(Brightness brightness,
    {bool glass = false, bool blur = true}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF2167CC), brightness: brightness)
      .copyWith(
    primary: dark ? const Color(0xFFA8C9FF) : const Color(0xFF195DB7),
    onPrimary: dark ? const Color(0xFF102A4D) : Colors.white,
    surface: dark ? const Color(0xFF161A21) : const Color(0xFFF6F7FA),
    surfaceContainerLowest: dark ? const Color(0xFF101319) : Colors.white,
    surfaceContainerLow: dark ? const Color(0xFF202630) : Colors.white,
    surfaceContainer: dark ? const Color(0xFF252D38) : const Color(0xFFEBEFF5),
    onSurface: dark ? const Color(0xFFF0F3F8) : const Color(0xFF172333),
    onSurfaceVariant: dark ? const Color(0xFFBAC5D3) : const Color(0xFF536174),
    outline: dark ? const Color(0xFF7D899B) : const Color(0xFF737F90),
    outlineVariant: dark ? const Color(0xFF424D5D) : const Color(0xFFCAD2DD),
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    extensions: [SurfaceStyle(glass: glass, blur: blur)],
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          titleLarge: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
              color: scheme.onSurface),
          titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface),
          bodyMedium:
              TextStyle(fontSize: 14, height: 1.4, color: scheme.onSurface),
        ),
    appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
            fontSize: 23,
            letterSpacing: -.5,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface)),
    cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor:
            glass ? Colors.transparent : scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withValues(alpha: .13),
        elevation: 0),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        showDragHandle: true),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.outlineVariant))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)))),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: SoftPageTransitions(),
      TargetPlatform.iOS: SoftPageTransitions(),
      TargetPlatform.windows: SoftPageTransitions(),
      TargetPlatform.macOS: SoftPageTransitions(),
      TargetPlatform.linux: SoftPageTransitions(),
      TargetPlatform.fuchsia: SoftPageTransitions(),
    }),
  );
}
