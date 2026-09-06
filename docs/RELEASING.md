# Wydawanie Kolejki

1. Ustaw nową wersję i rosnący numer kompilacji w pubspec.yaml.
2. Uzupełnij CHANGELOG.md.
3. Uruchom formatowanie, analizę i pełne testy. Sprawdź najważniejsze ścieżki na Androidzie.
4. Przygotuj android/key.properties według android/key.properties.example. Używaj tego samego prywatnego klucza dla kolejnych aktualizacji.
5. Zbuduj `flutter build apk --release`. Brak konfiguracji podpisu celowo blokuje wydanie zamiast używać klucza debug.
6. Sprawdź podpis narzędziem Android apksigner. Skopiuj APK do kolejka-WERSJA.apk i policz SHA-256.
7. Utwórz tag vWERSJA i GitHub Release oznaczony jako prerelease. Dodaj APK oraz SHA256SUMS.txt.
8. Zaktualizuj numer i odnośnik na stronie pobierania, zbuduj ją i opublikuj przez Sites.

Prywatny klucz pierwszego wydania jest przechowywany lokalnie, poza Git, w .private/kolejka-release.jks. Hasła są w ignorowanym android/key.properties. Właściciel powinien wykonać bezpieczną kopię obu plików. Utrata klucza uniemożliwi podpisywanie zgodnych aktualizacji. Nie umieszczaj klucza ani haseł w repozytorium i zgłoszeniach.

CI sprawdza kod i testy, ale nie publikuje ani nie podpisuje wydań. Sekrety wydawnicze nie są udostępniane pull requestom.

APK wymaga Androida 7.0 (API 24) lub nowszego. Pierwsze wydanie zawiera ABI arm64-v8a, armeabi-v7a i x86_64. Odcisk certyfikatu SHA-256: fa249892a4174dd9d3dbe2d36a9d599e5fd97b3336fbc52126e00dd56b3e1b23.
