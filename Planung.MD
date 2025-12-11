# Projektplan für M346 Nextcloud Projekt

**Zeitraum:** 20.11 – 17.12  
**Arbeitszeit pro Woche:** 1.5 Stunden  
**Ziel:** Strukturierter Plan zur vollständigen und stressfreien Fertigstellung des Projekts

---

## Woche 1 (20.11 – 26.11)
**Ziel:** Projekt starten & Grundlage schaffen  
### Aufgaben:
- Git Repository clonen  
- Ordnerstruktur erstellen (`docs/`, `scripts/`, `screenshots/`)  
- README für Inbetriebnahme anlegen  
- Dokumentation.md erstellen  
- Projektarchitektur (2-Server-Modell) grob skizzieren  
- Aufgabenverteilung innerhalb der Gruppe festlegen  
- Ersten Commit erstellen  

---

## Woche 2 (27.11 – 03.12)
**Ziel:** Server bereitstellen  
### Aufgaben:
- Webserver-VM installieren (Ubuntu)  
- Apache installieren  
- PHP + Module installieren  
- Datenbank-VM installieren (Ubuntu)  
- MariaDB installieren  
- Datenbank + Benutzer für Nextcloud anlegen  
- Verbindung zwischen Webserver & Datenbank testen  
- Schritte dokumentieren & Screenshots erstellen  

---

## Woche 3 (04.12 – 10.12)
**Ziel:** Nextcloud + Automatisierung  
### Aufgaben:
- Installationsscript (`install_nextcloud.sh`) erstellen  
- Nextcloud Archiv herunterladen & entpacken  
- Apache Konfiguration erstellen  
- Berechtigungen setzen  
- Ausgabe der Datenbankverbindungsdaten in Konsole implementieren  
- Cloud-Init Version vorbereiten (falls nötig)  
- Dokumentation erweitern (Umsetzung)  

---

## Woche 4 (11.12 – 17.12)
**Ziel:** Nextcloud testen & Dokumentation finalisieren  
### Aufgaben:
- Nextcloud im Browser testen  
- Install Assistent mit DB-Daten ausfüllen  
- Screenshots der Testfälle erstellen  
- Testbericht schreiben:  
  - Testfälle  
  - Resultate  
  - Screenshots  
  - Fazit  
- Reflexion schreiben  
- Dokumentation fertigstellen  
- Rechtschreibung prüfen  

---

## Woche 5 (18.12 – Abgabetag)
**Ziel:** Finaler Check & Abgabe  
### Aufgaben:
- Alle Commits noch einmal prüfen  
- README überprüfen  
- Dokumentation final lesen  
- Repo-Link kontrollieren  
- Lehrperson berechtigen  
- Projekt abgeben  

---

## Erfolgskriterien
- Sauberes Repository  
- Logische Struktur  
- Funktionierende Installation  
- Nachvollziehbare Dokumentation  
- Saubere Screenshots  
- Gute Reflexion 


### 8.1.1 Vergleich: Manuelle Installation vs. Skript-Deployment

| Aspekt                         | Manuelle Installation                                      | Skript-Deployment (IaC)                                      |
|--------------------------------|------------------------------------------------------------|--------------------------------------------------------------|
| Aufwand pro Deployment         | Viele Einzelschritte, hohe Klick- und Tipp-Arbeit         | Ein Kommando startet komplettes Setup                       |
| Fehleranfälligkeit             | Hohe Gefahr für Tippfehler und vergessene Schritte        | Wiederholbar, gleiche Schritte bei jedem Lauf               |
| Dauer bis zum laufenden System | Deutlich länger, abhängig von Erfahrung der Person        | Minuten, unabhängig von der ausführenden Person             |
| Dokumentation der Schritte     | Muss separat geschrieben werden                           | Skript ist „ausführbare Dokumentation“ der Infrastruktur    |
| Skalierung / Wiederverwendung  | Kaum wiederverwendbar, alles muss neu gemacht werden      | Skript kann mehrfach und in anderen Umgebungen genutzt werden |
| Nachvollziehbarkeit            | Schwer nachzuvollziehen, was genau gemacht wurde         | Jeder Befehl ist im Skript sichtbar und versioniert (Git)   |

