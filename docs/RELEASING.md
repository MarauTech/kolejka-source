# Wydawanie Kolejki

1. Ustaw nową wersję i rosnący numer kompilacji w pubspec.yaml.
2. Uzupełnij CHANGELOG.md.
3. Uruchom formatowanie, analizę i pełne testy. Sprawdź najważniejsze ścieżki na Androidzie.
4. Przygotuj android/key.properties według android/key.properties.example. Używaj tego samego prywatnego klucza dla kolejnych aktualizacji.
5. Zbuduj `flutter build apk --release --obfuscate --split-debug-info=.private/symbols/WERSJA`. Nie pomijaj kroku pub po testach integracyjnych: odświeża rejestrację wtyczek i wyklucza wtyczkę testową z wydania. Brak konfiguracji podpisu celowo blokuje wydanie zamiast używać klucza debug.
6. Sprawdź podpis narzędziem Android apksigner. Skopiuj APK do kolejka-WERSJA.apk i policz SHA-256.
7. Utwórz tag vWERSJA i GitHub Release oznaczony jako prerelease. Dodaj APK oraz SHA256SUMS.txt.
8. Zaktualizuj numer i odnośnik na stronie pobierania, zbuduj ją i opublikuj przez GitHub Pages.

Prywatny klucz pierwszego wydania jest przechowywany lokalnie, poza Git, w .private/kolejka-release.jks. Hasła są w ignorowanym android/key.properties. Właściciel powinien wykonać bezpieczną kopię obu plików. Utrata klucza uniemożliwi podpisywanie zgodnych aktualizacji. Nie umieszczaj klucza ani haseł w repozytorium i zgłoszeniach.

CI sprawdza kod i testy, ale nie publikuje ani nie podpisuje wydań. Sekrety wydawnicze nie są udostępniane pull requestom.

Kod i historia aplikacji znajdują się w **prywatnym MarauTech/kolejka-source**. Publiczne **MarauTech/kolejka** służy wyłącznie dystrybucji. Nigdy nie wysyłaj do niego gałęzi ani historii repozytorium źródłowego.

Do publicznego repozytorium kopiuj wyłącznie zweryfikowany `website/dist/client/index.html`, wskazane przez niego CSS/obrazy, `.nojekyll`, instrukcję pobierania, politykę prywatności i szablony zgłoszeń. Nie kopiuj plików Dart, backendu, testów, map źródeł, symboli ani generowanych pakietów JavaScript/RSC. GitHub Pages publikuje katalog główny gałęzi main repozytorium dystrybucyjnego. Workflow w repozytorium źródłowym tylko sprawdza budowę strony.

Wydanie APK i sumę kontrolną dodawaj do Release w repozytorium dystrybucyjnym. Sprawdź zgodność sumy przesłanego pliku z lokalnym, a następnie pobranie bez logowania. Automatyczne archiwa „Source code” GitHuba zawierają wtedy tylko publiczną stronę i instrukcje.

APK wymaga Androida 7.0 (API 24) lub nowszego. Pierwsze wydanie zawiera ABI arm64-v8a, armeabi-v7a i x86_64. Odcisk certyfikatu SHA-256: fa249892a4174dd9d3dbe2d36a9d599e5fd97b3336fbc52126e00dd56b3e1b23.
