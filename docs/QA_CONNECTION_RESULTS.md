# Przebudowa wyników połączeń — 7 września 2026

Wersja lokalna: 1.0.0-beta.6+7.

## Zmiany

- Wspólny nagłówek trasy i terminu z przyciskiem „Zmień”.
- Pozioma oś podróży: duże godziny, czas przejazdu pomiędzy nimi, status obok oznaczenia pociągu i perony pod właściwymi końcami podróży.
- Usunięte powtarzanie celu podróży w każdym wierszu. Przesiadki nadal pokazują miejsce zmiany i oba pociągi.
- Większa czcionka przenosi czas podróży pod godziny i zachowuje ich wyrównanie. Puste wyniki oraz brak późniejszych kursów mają czytelne objaśnienie.

## Błąd wykryty na prawdziwych danych

W wynikach Kędzierzyn-Koźle → Opole Główne kurs URSA 37010 miał przyjazd 00:01 i fałszywe opóźnienie +1440 min. Odpowiedź operacyjna zawierała planowy przyjazd z datą 7 września, rzeczywisty z 8 września, a rozkład jawnie wskazywał `arrivalDay: 1` względem dnia kursowania 7 września.

Wspólny parser planowanych godzin korzysta teraz z jawnego dnia rozkładu, kiedy operacyjny znacznik ma datę rozpoczęcia kursu. Nie przesuwa godzin rzeczywistych ani już poprawnie datowanych przystanków. Testy zachowują także rzeczywiste opóźnienie 1440 minut i opóźnienie podane wprost przez źródło.

## Weryfikacja

- Formatowanie i analiza kodu: bez problemów.
- Wszystkie testy aplikacji: **134/134**.
- Pełny zestaw scenariuszy Androida po zmianie układu: **57/57**.
- Po dodatkowej poprawce daty: **11/11** scenariuszy połączeń na Androidzie, w tym nocny przyjazd, przesiadki, rozwijanie list i powiększona czcionka.
- Szerokości 320, 360, 384 i 411 dp; oba motywy; dodatkowo 320 dp z czcionką 160%.
- Zbudowano i zainstalowano finalny APK jako aktualizację. Testy Androida używają oddzielnego pakietu `com.trainly.qa`.
- W działającej aplikacji sprawdzono wyszukanie trasy do Opola, nowy nagłówek, opóźnienia, przejście do szczegółów i otwarcie edycji. Wizualny podgląd rzeczywistych wyników zapisano w ciemnym motywie.

Podgląd: `artifacts/connections-results-dark.png`.
Instalator: `artifacts/kolejka-1.0.0-beta.6-connections-debug.apk`.
Logi i suma kontrolna: `artifacts/connections-*.log`, `artifacts/connections-verification.json`.

Przy kompilacji nadal występują ostrzeżenia narzędzi o przyszłej migracji Kotlin i wersji SDK XML; nie blokują bieżącej kompilacji. Brak miejsca na dysku rozwiązano przez usunięcie zweryfikowanych, starych kopii wygenerowanych katalogów kompilacji.

## Uzupełnienie: gwiazdka, kolejne dni i zielona oś

- Gwiazdka została przeniesiona z paska tytułu do panelu stacji, przy początku trasy. Jest dostępna również w zwiniętym podsumowaniu.
- Wyniki pobierają kolejne dni na żądanie, zachowują dotychczasowe wiersze i stan rozwinięcia oraz pokazują po osiem nowych kursów. Granice dni oznacza data między separatorami. Dni bez nowych wyników nie kończą przeglądania; błąd pozwala ponowić ten sam dzień. Odpowiedź po zmianie trasy jest odrzucana.
- Dopasowanie bieżącego kursowania uwzględnia dzień kursowania. Przyszłe dni korzystają z rozkładu, bez dodatkowego pobierania dzisiejszych opóźnień.
- Tablica śledzi faktycznie pobrane dni, zamiast wyznaczać kolejny dzień na podstawie ostatniego nocnego pociągu. Pozwala również przejść przez pusty dzień.
- Oś trasy ma spójną grubość, zieloną paletę i połączone odcinki. Pozycja szacowana również jest zielona i zachowuje opis tekstowy. Animacja odmalowuje wyłącznie oś.

Weryfikacja: **141/141 testów**, **65/65 scenariuszy na Androidzie**, analiza bez uwag, APK zbudowany i zainstalowany jako aktualizacja. Test pikseli potwierdza ciągłość zielonej linii między wierszami o różnej wysokości w obu motywach. Sprawdzono też powiększoną czcionkę 160% przy 320 dp.

Rzeczywiste źródło zwróciło 42 trasy łączące Kędzierzyn-Koźle i Opole Główne na 8 września 2026. Odczyt wykonano bezpośrednio, ponieważ widok emulatora zmieniał się niezależnie między krokami kontroli. Działający podgląd szczegółów CARPATII potwierdził nową zieloną oś; zapisano go w `artifacts/route-axis-green.png`.

Aktualny instalator: `artifacts/kolejka-1.0.0-beta.6-next-days-debug.apk`.
Wyniki i suma kontrolna: `artifacts/followup-verification.json`.
