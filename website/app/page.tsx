'use client';
import Image from 'next/image';
import Link from 'next/link';
import { Download, ArrowUpRight, TrainFront, MapPin, Clock3 } from 'lucide-react';
import { buttonVariants } from '@/components/ui/button';
const repo = 'https://github.com/MarauTech/kolejka';
const apk = `${repo}/releases/download/v1.0.0-beta.1/kolejka-1.0.0-beta.1.apk`;
export default function Home() {
  return <main>
    <nav className="nav shell" aria-label="Nawigacja"><Link className="brand" href="/"><Image unoptimized src="/kolejka.png" width="42" height="42" alt=""/>Kolejka <span className="beta">BETA</span></Link><a href={repo}>GitHub <ArrowUpRight size={16}/></a></nav>
    <section className="hero shell">
      <div className="intro"><p className="eyebrow">TWÓJ PODRĘCZNY ROZKŁAD JAZDY</p><h1>Kolej pod ręką.<br/><span>Dokądkolwiek jedziesz.</span></h1><p className="lead">Połączenia, tablice stacyjne i opóźnienia w jednej aplikacji. Pobierz Kolejkę na Androida i sprawdź swoją następną podróż.</p>
      <a className={`${buttonVariants({size:'lg'})} download`} href={apk}><Download size={21}/> Pobierz na Androida</a><p className="release-meta">1.0.0-beta.1 · plik APK · bez konta</p><a className="text-link" href="#instalacja">Jak zainstalować aplikację? <span>↓</span></a></div>
      <aside className="release-panel" aria-label="Informacje o wydaniu"><div className="panel-top"><span>KOLEJKA / ANDROID</span><span className="status-dot">WERSJA TESTOWA</span></div><Image unoptimized className="app-icon" src="/kolejka.png" width="160" height="160" alt="Logo aplikacji Kolejka"/><div className="panel-title">Następny przystanek:<br/><strong>Twoja podróż.</strong></div><div className="panel-bottom"><span>WYDANIE <b>01 / BETA</b></span><a href={`${repo}/releases/tag/v1.0.0-beta.1`}>Co nowego <ArrowUpRight size={17}/></a></div></aside>
    </section>
    <section className="features shell" aria-label="Możliwości aplikacji">{[
      [TrainFront,'Znajdź połączenie','Wybierz stacje A i B, sprawdź godziny i zapisz ulubioną trasę.'],
      [Clock3,'Sprawdź swój pociąg','Zobacz opóźnienia, pełną trasę, perony i tory, gdy dane są dostępne.'],
      [MapPin,'Bądź na właściwej stacji','Otwórz tablicę odjazdów i przyjazdów. Opcjonalny GPS pomoże znaleźć najbliższą stację.']
    ].map(([Icon,title,body])=>{const I=Icon as typeof TrainFront;return <article key={String(title)}><I size={25}/><h2>{String(title)}</h2><p>{String(body)}</p></article>})}</section>
    <section className="install shell" id="instalacja"><div><p className="eyebrow">ZACZNIJ KORZYSTAĆ</p><h2>Trzy kroki.<br/>I możesz ruszać.</h2><p>Aplikacja jest w wersji BETA. Możesz napotkać błędy; zgłoszenia pomagają ją poprawiać.</p><a className="text-link" href={`${repo}/issues/new/choose`}>Zgłoś problem <ArrowUpRight size={16}/></a></div><ol><li><span>01</span><div><h3>Pobierz plik APK</h3><p>Otwórz tę stronę na telefonie z Androidem i wybierz „Pobierz na Androida”.</p></div></li><li><span>02</span><div><h3>Zainstaluj Kolejkę</h3><p>Otwórz pobrany plik. Jeśli Android poprosi, zezwól tej przeglądarce na instalację aplikacji. Po instalacji możesz cofnąć to uprawnienie.</p></div></li><li><span>03</span><div><h3>Wybierz stację lub trasę</h3><p>Korzystaj bez zakładania konta. GPS jest opcjonalny — stację możesz wybrać ręcznie.</p></div></li></ol></section>
    <footer className="shell"><div><strong>Kolejka</strong><p>Niezależna aplikacja. Dane rozkładowe i o kursowaniu pochodzą z API PKP PLK. Dostępność i aktualność informacji zależą od źródła danych.</p></div><div className="footer-links"><a href={`${repo}/blob/main/docs/PRIVACY.md`}>Prywatność</a><a href={`${repo}/releases/tag/v1.0.0-beta.1`}>Wydanie i suma kontrolna</a><a href={repo}>Kod projektu</a></div></footer>
  </main>;
}
