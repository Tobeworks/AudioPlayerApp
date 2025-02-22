# Webapp Audioplayer und Hintergrund-Slideshow


Diese Dokumentation beschreibt eine moderne Web-Anwendung, die mit Vue.js 3, Vite, Tailwind CSS und Pinia entwickelt wurde. Die Anwendung umfasst eine Hintergrund-Slideshow und einen interaktiven Audioplayer mit Funktionen wie Wiedergabe, Shuffle, Repeat und einer Playlist. Sie ist für Desktop- und Mobilgeräte optimiert und verwendet eine API zur Datenbeschaffung.

---

## Projektstruktur und Konfiguration

### 1. `tailwind.config.js`
- **Zweck:** Konfiguriert Tailwind CSS für das Projekt.
- **Details:** In der bereitgestellten Datei fehlt der Inhalt, aber typischerweise definiert sie Themes, Farben, Schriftarten und Plugins, die mit Tailwind CSS verwendet werden.
- **Verwendung:** Wird in `vite.config.js` referenziert.

### 2. `vite.config.js`
- **Zweck:** Hauptkonfigurationsdatei für Vite, den Build-Tool und Dev-Server.
- **Inhalt:**
  - **Plugins:**
    - `vue()`: Ermöglicht die Verarbeitung von Vue.js-Dateien.
    - `vueDevTools()`: Integriert Vue DevTools für Entwicklungszwecke.
    - `tailwindcss()`: Bindet Tailwind CSS ein mit Verweis auf `tailwind.config.js`.
  - **Alias:** Definiert `@` als Verknüpfung zum `src`-Verzeichnis für einfachere Importe.
- **Bemerkung:** Optimiert für schnelles Hot Module Replacement (HMR) und Produktions-Builds.

### 3. `eslint.config.js`
- **Zweck:** Konfiguriert ESLint für Code-Linting.
- **Inhalt:**
  - **Dateien zum Linten:** Alle `.js`, `.mjs`, `.jsx` und `.vue` Dateien.
  - **Ignorierte Verzeichnisse:** `dist`, `dist-ssr`, `coverage`.
  - **Regeln:** Nutzt empfohlene Konfigurationen von `@eslint/js` und `eslint-plugin-vue` (essential).
- **Bemerkung:** Sorgt für konsistenten Code-Stil und Fehlervermeidung.

---

## Hauptkomponenten und Funktionalität

### 4. `src/App.vue`
- **Zweck:** Root-Komponente der Anwendung.
- **Struktur:**
  - **Imports:** 
    - CSS-Datei (`main.css`) für globale Stile.
    - `RouterLink` und `RouterView` für Routing.
    - `BackgroundSlideshow` als Hintergrund-Komponente.
  - **Template:** 
    - Rendert die `BackgroundSlideshow`-Komponente und den `RouterView` für dynamische Inhalte.
  - **Styling:** Setzt `body` auf volle Breite/Höhe ohne Überlauf.
- **Funktion:** Dient als Container für die gesamte Anwendung.

### 5. `src/main.js`
- **Zweck:** Einstiegspunkt der Anwendung.
- **Inhalt:**
  - Initialisiert Vue-App mit `createApp`.
  - Integriert Pinia (State-Management) und Vue-Router.
  - Mountet die App an `#app`.
- **Bemerkung:** Lädt globale CSS-Dateien und Komponenten.

### 6. `src/stores/counter.js`
- **Zweck:** Beispiel-Store mit Pinia.
- **Funktion:** 
  - Definiert einen `counter`-Store mit `count`, `doubleCount` (computed) und `increment`-Methode.
- **Bemerkung:** Dient als Vorlage für State-Management, wird hier nicht direkt im Audioplayer genutzt.

---

## Hintergrund-Slideshow

### 7. `src/components/BackgroundSlideshow.vue`
- **Zweck:** Zeigt eine Slideshow von Bildern als Hintergrund an.
- **Funktionalität:**
  - **Technologien:** Nutzt Swiper.js für Slideshow mit Fade-Effekt und Autoplay.
  - **API-Integration:** Lädt Bilder von einer API (lokal oder Produktion).
  - **Fallback:** Bei Fehlern werden statische Bilder geladen.
  - **Zustände:** `isLoading`, `error`, `images`.
  - **Events:** Loggt Swiper-Initialisierung und Slide-Wechsel.
- **Styling:** 
  - Vollbild-Positionierung mit `fixed`.
  - Fade-Animationen und Lade-Indikator.
- **Bemerkung:** Läuft im Hintergrund mit minimaler Interaktion.

---

## Audioplayer

### 8. `src/components/Audioplayer/AudioPlayer.vue`
- **Zweck:** Hauptkomponente des Audioplayers.
- **Funktionalität:**
  - **Zustände:** Verwaltet Wiedergabe, Lautstärke, Position (Desktop), Playlist-Anzeige, etc.
  - **API-Integration:** Lädt Tracks von einer API.
  - **Interaktionen:**
    - Wiedergabe/Pause, Skip, Shuffle, Repeat.
    - Ziehen des Players auf Desktop (`startDrag`, `onDrag`, `endDrag`).
    - Speichern/Laden des Zustands in `localStorage`.
  - **Responsivität:** Unterschiedliches Verhalten auf Mobile/Desktop.
  - **Audio-Element:** Unsichtbares `<audio>`-Tag mit Event-Listenern.
- **Unterkomponenten:**
  - `PlayerExpanded`: Vollständige UI bei geöffnetem Player.
  - `PlayerMinimal`: Kompakte UI bei eingeklapptem Player.
  - `PlaylistOverlay`: Anzeige der Playlist.

### 9. `src/components/Audioplayer/PlayerMinimal.vue`
- **Zweck:** Minimalistische Ansicht des Players.
- **Inhalt:** Cover-Bild, Titel, Künstler, Basissteuerung (Skip, Play/Pause).
- **Bemerkung:** Sichtbar, wenn der Player eingeklappt ist.

### 10. `src/components/Audioplayer/PlaylistOverlay.vue`
- **Zweck:** Zeigt die Playlist an.
- **Funktionalität:**
  - **Mobile:** Slide-Up von unten.
  - **Desktop:** Modal-Overlay.
  - **Interaktion:** Track-Auswahl und Schließen.
- **Styling:** Responsiv mit Animationen.

### 11. `src/components/Audioplayer/PlayerExpanded.vue`
- **Zweck:** Erweiterte Ansicht des Players.
- **Inhalt:** 
  - Cover-Bild, Track-Info, Fortschrittsleiste, Steuerung (Shuffle, Skip, Play, Repeat), Lautstärkeregler.
- **Bemerkung:** Sichtbar, wenn der Player ausgeklappt ist.

---

## Routing und Views

### 12. `src/router/index.js`
- **Zweck:** Konfiguriert Vue-Router.
- **Routen:**
  - `/`: `HomeView`.
  - `/about`: `AboutView` (lazy-loaded).
- **Bemerkung:** Einfaches Routing mit Web-History.

### 13. `src/views/HomeView.vue`
- **Zweck:** Startseite mit Audioplayer.
- **Inhalt:** Rendert die `AudioPlayer`-Komponente.

### 14. `src/views/AboutView.vue`
- **Zweck:** Platzhalter für eine About-Seite.
- **Inhalt:** Einfacher Text.

---