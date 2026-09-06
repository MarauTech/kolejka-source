import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../services/location_service.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  LocationPermissionStatus _status = LocationPermissionStatus.denied;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    final appState = context.read<AppState>();
    final status = await appState.locationService.checkPermission();
    if (mounted) {
      setState(() {
        _status = status;
        _isChecking = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final appState = context.read<AppState>();
    await appState.locationService.requestPermission();
    await _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String statusTitle;
    String statusSubtitle;
    Color statusColor;
    IconData statusIcon;

    switch (_status) {
      case LocationPermissionStatus.granted:
        statusTitle = 'Uprawnienie przyznane';
        statusSubtitle =
            'Aplikacja może automatycznie wykrywać najbliższą stację kolejową.';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case LocationPermissionStatus.serviceDisabled:
        statusTitle = 'Lokalizacja w urządzeniu jest wyłączona';
        statusSubtitle =
            'Moduł GPS w telefonie jest wyłączony. Włącz lokalizację w ustawieniach systemu.';
        statusColor = Colors.orange;
        statusIcon = Icons.location_off_outlined;
        break;
      case LocationPermissionStatus.permanentlyDenied:
        statusTitle = 'Dostęp zablokowany w systemie';
        statusSubtitle =
            'Uprawnienie zostało trwale zablokowane. Aby je włączyć, przejdź do ustawień aplikacji w Androidzie.';
        statusColor = Colors.red;
        statusIcon = Icons.block;
        break;
      case LocationPermissionStatus.denied:
      default:
        statusTitle = 'Brak uprawnienia';
        statusSubtitle = 'Aplikacja nie posiada zgody na odczyt lokalizacji.';
        statusColor = Colors.orange;
        statusIcon = Icons.help_outline;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uprawnienia',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (_isChecking)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    statusSubtitle,
                    style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_status != LocationPermissionStatus.granted)
                        FilledButton.icon(
                          onPressed: _requestPermission,
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text('Zezwól na dostęp'),
                        ),
                      if (_status == LocationPermissionStatus.permanentlyDenied)
                        OutlinedButton.icon(
                          onPressed: () => Geolocator.openAppSettings(),
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text('Ustawienia aplikacji'),
                        ),
                      if (_status == LocationPermissionStatus.serviceDisabled)
                        OutlinedButton.icon(
                          onPressed: () => Geolocator.openLocationSettings(),
                          icon: const Icon(Icons.location_on, size: 18),
                          label: const Text('Włącz lokalizację w telefonie'),
                        ),
                      TextButton.icon(
                        onPressed: _checkStatus,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Odśwież stan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Privacy explanation
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 22, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Prywatność danych lokalizacyjnych',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lokalizacja GPS jest wykorzystywana WYŁĄCZNIE na Twoim urządzeniu do obliczenia odległości (wzór Haversine) od pobliskich stacji kolejowych pobranych z OpenStreetMap.\n\n'
                    'Aplikacja nie śledzi Twojego położenia w tle, nie profiluje użytkowników ani nie przesyła Twoich współrzędnych do zewnętrznych serwerów reklamowych.\n\n'
                    'W dowolnej chwili możesz korzystać z aplikacji bez uprawnień GPS, wybierając stacje ręcznie z wyszukiwarki.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
