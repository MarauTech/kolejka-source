import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/search_screen.dart';
import 'screens/station_screen.dart';
import 'screens/disruptions_screen.dart';
import 'screens/statistics_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  await appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const TrainlyApp(),
    ),
  );
}

class TrainlyApp extends StatelessWidget {
  const TrainlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trainly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF003366),
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
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
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SearchScreen(),
    StationScreen(),
    DisruptionsScreen(),
    StatisticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load dictionaries on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadDictionaries();
    });
  }

  @override
  Widget build(BuildContext context) {
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: Color(0xFF003366)),
            label: 'Szukaj',
          ),
          NavigationDestination(
            icon: Icon(Icons.train),
            selectedIcon: Icon(Icons.train, color: Color(0xFF003366)),
            label: 'Stacja',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber),
            selectedIcon: Icon(Icons.warning_amber, color: Color(0xFF003366)),
            label: 'Utrudnienia',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF003366)),
            label: 'Status',
          ),
        ],
      ),
    );
  }
}
