<div align="center">
  <img src="assets/branding/kolejka_icon.png" width="104" alt="Logo Kolejka">
  <h1>Kolejka <sup>BETA</sup></h1>
  <p>Połączenia, tablice stacyjne i opóźnienia. Kolej pod ręką.</p>
  <p><a href="https://marautech.github.io/kolejka/">Strona aplikacji</a> · <a href="https://github.com/MarauTech/kolejka/releases/tag/v1.0.0-beta.1">Pobierz APK</a> · <a href="https://github.com/MarauTech/kolejka/issues/new/choose">Zgłoś błąd</a></p>
  <img src="https://img.shields.io/badge/status-BETA-e5bd5a" alt="Status BETA">
  <img src="https://img.shields.io/badge/platforma-Android-16436d" alt="Android">
</div>

## O aplikacji

Kolejka to niezależna aplikacja na Androida napisana we Flutterze. Korzysta z API PKP PLK za pośrednictwem własnego proxy. Nie jest oficjalną aplikacją PKP PLK ani przewoźnika.

- **Tablica stacyjna:** odjazdy, przyjazdy, kierunki, perony i opóźnienia.
- **Połączenia:** formularz A/B, wybór daty i godziny, zwarte wyniki oraz ulubione trasy.
- **Szczegóły pociągu:** pełna trasa, godziny przyjazdu i odjazdu, wcześniejsze stacje i aktualny etap podróży.
- **Informacje:** utrudnienia ruchu oraz status dostępności danych.
- **Wygoda:** jasny i ciemny motyw, zapis lokalny, opcjonalne szukanie najbliższej stacji przez GPS.

## Pobierz wersję BETA

**[Kolejka 1.0.0-beta.1 — Android APK](https://github.com/MarauTech/kolejka/releases/download/v1.0.0-beta.1/kolejka-1.0.0-beta.1.apk)**

1. Pobierz APK na telefon z Androidem.
2. Otwórz plik i, jeśli system poprosi, zezwól użytej przeglądarce na instalowanie aplikacji. Po instalacji możesz cofnąć to uprawnienie.
3. Uruchom Kolejkę i wybierz stację lub połączenie. Konto nie jest wymagane.

Wydanie jest testowe. Mogą występować błędy i niepełne informacje zależne od dostępności API. Pozycja oszacowana z rozkładu jest oznaczona w aplikacji. APK jest podpisany osobnym kluczem wydawniczym. Wcześniejszy lokalny build debug ma inny podpis i nie aktualizuje się bezpośrednio do tego wydania; przed jego usunięciem pamiętaj o zapisanych lokalnie ulubionych.

Suma SHA-256 znajduje się w pliku `SHA256SUMS.txt` przy wydaniu. Uwagi: [CHANGELOG](CHANGELOG.md). Informacje o danych i GPS: [Prywatność](docs/PRIVACY.md).

## Uruchomienie projektu

Zweryfikowane środowisko: Flutter **3.47.2**, Dart **3.13.2**, JDK **21**, Android SDK.

```sh
git clone https://github.com/MarauTech/kolejka.git
cd kolejka
flutter pub get
flutter run
```

Domyślny adres proxy znajduje się w `lib/config.dart`. Własne wdrożenie wymaga API PKP PLK i ustawienia sekretu `PLK_API_KEY` w Workerze. Klucz API nie jest częścią aplikacji ani repozytorium.

```sh
cd worker
npm install
npx wrangler secret put PLK_API_KEY
npm run deploy
```

Ustaw adres swojego wdrożenia w `lib/config.dart`. Nie zapisuj klucza API w kodzie Fluttera.

## Weryfikacja

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

BETA zawiera 86 testów. Obejmują m.in. formularz, ulubione trasy, perony, kolory kategorii, mapowanie stacji i cały ekran szczegółów. Testy responsywności sprawdzają szerokości 320, 360, 384 i 411 px. Automatyczne sprawdzanie jest zdefiniowane w GitHub Actions.

Podpisane wydania: [instrukcja wydawania](docs/RELEASING.md). Zgłoszenia i wkład w projekt: [CONTRIBUTING](CONTRIBUTING.md).

## Struktura

| Katalog | Zawartość |
| --- | --- |
| `lib/` | Aplikacja Flutter, dane i ekrany |
| `test/` | Testy logiki oraz widoków |
| `android/` | Konfiguracja Androida |
| `assets/branding/` | Logo i ikony Kolejki |
| `worker/` | Proxy API PLK |
| `website/` | Strona pobierania publikowana przez GitHub Pages |
| `docs/` | Prywatność i proces wydań |

Nie nadano projektowi licencji open-source. Licencje zależności pozostają własnością ich autorów.
