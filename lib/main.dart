import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
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
  // Tablica is the default starting tab (index 0)
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      const StationScreen(), // 1. Tablica (default)
      const SearchScreen(), // 2. Połączenia
      const TrainSearchScreen(), // 3. Pociąg
      FavoritesScreen(
        onNavigateToTab: (index) {
          setState(() => _currentIndex = index);
        },
      ), // 4. Ulubione
      const MoreScreen(), // 5. Więcej
    ];

    // Initialize dictionaries & nearest station on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadDictionaries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.table_chart_outlined),
            selectedIcon:
                Icon(Icons.table_chart, color: theme.colorScheme.primary),
            label: 'Tablica',
          ),
          NavigationDestination(
            icon: const Icon(Icons.alt_route_outlined),
            selectedIcon:
                Icon(Icons.alt_route, color: theme.colorScheme.primary),
            label: 'Połączenia',
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
