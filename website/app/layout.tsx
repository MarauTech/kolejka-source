import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = {title:'Kolejka BETA — pobierz aplikację na Androida',description:'Rozkład jazdy, połączenia, tablice stacyjne i opóźnienia. Pobierz aplikację Kolejka BETA na Androida.',icons:{icon:process.env.NODE_ENV === 'production' ? '/kolejka/kolejka.png' : '/kolejka.png'}};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="pl"><body>{children}</body></html>;}
