import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'models/models.dart';
import 'screens/station_screen.dart';
import 'screens/search_screen.dart';
import 'screens/train_search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/more_screen.dart';
import 'services/app_diagnostics.dart';
import 'services/cache_service.dart';
import 'widgets/app_style.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDiagnostics.install();
  runApp(const KolejkaBootstrap());
}

class KolejkaBootstrap extends StatefulWidget {
  const KolejkaBootstrap({super.key});
  @override
  State<KolejkaBootstrap> createState() => _KolejkaBootstrapState();
}

class _KolejkaBootstrapState extends State<KolejkaBootstrap> {
  late Future<AppState> _initialization;
  AppState? _state;
  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<AppState> _initialize() async {
    final state = AppState();
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await CacheService.migrateLegacyAndroid(
            CacheService.androidLegacyStore());
      }
      await state.init();
      if (!mounted) {
        state.dispose();
        throw StateError('Initialization cancelled');
      }
      _state = state;
      return state;
    } catch (error, stack) {
      if (mounted) {
        state.dispose();
        AppDiagnostics.record(error, stack);
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _state?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppState>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ChangeNotifierProvider.value(
                value: snapshot.data!, child: const KolejkaApp());
          }
          return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                    child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: snapshot.hasError
                      ? Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text(
                              'Nie udało się odczytać ustawień aplikacji. Twoje dane nie zostały wyczyszczone.',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                              onPressed: () => setState(() {
                                    _initialization = _initialize();
                                  }),
                              child: const Text('Spróbuj ponownie')),
                        ])
                      : const CircularProgressIndicator(),
                )),
              ));
        },
      );
}

class KolejkaApp extends StatelessWidget {
  const KolejkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return GlassPerformance(
        enabled: appState.liquidGlass,
        builder: (context, allowBlur) => MaterialApp(
              scaffoldMessengerKey: AppDiagnostics.messengerKey,
              navigatorObservers: [AppDiagnostics.observer],
              title: 'Kolejka',
              debugShowCheckedModeBanner: false,
              locale: const Locale('pl', 'PL'),
              supportedLocales: const [Locale('pl', 'PL')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: appState.themeMode,
              theme: kolejkaTheme(Brightness.light,
                  glass: appState.liquidGlass, blur: allowBlur),
              darkTheme: kolejkaTheme(Brightness.dark,
                  glass: appState.liquidGlass, blur: allowBlur),
              home: const MainScreen(),
            ));
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Journey planning is the first destination, including on a fresh launch.
  int _currentIndex = 0;

  FavoriteRoute? _requestedRoute;
  int _searchRequest = 0;

  @override
  void initState() {
    super.initState();

    // Initialize dictionaries & nearest station on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().loadDictionaries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestedRoute = _requestedRoute;
    final screens = <Widget>[
      SearchScreen(
        key: ValueKey('connections-$_searchRequest'),
        initialFromStation: requestedRoute == null
            ? null
            : Station(
                id: requestedRoute.fromStationId,
                name: requestedRoute.fromStationName),
        initialToStation: requestedRoute == null
            ? null
            : Station(
                id: requestedRoute.toStationId,
                name: requestedRoute.toStationName),
        searchOnStart: requestedRoute != null,
      ),
      const StationScreen(),
      const TrainSearchScreen(),
      FavoritesScreen(onNavigateToTab: (index) {
        setState(() => _currentIndex = index);
      }, onOpenRoute: (route) {
        setState(() {
          _requestedRoute = route;
          _searchRequest++;
          _currentIndex = 0;
        });
      }),
      const MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: GlassSurface(
          radius: 0,
          child: NavigationBar(
            labelTextStyle:
                WidgetStateProperty.resolveWith((states) => TextStyle(
                      fontSize: 10.5,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.w600
                          : FontWeight.w500,
                    )),
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              AppDiagnostics.tab = [
                'Połączenia',
                'Tablica',
                'Pociąg',
                'Ulubione',
                'Więcej'
              ][index];
              setState(() => _currentIndex = index);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.route_outlined),
                selectedIcon:
                    Icon(Icons.route, color: theme.colorScheme.primary),
                label: 'Połączenia',
              ),
              NavigationDestination(
                icon: const Icon(Icons.table_chart_outlined),
                selectedIcon:
                    Icon(Icons.table_chart, color: theme.colorScheme.primary),
                label: 'Tablica',
              ),
              NavigationDestination(
                icon: const Icon(Icons.train_outlined),
                selectedIcon:
                    Icon(Icons.train, color: theme.colorScheme.primary),
                label: 'Pociąg',
              ),
              NavigationDestination(
                icon: const Icon(Icons.star_outline),
                selectedIcon:
                    Icon(Icons.star, color: theme.colorScheme.primary),
                label: 'Ulubione',
              ),
              NavigationDestination(
                icon: const Icon(Icons.more_horiz_outlined),
                selectedIcon:
                    Icon(Icons.more_horiz, color: theme.colorScheme.primary),
                label: 'Więcej',
              ),
            ],
          )),
    );
  }
}
