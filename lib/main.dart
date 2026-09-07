import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'models/models.dart';
import 'screens/station_screen.dart';
import 'screens/search_screen.dart';
import 'screens/train_search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/more_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  await appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const KolejkaApp(),
    ),
  );
}

class KolejkaApp extends StatelessWidget {
  const KolejkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    const seedColor = Color(0xFF003366);

    return MaterialApp(
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          margin: EdgeInsets.zero,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const MainScreen(),
    );
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
      FavoritesScreen(onOpenRoute: (route) {
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
      bottomNavigationBar: NavigationBar(
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 10.5,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w500,
            )),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route, color: theme.colorScheme.primary),
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
            selectedIcon: Icon(Icons.train, color: theme.colorScheme.primary),
            label: 'Pociąg',
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star, color: theme.colorScheme.primary),
            label: 'Ulubione',
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_outlined),
            selectedIcon:
                Icon(Icons.more_horiz, color: theme.colorScheme.primary),
            label: 'Więcej',
          ),
        ],
      ),
    );
  }
}
