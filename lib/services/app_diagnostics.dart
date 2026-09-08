import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Diagnostic context contains screen/operation names, never request payloads.
class AppDiagnostics {
  static String tab = 'Połączenia';
  static String route = '/';
  static String operation = 'Uruchamianie aplikacji';
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static final observer = _DiagnosticsObserver();
  static String get screen => route == '/' ? tab : route;

  static String redact(String message) => message
      .replaceAll(
          RegExp(r'(?:X-API-Key|PLK_API_KEY|API\s*key)\s*[:=]?\s*\S+',
              caseSensitive: false),
          '[REDACTED]')
      .replaceAll(RegExp(r'[A-Za-z0-9_+/=-]{40,}'), '[REDACTED]');

  static void record(Object error, StackTrace? stack) {
    if (kDebugMode) {
      debugPrint('[Crash] screen=$screen operation=$operation');
      debugPrint(redact('$error'));
      if (stack != null) debugPrint(redact('$stack'));
    }
  }

  static void install() {
    FlutterError.onError = (details) {
      record(details.exception, details.stack);
      if (kDebugMode) {
        FlutterError.presentError(FlutterErrorDetails(
          exception: ErrorDescription(redact('${details.exception}')),
          stack: details.stack,
          library: details.library,
        ));
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack);
      messengerKey.currentState?.showSnackBar(const SnackBar(
          content:
              Text('Nie udało się zakończyć operacji. Spróbuj ponownie.')));
      return true;
    };
    if (kReleaseMode) {
      ErrorWidget.builder = (_) => const Directionality(
            textDirection: TextDirection.ltr,
            child: ColoredBox(
                color: Color(0xFFF5F6F8),
                child: Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'Nie udało się wyświetlić tej części ekranu. Wróć i spróbuj ponownie.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF202733), fontSize: 16)),
                ))),
          );
    }
  }
}

class _DiagnosticsObserver extends NavigatorObserver {
  void _select(Route<dynamic>? route) {
    AppDiagnostics.route = route?.settings.name ?? 'Panel szczegółów';
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _select(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _select(previousRoute);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _select(newRoute);
}
