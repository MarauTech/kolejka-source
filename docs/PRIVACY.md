# Dane i prywatność w Kolejce BETA

Stan opisu: 7 września 2026, wersja 1.0.0-beta.2. Opis dotyczy obecnego kodu aplikacji.

## Dane przechowywane lokalnie

Ulubione stacje i trasy, wybrany motyw, ostatnia stacja oraz pamięć podręczna słowników są przechowywane na urządzeniu przez SharedPreferences. Aplikacja nie wymaga konta i nie ma własnego mechanizmu synchronizacji ulubionych z serwerem. Ustawienia kopii zapasowej Androida mogą działać niezależnie od aplikacji.

## Połączenia sieciowe

Zapytania o rozkład i kursowanie trafiają do proxy Kolejki działającego w Cloudflare, a następnie do API PKP PLK. Zawierają m.in. identyfikatory stacji, kursów i wybraną datę. Usługi sieciowe otrzymują także dane niezbędne do połączenia, w tym adres IP; ich własne zasady przetwarzania są niezależne od aplikacji.

## Lokalizacja

GPS jest opcjonalny. Po udzieleniu uprawnienia lokalizacja służy do znalezienia najbliższej stacji. Obecna implementacja przesyła współrzędne w zapytaniach do publicznych usług Overpass (OpenStreetMap) i może korzystać z Nominatim przy dopasowaniu nazw. Nie opisujemy więc GPS jako funkcji działającej wyłącznie lokalnie. Możesz odmówić dostępu lub cofnąć go w ustawieniach Androida i wybierać stacje ręcznie.

## Zgłoszenia

Publiczne zgłoszenia na GitHubie są widoczne dla innych. Nie dodawaj haseł, kluczy ani dokładnej lokalizacji. Ewentualne zrzuty ekranu i logi przejrzyj przed wysłaniem.
