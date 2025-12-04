# Nextcloud Projekt – Dokumentation (Modul 346) Samuel und Emin

## 1. Einleitung
In diesem Projekt wird eine Nextcloud-Installation mithilfe von **automatisierten Skripten** bereitgestellt.  
Das Ziel besteht darin, den Webserver, die PHP-Umgebung, die Nextcloud-Dateien sowie die Datenbank vollständig per Script einzurichten, ohne dass manuelle Installationsschritte notwendig sind.

Die Dokumentation beschreibt **den Aufbau, die Funktion, den Zweck und den Ablauf der Skripte**, sowie Screenshots der Ergebnisse, die durch die Automatisierung erzeugt wurden.

---

## 2. Architektur (2-Server-Modell)

### 2.1 Überblick
Die automatisierte Installation setzt auf zwei Server:

- **Webserver (Nextcloud)**  
  - Wird automatisch durch ein Bash- oder Cloud-Init-Skript eingerichtet.
  - Installiert Apache, PHP und Nextcloud.

- **Datenbankserver (MariaDB)**  
  - Kann manuell erstellt sein oder ebenfalls durch ein eigenes Skript.
  - Das Skript legt automatisch die Datenbank, Benutzer und Berechtigungen an.

---

### 2.2 Architekturdiagramm

![Architekturdiagramm](Grafiken/architektur.png)




