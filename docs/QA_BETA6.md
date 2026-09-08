# Kolejka — audyt użytkowy i poprawki beta 6

Data: 7 września 2026. Wersja końcowa: **1.0.0-beta.6, kompilacja 7**. Testowane urządzenie: emulator Samsung_s24, Android 36.1. Wersja debug, rozdzielczość 1080 × 2340, szerokości logiczne 320, 360, 384 i 411 oraz obrót poziomy. Emulator używał czasu UTC; godziny zapisane na zrzutach odpowiadają jego ustawieniom.

Najpierw wykonano audyt beta 5, następnie poprawki i ponowną kontrolę. Podczas drugiej kontroli wykryto dodatkowy błąd Q18; odtworzono go testem, naprawiono i ponownie uruchomiono cały zestaw testów oraz APK. **18 potwierdzonych błędów naprawiono; w wykonanym zakresie nie pozostał otwarty błąd aplikacji.** Nie jest to gwarancja braku wszystkich możliwych usterek ani test wydajności wersji release na telefonie.

## Wyniki i zakres

| Pozycja | Wynik |
|---|---|
| Odwiedzone widoki aplikacji | 18 rodzajów ekranów/paneli, dodatkowo systemowe zgody i ustawienia Androida |
| Scenariusze | 44 grupy opisane niżej; obejmują rzeczywiste interakcje i wskazane przypadki kontrolowane |
| Znalezione błędy | 18: 1 krytyczny, 13 wysokich, 3 średnie, 1 niski |
| Naprawione / otwarte potwierdzone | 18 / 0 |
| Dowody | 447 zapisanych PNG i 444 odczyty XML; nie każdy krok ma oba pliki |
| Formatowanie | PASS — 55 plików, 0 dalszych zmian |
| `flutter analyze` | PASS — bez uwag |
| `flutter test` | PASS — 121 testów |
| Testy integracyjne na Androidzie | PASS — 46 testów |
| `flutter build apk --debug` | PASS |
| Podpis i instalacja APK | PASS — dotychczasowy certyfikat, instalacja w emulatorze |
| Logcat całej sesji | **ERRORS** — 16 obsłużonych `SocketException` podczas celowo wyłączanej sieci; szczegóły niżej |
| Nieobsłużone błędy końcowego Flutter UI | 0; po testach i po restarcie również 0 `ErrorWidget` |

18 widoków to: formularz połączeń, wyniki połączeń, tablica stacyjna, panel wyboru stacji, wyszukiwarka pociągu, szczegóły pociągu, ulubione stacje, ulubione trasy, Więcej, Wygląd, Uprawnienia, Usługa i źródło danych, O aplikacji, lista utrudnień, szczegóły utrudnienia, Status sieci, kalendarz i wybór godziny. Odjazdy i przyjazdy są wariantami jednej tablicy, a nie dodatkowymi ekranami w tym liczniku. 46 testów integracyjnych powtarza wybrane scenariusze na silniku Androida; nie należy dodawać tej liczby do 44 jako niezależnych funkcji.

Dokumentacja robocza i pełne dowody znajdują się w [katalogu audytu](C:/Users/Maciej/Desktop/Trainly/artifacts/qa-2026-09-07). Numery w tabelach są prefiksami nazw kroków w `screenshots` i `actions.jsonl`. Zrzuty z fazy początkowej mają numery 001–215, z powtórzeń 300–514. Część kroków ma tylko XML lub wpis akcji, ponieważ narzędzie przerwało zapis zdjęcia; nie zaliczono ich do liczby PNG. Udane zdjęcia głównych widoków zostały uzupełnione.

## Potwierdzone błędy i poprawki

| ID | Ekran / opis błędu | Poziom | Jak odtworzyć przed poprawką | Przyczyna | Naprawiono | Ponowna weryfikacja |
|---|---|---|---|---|---|---|
| Q01 | Tablica: ujemne opóźnienie jako czerwone `+-1` | Wysoki | Otworzyć przyjazd z wyprzedzeniem jednej minuty (006, 092) | Każda wartość różna od zera formatowana jako dodatnie opóźnienie | Tak: znak zgodny z wartością, wyprzedzenie zielone | Test całego wiersza z `-1`; brak `+-1`, placeholderów i ID |
| Q02 | Uprawnienia: ponowna prośba nic nie robi po trwałej odmowie | Wysoki | Dwukrotnie odmówić zgody i nacisnąć prośbę ponownie (010–011) | Pomijany wynik natywnej prośby; Android nie zwraca trwałej odmowy przy każdym późniejszym sprawdzeniu | Tak: zapamiętanie trwałej odmowy, przejście do ustawień | 304–308: odmowa, trwała odmowa i ustawienia |
| Q03 | Uprawnienia: nieaktualny status po powrocie z ustawień | Średni | Włączyć GPS poza aplikacją i wrócić (018) | Brak odczytu statusu po wznowieniu | Tak: ponowna kontrola po powrocie | 308 i 313: status aktualizuje się automatycznie |
| Q04 | IC wyświetlane jako szare „InterCity” | Średni | Otworzyć szczegóły lub wyszukać kurs Intercity (040, 154) | Użycie pełnej nazwy kategorii zamiast symbolu | Tak: wspólne symbole w wynikach, tablicy i szczegółach | 441–442, 451–455, 476, 483: pomarańczowe IC |
| Q05 | Opóźniony nadchodzący pociąg ukryty we wcześniejszych połączeniach | Wysoki | Szukać po godzinie planowej, ale przed rzeczywistym odjazdem (039, 044) | Grupowanie i sortowanie według planu | Tak: pełna rzeczywista data odjazdu, następnie plan z opóźnieniem | Test graniczny oraz 441: IC8304 plan 18:10, rzeczywisty 18:49, zapytanie od 18:30 — widoczny w nadchodzących |
| Q06 | Polski wybór czasu myli 11:45 i 23:45 | Wysoki | Wpisać 23:45 albo 11:45 w urządzeniu z trybem 12h (070, 072) | Ukryte AM/PM przy polskim interfejsie | Tak: selektor wymusza format 24h | 422 = 23:45, 426 = 11:45; test widgetowy i na Androidzie |
| Q07 | Błąd HTTP 429 opisany jako brak pociągu | Wysoki | Wyszukać numer po wyczerpaniu limitu (076–082) | Wyjątek źródła zamieniany na pustą listę | Tak: błędy przekazywane do czytelnego komunikatu; nieaktualne odpowiedzi nie zastępują nowego zapytania | Kontrolowane 429/500/503, zachowanie pustej listy tylko dla prawdziwego braku wyników (457) |
| Q08 | Pociągi poprzedniej stacji pod nowym nagłówkiem | **Krytyczny** | Zmienić Kędzierzyn na Warszawę przy błędzie sieci (090) | Nagłówek zmieniany przed unieważnieniem danych poprzedniej stacji | Tak: tablica powiązana ze stacją, natychmiastowe przełączenie cache i odrzucanie spóźnionych odpowiedzi | 358: Opole offline, zero pociągów Kędzierzyna; test wyścigu kilku odpowiedzi |
| Q09 | Utrudnienia generują serię żądań osobno dla każdego pociągu | Wysoki | Otworzyć dwa duże utrudnienia (028–031) | Brak wspólnego indeksu i współdzielenia rozwiązywania odniesień | Tak: jeden indeks doby, współdzielone żądania i ograniczony czas cache | 102 i 550 pociągów z jednym pobranym indeksem; kontrola 96 referencji w dwóch przejściach = 1 HTTP |
| Q10 | Puste ulubione z tekstem przy krawędzi | Niski | Otworzyć pustą sekcję ulubionych (046) | Brak poziomych marginesów | Tak: 24 jednostki odstępu po bokach | 511: pusta lista tras, czytelny układ; kontrola małych szerokości |
| Q11 | Nagłówek prywatności wychodzi poza kartę przy 320 | Wysoki | Uprawnienia na szerokości 320 (116) | Tekst w wierszu bez ograniczenia dostępnej szerokości | Tak: elastyczny tekst z zawijaniem | 309: poprawny widok przy 320; testy szerokości |
| Q12 | Rozwinięta lista utrudnienia wraca z 40 do 20 po zmianie rozmiaru | Wysoki | Rozwinąć do 40, obrócić/zmienić szerokość (187a, 193, 195) | Licznik inicjalizowany wewnątrz przebudowy panelu | Tak: licznik należy do otwartego panelu | 345: zachowane 40 po zmianie szerokości, następnie 102/102; 348: 550/550 |
| Q13 | Bezimienny pociąg z `--:--` pomimo dostępnej godziny | Wysoki | Otworzyć późne odjazdy Kędzierzyna (173) | Brak trasy w zbiorczym rozkładzie i pierwszeństwo placeholdera nad rzeczywistym czasem | Tak: uzupełnienie brakującej trasy oraz wybór dostępnej godziny | 333-step-2: TLK36101 PLANTY 21:03, peron I, tor 5; test brakujących metadanych |
| Q14 | Utrudnienia znikają po ponownym wejściu offline | Wysoki | Pobrać listę, wyłączyć sieć, opuścić i otworzyć ekran (200) | Cache ograniczony do życia widoku | Tak: zapis w pamięci aplikacji i na urządzeniu, ostrzeżenie przy błędzie odświeżenia | 350, 352: dane i czas źródła zachowane, widoczne ostrzeżenie; test zapisu/odczytu cache |
| Q15 | Ponowienie tej samej trasy offline usuwa wyniki | Wysoki | Wyszukać, wyłączyć sieć, ponowić bez zmiany pól (205–207) | Czyszczenie wyników przed każdym zapytaniem | Tak: zachowanie wyników dla tej samej trasy z ostrzeżeniem; zmiana parametrów je unieważnia | 431: wyniki zachowane; 432: zamiana stacji czyści poprzednie wyniki; test regresji |
| Q16 | Błąd odświeżenia niewidoczny przy starych danych; utrata danych kursowania w szczegółach | Wysoki | Odświeżyć tablicę/szczegóły lub doładować dzień offline (204) | Ukrywanie błędu, nieprawidłowe zastępowanie zachowanego stanu | Tak: ostrzeżenie i zachowanie poprawnie przypisanych danych | 355: tablica z ostrzeżeniem; 445: szczegóły nadal +40 min i pełna trasa; testy awarii odświeżenia |
| Q17 | Opis prywatności nie wyjaśnia zapytania o okolice lokalizacji | Średni | Przeczytać opis, porównać działanie wyszukiwania GPS | Nieprecyzyjna informacja o przetwarzaniu lokalizacji | Tak: opis zgodny z wyszukiwaniem stacji przez usługi mapowe, zaktualizowana polityka | 309 i przegląd przepływu LocationService oraz dokumentacji |
| Q18 | Czerwony element błędu i uszkodzony formularz po zamknięciu wyboru stacji | Wysoki | Zamknąć panel przy zmianie rozmiaru/klawiatury, wejść do połączeń (360, 362) | `TextEditingController.dispose()` po zakończeniu Future panelu, ale przed końcem animacji zamykania | Tak: osobny StatefulWidget StationPicker posiada kontroler aż do usunięcia widoku | Test FAIL przed/PASS po; 404, 412–416, 491–493; 0 ErrorWidget po całym przebiegu i restarcie |

## Macierz wykonanych scenariuszy

PASS oznacza sprawdzony opisany przypadek. „Kontrolowany” oznacza przygotowaną odpowiedź źródła lub ustalony zegar; nie udaje aktualnych danych PLK.

| ID | Scenariusz | Wynik / dowód końcowy |
|---|---|---|
| S01 | Zimny start, pierwszy widok, stan GPS | PASS: 400–401, 508b; formularz i zachowana stacja dostępne podczas pobierania |
| S02 | Odmowa lokalizacji | PASS: 302–305 |
| S03 | Trwała odmowa i przejście do ustawień | PASS: 306–308 |
| S04 | Przyznana lokalizacja i najbliższa stacja | PASS: 490, testowe 18.206/50.344 → Kędzierzyn-Koźle |
| S05 | GPS wyłączony, włączenie i powrót | PASS: 310–313 |
| S06 | Ręczny wybór w czasie ustalania GPS | PASS: 317–324, 409–412 oraz kontrola spóźnionych odpowiedzi |
| S07 | Odjazdy/przyjazdy i przełączanie | PASS: 326–333 |
| S08 | Wcześniejsze odjazdy i separator | PASS: 327–330 oraz test tablicy |
| S09 | Kolejne porcje tablicy | PASS: 333 i 334 |
| S10 | Przejście przez północ | PASS: 335, 23:38 → Jutro → 03:57; kontrolowane 23:58 → 00:12 |
| S11 | Lokalne filtrowanie czterech nazw | PASS: 318–321 oraz 403, 411; bez żądania przy każdym znaku |
| S12 | Ostatnie, ulubione, długie nazwy, brak wyników | PASS: 322, 402–403, 410–411 |
| S13 | Kędzierzyn-Koźle → Gliwice | PASS: 429, 497 |
| S14 | Opole Główne → Kędzierzyn-Koźle | PASS: 435 |
| S15 | Wrocław Główny → Kraków Główny | PASS: 441 |
| S16 | Przyszły rzeczywisty odjazd przy wcześniejszej godzinie planowej | PASS: 441, IC8304; również test graniczny |
| S17 | Zamiana stacji | PASS: 432; poprawnie unieważnione wyniki |
| S18 | Data, 24h, Teraz | PASS: 422, 426, 427, 500–503 |
| S19 | Dodanie, użycie, usunięcie ulubionej trasy, bez duplikatów | PASS: 428, 495–497, 511; kontrola modelu ulubionych |
| S20 | Ulubione po restarcie | PASS: 508b–510, jedna stacja i jedna trasa |
| S21 | Pociąg 5410 | PASS: 451, jeden właściwy kurs, również offline |
| S22 | Pociąg IC 5410 | PASS: 453, ten sam kurs |
| S23 | Nazwa HEWELIUSZ | PASS: 455, cztery odrębne numery i relacje |
| S24 | Nieistniejący numer | PASS: 457, pusty wynik bez fikcyjnych kursów |
| S25 | Krótka trasa przed odjazdem, jutro | PASS: 336–337, R94904, 7 stacji |
| S26 | Długa opóźniona trasa w ruchu | PASS: 442, MALCZEWSKI, 26 stacji, dane kursowania i pozycja szacowana |
| S27 | Kurs zakończony | PASS: 476, IC66100, 7 stacji, poprzednie zwinięte, brak aktywnej animacji |
| S28 | Rozwinięcie poprzednich, ciągła oś i pojedynczy aktywny odcinek | PASS: 443–444; kontrolowane pozycje potwierdzone, szacowane, brak operations, powtórzona stacja |
| S29 | Wszystkie pociągi utrudnienia i licznik | PASS: rzeczywiste 102/102, 550/550 i 16/16; kontrolowane 96/96 |
| S30 | Godzina dodania utrudnienia | PASS: test wartości 13:42 i braku czasu; 480 potwierdza brak tego pola w bieżącym źródle |
| S31 | Status sieci bez JSON | PASS: 465 |
| S32 | Prosty status usługi i źródła | PASS: 463 |
| S33 | Informacje o aplikacji i Back | PASS: 461–462, autorzy, beta6/build7, źródło i brak oficjalnego powiązania |
| S34 | Wszystkie główne zakładki w jasnym i ciemnym motywie | PASS: 400–480, uzupełnione zdjęcia 483–484 i 511–514 |
| S35 | 320/360/384/411 i obrót | PASS: 309, 345, 404, 446–447; testy całych ekranów bez overflow |
| S36 | Pięć szybkich obiegów zakładek | PASS: 487, 25 kliknięć, 0 żądań API w tym przedziale |
| S37 | Back z tablicy, wyników, szczegółów i ustawień | PASS: 338, 448, 462, 464, 477, 481–482 i 489 |
| S38 | Offline: tablica, nowa stacja, połączenia, utrudnienia, szczegóły | PASS: 350–358, 431–432, 445, 451–455 |
| S39 | GPRS/GSM, możliwość opuszczenia ekranu podczas pobierania | PASS: 488–489; przywrócono pełną szybkość i brak sztucznego opóźnienia |
| S40 | HTTP 429/500/503 | PASS kontrolowany: 429 bez ponowienia i z blokadą dalszych prób; 500/503 najwyżej trzy próby; czytelny UI |
| S41 | Cache, współdzielenie równoległych żądań, słowniki | PASS: test deduplikacji, indeksu 96 referencji i pamięci; logi rzeczywistego użytkowania |
| S42 | Regresja pełnego TrainDetailsScreen | PASS kontrolowany: 16 rozkładowych / 9 przestawionych operacyjnych, wskazanie 11, cztery szerokości i krótkie godziny |
| S43 | Życie kontrolera zamykanego panelu | PASS: test trzykrotnego otwarcia z przebudową podczas zamykania oraz ponowny test natywny |
| S44 | Zakres przebudowy animacji | PASS: 180 przebudów AnimatedBuilder w 3 s, 0 Scaffold i 0 TrainDetailsScreen |

## API, cache i logi

Rejestr obejmuje **171 prób żądań API kolejowego**: 105 w audycie początkowym i 66 w powtórzeniach po poprawkach, z restartami i wymuszonym offline. Nie każda próba dotarła do serwera. Dodatkowe dwa diagnostyczne odczyty źródła wykonano poza interfejsem aplikacji. Zapytania usług mapowych GPS nie są wliczone do 171.

| Grupa endpointów | Próby w całym audycie |
|---|---:|
| Pojedyncza trasa rozkładu | 65 |
| Rozkłady zbiorcze | 32 |
| Kursowanie zbiorcze | 23 |
| Kursowanie pojedynczego pociągu | 12 |
| Wersja danych | 9 |
| Utrudnienia | 8 |
| Cztery słowniki | 20 łącznie, po 5 każdego |
| Statystyki | 2 |

Przed poprawką odnotowano 64 żądania pojedynczej trasy; po poprawkach tylko jedno, potrzebne do uzupełnienia brakującego rekordu tablicy. Rozwinięcie dużych utrudnień korzystało ze wspólnego indeksu doby. Słowniki ładowano podczas inicjalizacji aplikacji, a nie przy każdej zmianie zakładki. W dokładnym przedziale 25 szybkich kliknięć końcowego testu wystąpiło **0 żądań**.

Kontrolowane próby HTTP potwierdziły: 429 = jedna próba i 60-sekundowa przerwa przed kolejnymi; 500 i 503 = maksymalnie trzy próby; dwa równoległe identyczne zapytania = jedno faktyczne żądanie. Wyniki kontrolowanych adapterów nie zostały dodane do liczby rzeczywistych żądań API.

Logcat zbierano przez całą pracę. W procesach zwykłej aplikacji znaleziono 16 wpisów `SocketException`, zgodnych z próbami offline: 7 przed poprawkami, 5 w pierwszej poprawionej instalacji i 4 w końcowym APK. Zostały obsłużone, a w poprawionej wersji użytkownik widział zachowane dane i ostrzeżenie. Nie należy nazywać całego surowego logu CLEAN. Nie znaleziono w nim `FATAL EXCEPTION`, `RangeError`, `FlutterError`, `RenderFlex`, `overflowed`, `setState after dispose`, błędu zdezaktywowanego widoku, `Null check operator`, `LateInitializationError`, `FormatException` ani `Bad state` pochodzących z testowanych procesów aplikacji.

**Sam logcat nie wystarczył do wykrycia Q18.** Przed ostateczną poprawką screenshot oraz Dart VM potwierdziły trzy ErrorWidget, w tym użycie zwolnionego kontrolera i wtórny błąd drzewa renderowania. Test regresji potwierdził przyczynę. Po poprawce, po wszystkich interakcjach i po końcowym restarcie: **0 ErrorWidget**. Sztucznie wywołane błędy testów negatywnych izolowanej aplikacji QA nie są błędami zwykłej aplikacji.

Pomiar wydajności dotyczył debug w emulatorze podczas automatyzacji. W próbce animacji 3 s: 180 przebudów AnimatedBuilder, zero przebudów Scaffold i TrainDetailsScreen. Migawka `gfxinfo`: 335 klatek, P90 40 ms, P95 57 ms, P99 109 ms, 50,15% klatek oznaczonych jako janky według aktualnej metryki Androida (24,78% według legacy). To nie uzasadnia deklaracji płynnych 60 FPS na telefonie; potrzebny byłby osobny pomiar wersji release na urządzeniu. W testowanych interakcjach nie wystąpiło zawieszenie uniemożliwiające nawigację.

## Godzina dodania, RangeError i granice weryfikacji

Utrudnienie pokazuje **„Dodano o HH:mm”**, jeśli odpowiedź pojedynczego komunikatu zawiera poprawny czas utworzenia. Ta sama informacja jest na liście i w szczegółach. Czas aktualizacji całego zestawu danych jest osobną wartością. Obecnie sprawdzone odpowiedzi PLK nie zawierały czasu utworzenia pojedynczego komunikatu, więc UI uczciwie informuje o jego braku. Nie przypisuje utrudnieniu godziny odświeżenia. Oba warianty przechodzą testy widgetowe i na Androidzie.

Historycznej linii zgłoszonego `RangeError (start): ... 0..8: 11` nie można rzetelnie wskazać: dostarczony stan kodu zawierał już wcześniejsze zmiany, a stosu starego wyjątku nie było. Nie przypisuję awarii do zgadywanej linii. Potwierdzony wcześniejszy problem mapowania dotyczył nadpisywania powtórnych wystąpień stacji przez mapę opartą wyłącznie na stationId. Obecny resolver dopasowuje dane rozkładowe i operacyjne przez stabilne identyfikatory oraz numery kolejności. Pozycja i renderowanie dotyczą tej samej listy rozkładowej. Jeśli pozycja jest niejednoznaczna, wyświetlana jest pełna trasa. Regresja całego ekranu z 16/9 stacjami i wskazaniem 11 przechodzi bez RangeError, FlutterError i czerwonego ekranu.

Formatter peronu jest wspólny; 1–10 daje I–X, tor pozostaje arabski. Wspólne kolory: Os/R/RP/PR/KW/ŁKA czerwony; IR/KM zielony; TLK/IC/EC/EN pomarańczowy; EIC jasnoniebieski; EIP ciemnoniebieski; SKM/KD/KMŁ żółty; KŚ niebieski; nieznane symbole neutralne. Opóźnione godziny są czerwone. Wyniki połączeń zachowują zwarty układ tablicy, a zapisane trasy są dostępne pod formularzem i w Ulubionych.

Bieżące dane stacji udostępniały po północy pierwszy pokazany kurs o 03:57, dlatego nie wymyślano rzeczywistego kursu 00:xx. Taki dokładny przypadek sprawdzono na danych kontrolowanych. Dwa komunikaty utrudnień nie miały opisu w źródle. GPS ostatecznie wybrał poprawną stację, ale trzy serwery Overpass zwracały timeout; odpowiedź pochodziła z mechanizmu awaryjnego. Oczekiwanie nie blokowało reszty UI. To ograniczenia zaobserwowanych danych i usług zewnętrznych, nie otwarte potwierdzone błędy Q01–Q18.

## Powtarzalność, artefakty i incydent testowy

Końcowe wyniki zapisano w katalogu audytu: `analyze-picker-final.log`, `unit-picker-final.log`, `integration-picker-fixed.log`, `build-picker-final.log`, `format-clean-project.log`, `api-requests-final.json`, `api-endpoints-summary.json`, `all-app-error-patterns.log`, `pulse-summary.json` i `error-widgets-restart-final.json`.

Pełne `dart format .` w roboczym katalogu zatrzymało się na zbyt długiej ścieżce wygenerowanych kopii build w Windows. Wszystkie źródła sformatowano, a dokładne `dart format .` wykonano w czystej kopii lib/test/integration_test z konfiguracją projektu: 55 plików, 0 zmian. Nie przedstawiam nieudanego przejścia przez wygenerowane katalogi jako udanego. Analiza, 121 testów i budowa debug dotyczą właściwego projektu. 46 testów silnika Androida wykonano z tymi samymi źródłami w izolowanej kopii QA.

Podczas wcześniejszego sprzątania testów Flutter usunął z emulatora zwykły pakiet aplikacji, ponieważ kopia testowa miała jeszcze wspólną przestrzeń nazw aktywności. Użytkownik został poinformowany. Poprawiono izolację pakietu, przestrzeni nazw i MainActivity w kopii QA. Zwykłą aplikację ponownie zainstalowano, stan testowy odtworzono, a późniejsza aktualizacja APK i restart zachowały odtworzone ulubione. Nie twierdzę, że wcześniejsze dane przetrwały incydent. Nie dotyczył on aplikacji pobranych przez użytkowników.

Automatyczna kontrola odrzuciła próbę zapisania kopii preferencji emulatora w projekcie ze względu na możliwość zawarcia danych prywatnych. Kopia nie powstała; nie ponawiano tego odczytu. Kontynuowano bezpiecznie w odrębnej aplikacji QA.

[APK testowy beta 6](C:/Users/Maciej/Desktop/Trainly/artifacts/kolejka-1.0.0-beta.6-debug.apk)

SHA-256 APK: `48C21A5A28618D00E358EACB140BFC85F524F3A34A09A649FA7254137F2CF052`.

Certyfikat SHA-256: `fa249892a4174dd9d3dbe2d36a9d599e5fd97b3336fbc52126e00dd56b3e1b23`.

Ten raport dostarcza sprawdzony lokalny APK debug i poprawki źródeł. Nie oznacza publikacji nowego wydania ani aktualizacji strony GitHub Pages.
