# Strona pobierania Kolejki

Hosting: **GitHub Pages**, https://marautech.github.io/kolejka/.

Wymagane Node 22 (zweryfikowane 22.23.2) i npm.

```sh
npm ci
npm run dev
npm run lint
npm run build
```

Podgląd: http://localhost:3000/kolejka/. Strona jest statyczna; publiczny katalog to dist/client. Workflow .github/workflows/pages.yml buduje i publikuje stronę po zmianach w website na gałęzi main. Można go także uruchomić ręcznie przez Actions.

Nie umieszczaj tutaj APK — pliki wydań pozostają w GitHub Releases. Przy nowym wydaniu zmień wersję i adres APK w app/page.tsx. Klucz podpisu Androida nie jest potrzebny do budowy strony.
