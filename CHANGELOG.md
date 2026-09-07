# Historia zmian

## 1.0.0-beta.2 — 2026-09-07

- Czytelne rozróżnienie danych czasu rzeczywistego od informacji wyłącznie rozkładowych.
- Czas przejazdu jest liczony z tych samych godzin, które widzi pasażer.
- Wyszukiwanie stacji działa także bez polskich znaków i informuje o braku wyników.
- Polski kalendarz i krótsze etykiety dolnej nawigacji na małych ekranach.
- Wyniki połączeń znajdują się przed ulubionymi trasami, a wybór ulubionej trasy od razu wyszukuje połączenie.
- Czytelniejsze przystanki trasy z pełnymi etykietami przyjazdu, odjazdu, peronu i toru.
- Utrudnienia mają nagłówki odcinków, filtr i krótsze opisy bez powtarzających się etykiet.
- Poprawione kolory kategorii złożonych oraz przewidywany czas podróży przy opóźnieniach.
- 93 testy, w tym regresje interfejsu dla szerokości 320–411 px.

## 1.0.0-beta.1 — 2026-09-06

Pierwsze publiczne wydanie BETA na Androida.

- Zwarty formularz A/B i wyniki połączeń w jednym ekranie.
- Ulubione trasy pod formularzem; wybór ustawia dziś i teraz.
- Tablice stacyjne z oddzieleniem wcześniejszych odjazdów.
- Pełna trasa pociągu ze zwijaniem wcześniejszych stacji.
- Wspólne kolory kategorii, perony rzymskie oraz czerwone opóźnione godziny.
- Dopasowanie wykonania do stacji i kursu z kontrolą daty; regresja rozbieżnych list.
- Uproszczone utrudnienia i status danych bez surowych odpowiedzi API.
- 86 testów; podpisany APK release oraz strona pobierania.

### Znane ograniczenia

- BETA może zawierać błędy. Dane i opóźnienia zależą od źródła PLK i dostępności proxy.
- Pozycja bywa szacowana na podstawie rozkładu, co jest oznaczane w interfejsie.
- Zakres przesiadek zależy od istniejącego wyszukiwania; nie jest to kompletny planer wszystkich możliwych podróży.
- Pierwsze przejście z lokalnej wersji debug wymaga instalacji z innym podpisem. Przed usunięciem starej aplikacji pamiętaj o ulubionych.
