# Strona pobierania Kolejki

Wymagane Node 22 (zweryfikowane 22.23.2) i npm. Nowszy Node 24 w lokalnym Windows powodował błąd zamykania procesu podczas eksportu.

```sh
npm ci
npm run dev
npm run lint
npm run build
```

Strona jest statyczna; gotowy publiczny katalog to dist/client. Publikacja korzysta z Sites i identyfikatora w .openai/hosting.json. Nie umieszczaj tutaj APK — pliki wydań są przechowywane w GitHub Releases.

Przy nowym wydaniu zaktualizuj numer wersji i adres APK w app/page.tsx. Klucz podpisu Androida nie jest potrzebny do budowy strony.
