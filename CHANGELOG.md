# Historia zmian

## 2.0.0-beta.1 — Beta 2.0 — 2026-09-08

- Wydanie obejmuje wszystkie poprawki interfejsu i stabilności opisane w Beta 4–6, w tym połączenia na kolejne dni, nowy wybór stacji, zieloną oś trasy oraz godziny dodania utrudnień, gdy źródło je udostępnia.
- Publiczna dystrybucja aplikacji i strona pobierania są oddzielone od prywatnego repozytorium kodu źródłowego.
- Instalator Androida jest podpisany dotychczasowym kluczem wydawniczym i zawiera zaciemniony kod produkcyjny.
- Naprawiono odczyt uszkodzonego cache i migrację dużych starych indeksów na Androidzie bez utraty ulubionych. Ograniczono rozmiar cache w pamięci i ustawieniach.
- Tablica łączy rozkład z operacjami, zachowuje cały dzień i różne kursy tego samego numeru. Status sieci pokazuje udziały rozłącznych kategorii, sumujące się do 100,0%.
- Dodano nowy jasny motyw, opcjonalny Liquid Glass z ograniczeniem efektów na wolniejszych urządzeniach i panele wyboru daty oraz godziny w stylu iOS.
- Przebudowano szczegóły pociągu i zieloną oś trasy. Wyszukiwarka stacji dopasowuje początek nazwy, a utrudnienia rozwiązują opisy ze słownika źródła.

## 1.0.0-beta.6 — 2026-09-07

- Gwiazdka zapisywania trasy znajduje się przy wybranych stacjach. Połączenia można dociągać na kolejne dni i rozwijać po osiem; dni rozdziela data między liniami.
- Oś przebiegu pociągu jest ciągła i zielona, z wyraźnymi punktami stacji. Pulsowanie odświeża wyłącznie rysunek osi, również przy pozycji szacowanej.
- Pobieranie kolejnych dni nie przypisuje dzisiejszych opóźnień do jutrzejszych pociągów. Tablica nie pomija dnia z powodu pojedynczego nocnego kursu i pozwala przejść przez dni bez nowych wyników.
- Wyniki połączeń mają poziomą oś podróży: duże godziny odjazdu i przyjazdu, czas przejazdu pomiędzy nimi oraz status przy numerze pociągu. Trasa i termin są zebrane w jednym nagłówku z przyciskiem „Zmień”.
- Dzień stacji zapisany w rozkładzie koryguje planowe godziny nocnego kursu oznaczone przez źródło datą wyjazdu; usuwa to fałszywe opóźnienie o całą dobę.
- Wybór stacji ma większe pola dotykowe, skrót do lokalizacji, uporządkowane ulubione i ostatnie stacje oraz przypięte wyszukiwanie nad klawiaturą. Pełne nazwy i trafienia od początku nazwy mają pierwszeństwo w wynikach.
- Zmiana stacji natychmiast przełącza powiązaną z nią tablicę; błąd sieci nie pozostawia pociągów poprzedniej stacji pod nowym nagłówkiem.
- Poprawiono wybór godziny w polskim trybie 24-godzinnym, oznaczenie ujemnego opóźnienia i kolejność połączeń uwzględniającą rzeczywisty odjazd.
- Trwała odmowa GPS prowadzi do ustawień Androida, a powrót z ustawień aktualizuje status. Poprawiono układ uprawnień przy 320 dp oraz opis korzystania z lokalizacji.
- Utrudnienia zachowują rozwiniętą listę po zmianie rozmiaru ekranu. Duże listy korzystają ze wspólnego rozkładu zamiast osobnego zapytania o każdy pociąg.
- Utrudnienia można ponownie otworzyć z pamięci podręcznej. Nieudane odświeżenie tej samej trasy, tablicy lub szczegółów pociągu zachowuje dostępne dane i pokazuje ostrzeżenie o ich aktualności.
- Uzupełniane są brakujące metadane tablicy. Gdy brakuje godziny planowej, widoczna pozostaje dostępna godzina rzeczywista.
- Błędy źródła, w tym limit zapytań, mają czytelne komunikaty. Poprawiono oznaczenia kategorii pociągów oraz marginesy pustych ulubionych.
- Poprawiono czas zwalniania pola wyszukiwania po zamknięciu wyboru stacji, co usuwa błąd formularza przy zmianie rozmiaru ekranu.
- Dodano testy regresji oraz scenariusze pasażera uruchamiane na emulatorze Androida.

## 1.0.0-beta.5 — 2026-09-07

- Tablica dociąga rozkład następnego dnia wyłącznie po wybraniu „Pokaż więcej”, zachowuje dane na ekranie i rozdziela dni separatorem „Jutro”.
- Wybór stacji działa w dolnym panelu z lokalnym wyszukiwaniem, obsługą polskich znaków, ostatnio używanymi i ulubionymi stacjami.
- Szczegóły utrudnienia pokazują wszystkie dotknięte pociągi porcjami po 20, z licznikiem postępu; jeśli źródło podaje czas utworzenia komunikatu, widoczna jest godzina „Dodano o”.
- Stan pociągu jest oznaczony bezpośrednio na osi trasy: pulsuje tylko bieżący odcinek albo punkt stacji, także w trybie szacowanym.
- Odpowiedzi tablicy dla wcześniej wybranej stacji nie zastępują już aktualnych danych.
- 102 testy, w tym przejście przez północ, 96 pociągów w utrudnieniu i oznaczenie aktywnego odcinka trasy.
## 1.0.0-beta.4 — 2026-09-07

- Połączenia są pierwszą zakładką i ekranem startowym aplikacji.
- Wyniki mają układ tablicy z wyraźnymi godzinami, oznaczeniami pociągów i cienkimi separatorami.
- Wcześniejsze połączenia rozwijają się nad późniejszymi; kolejne późniejsze wyniki można dodawać na dole listy.
- Po wyszukaniu znika sekcja ulubionych tras, a formularz zmienia się w zwarty nagłówek z możliwością edycji.
- Oddzielne ikony czoła pociągu regionalnego i opływowego pociągu dalekobieżnego są wspólne dla wyników i tablic stacyjnych.
- Lista utrudnień pokazuje datę i godzinę danych przekazaną przez źródło. Szczegóły wyjaśniają brak godziny dodania pojedynczego komunikatu w API.
- Wyszukiwarka wyjaśnia przekroczenie limitu zapytań i brak połączenia z internetem.

## 1.0.0-beta.3 — 2026-09-07

- Tablice odjazdów i przyjazdów mają zwarty układ wzorowany na tablicach kolejowych: godzina, opóźnienie, pociąg, kierunek i peron są widoczne bez otwierania szczegółów.
- Wcześniejsze kursy można rozwinąć osobno, a kolejne późniejsze kursy są dokładane po osiem pozycji.
- Ekran połączeń otrzymał spójny nagłówek, zamknięty formularz A/B, czytelny wybór daty i godziny oraz wyraźną akcję wyszukiwania.
- Układ tablic i wyszukiwarki został sprawdzony w jasnym i ciemnym motywie dla szerokości 320–411 px.
- 94 testy, w tym nowa regresja rozwijania wcześniejszych i kolejnych odjazdów oraz przyjazdów.

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
