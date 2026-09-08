import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/screens/appearance_screen.dart';
import 'package:trainly/services/bounded_cache.dart';
import 'package:trainly/services/cache_service.dart';
import 'package:trainly/utils/category_utils.dart';
import 'package:trainly/widgets/app_style.dart';
import 'package:trainly/widgets/journey_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Memory eviction retains recent writes and reads are safe during iteration',
      () {
    final cache = BoundedCache<int, List<int>>(3);
    for (var i = 0; i < 80; i++) {
      cache[i] = List.filled(100, i);
    }
    expect(cache.keys.toList(), [77, 78, 79]);
    for (final key in cache.keys) {
      expect(cache[key]!.first, key);
    }
    cache[77] = [100];
    cache[80] = [80];
    expect(cache.keys.toList(), [79, 77, 80]);
  });

  test(
      'Glass tolerates startup and isolated slow frames; sustained load disables blur',
      () {
    final budget = GlassFrameBudget();
    for (var i = 0; i < 20; i++) {
      budget.add(
          raster: const Duration(milliseconds: 100),
          total: const Duration(milliseconds: 120));
    }
    for (var i = 0; i < 80; i++) {
      budget.add(
          raster: Duration(milliseconds: i % 20 == 0 ? 40 : 5),
          total: const Duration(milliseconds: 15));
    }
    expect(budget.allowBlur, isTrue);
    for (var i = 0; i < 40; i++) {
      budget.add(
          raster: const Duration(milliseconds: 30),
          total: const Duration(milliseconds: 40));
    }
    expect(budget.allowBlur, isFalse);
  });

  for (final dark in [false, true]) {
    test(
        'Passenger text and all train badges have readable contrast, dark=$dark',
        () {
      final scheme =
          kolejkaTheme(dark ? Brightness.dark : Brightness.light).colorScheme;
      double contrast(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
      }

      for (final foreground in [
        scheme.onSurface,
        scheme.onSurfaceVariant,
        scheme.primary,
        scheme.error
      ]) {
        expect(contrast(foreground, scheme.surfaceContainerLow),
            greaterThanOrEqualTo(4.5));
      }
      for (final category in [
        'Os',
        'R',
        'RP',
        'PR',
        'KW',
        'ŁKA',
        'IR',
        'KM',
        'TLK',
        'IC',
        'EC',
        'EN',
        'EIC',
        'EIP',
        'SKM',
        'KD',
        'KMŁ',
        'KŚ'
      ]) {
        expect(
            contrast(categoryColor(category, isDark: dark),
                categoryTextColor(category, isDark: dark)),
            greaterThanOrEqualTo(4.5),
            reason: category);
      }
    });
    for (final glass in [false, true]) {
      testWidgets(
          'Appearance and glass fallback work at 320dp, dark=$dark glass=$glass',
          (tester) async {
        tester.view.physicalSize = const Size(320, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final state = AppState()..cache = CacheService();
        await state.cache.init();
        state.liquidGlass = glass;
        await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
            value: state,
            child: MaterialApp(
                theme: kolejkaTheme(dark ? Brightness.dark : Brightness.light,
                    glass: glass),
                home: const AppearanceScreen())));
        expect(find.text('Klasyczny'), findsOneWidget);
        await tester.tap(find.text(glass ? 'Klasyczny' : 'Liquid Glass'));
        await tester.pumpAndSettle();
        expect(state.liquidGlass, !glass);
        final reloaded = CacheService();
        await reloaded.init();
        expect(reloaded.loadInterfaceStyle(), glass ? 'classic' : 'glass');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(MaterialApp(
            theme: kolejkaTheme(dark ? Brightness.dark : Brightness.light,
                glass: glass),
            home: const Scaffold(body: GlassSurface(child: Text('Treść')))));
        expect(
            find.byType(BackdropFilter), glass ? findsOneWidget : findsNothing);
        await tester.pumpWidget(MaterialApp(
            theme: kolejkaTheme(dark ? Brightness.dark : Brightness.light,
                glass: glass, blur: false),
            home: const Scaffold(body: GlassSurface(child: Text('Treść')))));
        await tester.pumpAndSettle();
        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.text('Treść'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      });
    }
  }

  testWidgets(
      'Date sheet commits tomorrow and cancellation preserves the last selection',
      (tester) async {
    DateTime? selected;
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('pl', 'PL'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        supportedLocales: const [Locale('pl', 'PL')],
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    child: const Text('Data'),
                    onPressed: () async {
                      final value = await showJourneyPicker(
                          context: context,
                          initial: DateUtils.dateOnly(DateTime.now()),
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 2)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 60)));
                      if (value != null) selected = value;
                    })))));
    await tester.tap(find.text('Data'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    await tester.tap(find.text('Jutro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gotowe'));
    await tester.pumpAndSettle();
    expect(selected,
        DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1)));
    final previous = selected;
    await tester.tap(find.text('Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dzisiaj'));
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(selected, previous);
    expect(tester.takeException(), isNull);
  });
}
