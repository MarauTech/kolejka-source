# Trainly - Rozkład jazdy kolei w Polsce

Trainly to aplikacja mobilna stworzona w technologii Flutter, która umożliwia sprawdzanie rozkładów jazdy pociągów, statystyk opóźnień oraz informacji o zakłóceniach korzystając z oficjalnego API PKP PLK.

## Wymagania wstępne
- Flutter SDK w wersji 3.x
- Dart SDK
- Android SDK (do budowy aplikacji na Androida)

## Instrukcja uruchomienia i instalacji

### 1. Przygotowanie środowiska Flutter
1. Zainstaluj [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Sprawdź poprawność instalacji uruchamiając w terminalu:
   ```bash
   flutter doctor
   ```
3. Pobierz wszystkie wymagane zależności projektu:
   ```bash
   flutter pub get
   ```

### 2. Konfiguracja Cloudflare Worker (Proxy)
Aplikacja łączy się z API PKP PLK za pośrednictwem Cloudflare Workera w celu ukrycia klucza API i ominięcia problemów z CORS.
1. Wejdź do katalogu `worker`:
   ```bash
   cd worker
   ```
2. Zainstaluj narzędzie Wrangler:
   ```bash
   npm install -g wrangler
   ```
3. Skonfiguruj klucz API PKP PLK. Zostaniesz poproszony o wklejenie swojego klucza:
   ```bash
   wrangler secret put PLK_API_KEY
   ```
4. Wdróż Workera na serwery Cloudflare:
   ```bash
   wrangler deploy
   ```
5. Po wdrożeniu skopiuj otrzymany URL workera.

### 3. Konfiguracja aplikacji mobilnej
1. Otwórz plik `lib/config.dart` (jeśli nie istnieje - utwórz go lub odszukaj miejsce na URL API).
2. Ustaw URL wdrożonego workera jako bazowy adres API.

### 4. Uruchamianie i Budowanie
- **Aby uruchomić aplikację w trybie deweloperskim (na podłączonym urządzeniu lub emulatorze):**
  ```bash
  flutter run
  ```
- **Aby zbudować aplikację w wersji Release (APK):**
  ```bash
  flutter build apk --release
  ```
  *Gotowy plik APK będzie znajdować się w lokalizacji: `build/app/outputs/flutter-apk/app-release.apk`*
- **Aby zbudować aplikację w trybie Debug (APK):**
  ```bash
  flutter build apk --debug
  ```

## Architektura projektu
Projekt został oparty o prostą płaską architekturę dla łatwości czytania kodu:
- Wykorzystano `dio` do komunikacji HTTP.
- Wykorzystano `shared_preferences` do prostego cache'owania danych.
- Wykorzystano `provider` do zarządzania stanem aplikacji.
- Design oparty jest o zasady Material 3.
- Wszystkie teksty interfejsu użytkownika (UI) są w języku polskim.

## Używane Endopinty API
Proxy i aplikacja wykorzystują następujące końcówki API PKP PLK (wersja `/api/v1/`):
- `/schedules` (oraz `/shortened`)
- `/schedules/route/*`
- `/schedules/routes/*`
- `/operations` (oraz `/shortened`)
- `/operations/train/*`
- `/operations/statistics`
- `/disruptions` (oraz `/shortened`)
- Słowniki: `/dictionaries/stations`, `/dictionaries/carriers`, `/dictionaries/commercial-categories`, `/dictionaries/stop-types`, `/dictionaries/cities`
- Inne: `/data-version`, `/fields/schedules`, `/fields/operations`, `/fields/disruptions`
