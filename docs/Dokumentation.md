# Nextcloud Projekt – Dokumentation (Modul 346)

## 1. Einleitung
In diesem Projekt setzen wir eine Nextcloud-Installation in einer Cloud-Umgebung um.  
Dabei verwenden wir ein **2-Server-Modell**, bestehend aus einem Webserver und einem separaten Datenbankserver.  
Das Ziel ist, eine funktionierende Nextcloud bereitzustellen, die über ein Installationsskript bzw. Cloud-Init automatisch eingerichtet werden kann.

Dieses Dokument beschreibt die Architektur, die Umsetzung, Tests, Ergebnisse und die Reflexion des Projektes.

---

## 2. Architektur

### 2.1 Überblick
Die Projektarchitektur besteht aus zwei voneinander getrennten Systemen:

- **Webserver (Nextcloud)**  
  - Apache Webserver  
  - PHP + benötigte Module  
  - Nextcloud Community Edition  
  - öffentliche IP für Benutzerzugriff  

- **Datenbankserver**  
  - MariaDB  
  - interne IP (nur für Webserver zugänglich)  
  - separate DB, Benutzer und Passwort für Nextcloud  

Die Trennung erhöht Sicherheit, Skalierbarkeit und entspricht professionellen Cloud-Standards.

---

### 2.2 Architekturdiagramm

![Architekturdiagramm](Grafiken/architektur.png)




