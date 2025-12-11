# Nextcloud M346 – Inbetriebnahme

Dieses Repository stellt eine automatisierte Installation von Nextcloud (Community Edition, Archiv-Variante) in AWS bereit. Die Umgebung besteht aus zwei EC2-Instanzen (Webserver + Datenbankserver), die über ein Bash-Skript erstellt und konfiguriert werden.

> **Hinweis:**  
> Details zur Architektur, zu den Skripten und zu den Tests stehen in `docs/Dokumentation.md`.

## Voraussetzungen

Bevor das Deployment gestartet werden kann, müssen folgende Voraussetzungen erfüllt sein:

- AWS-Account mit Berechtigung für:
  - EC2-Instanzen
  - Keypairs
  - Security Groups
  - VPC/Subnets
- Lokale Tools:
  - Git
  - AWS CLI v2 installiert und im `PATH` verfügbar
  - Bash (Linux, macOS oder WSL unter Windows)
- Konfigurierte AWS CLI:
  - `aws configure`
    - Region: `us-east-1`
    - Gültige Access Keys (IAM-User)

## Repository klonen

git clone <URL-zu-diesem-Repository>
cd /Cloud-Projekt-Samuel-Emin-M346

> Die weitere Inbetriebnahme erfolgt aus dem Ordner `scripts`.

## Deployment starten

1. In das Skriptverzeichnis wechseln:

   cd scripts

2. Skript ausführbar machen (falls nötig):

   chmod +x deploy-nextcloud-aws.sh

3. Deployment starten:

   ./deploy-nextcloud-aws.sh

Das Skript erledigt nun automatisch:

- Ermitteln des neusten Ubuntu 22.04 AMIs in `us-east-1`
- Erzeugen eines neuen SSH-Keypairs (`*.pem`)
- Erstellen zweier Security Groups (Web + DB)
- Starten einer DB-Instanz (MariaDB, DB `nextcloud`, User `ncuser`)
- Starten einer Web-Instanz (Apache, PHP, Nextcloud aus Archiv)
- **Falls es irgendwo hängen bleibt dann muss man "Q" drücken**

Am Ende zeigt das Skript im Terminal:

- Public IP der Web-Instanz
- Private IP der DB-Instanz
- Datenbank-Name, Benutzername und Passwort

## Zugriff auf Nextcloud

1. Browser öffnen und die ausgegebene URL des Webservers aufrufen:

   http://<Public-IP-des-Webservers>

2. Es erscheint der Installationsassistent von Nextcloud.

3. Im Schritt „Datenbank einrichten" folgende Werte eintragen:

   - Datenbankname: wie im Skript ausgegeben (Standard: `nextcloud`)
   - Benutzername: wie im Skript ausgegeben (Standard: `ncuser`)
   - Passwort: wie im Skript ausgegeben (Standard: `NcDbPass123!`)
   - Datenbank-Host: Private IP der DB-Instanz (wie im Skript ausgegeben)

4. Admin-Konto für Nextcloud vergeben und Installation starten.

Nach Abschluss ist Nextcloud über die gleiche URL erreichbar.

## SSH-Zugriff (optional)

Das Skript legt automatisch ein neues Keypair an und speichert den privaten Schlüssel im aktuellen Verzeichnis, z.B.:

m346-nextcloud-key-<timestamp>.pem

Beispiel für den SSH-Zugriff auf den Webserver (Ubuntu):

ssh -i m346-nextcloud-key-<timestamp>.pem ubuntu@<Public-IP-des-Webservers>

Analog kann mit der Private IP der DB-Instanz auf den Datenbankserver zugegriffen werden.

## Aufräumen der Ressourcen

Nach Abschluss der Tests sollen alle AWS-Ressourcen wieder gelöscht werden, um unnötige Kosten zu vermeiden.
 
### Variante 1: Automatisch mit Skript
 
Mit dem Skript `scripts/cleanup-nextcloud-aws.sh` werden automatisch:
 
- beide EC2-Instanzen (`m346-nextcloud-web`, `m346-nextcloud-db`) terminiert
- das zum Deployment gehörende Keypair gelöscht
- die beiden Security Groups (`m346-nextcloud-web-sg`, `m346-nextcloud-db-sg`) entfernt, sofern sie nicht mehr verwendet werden.
 
Ausführung:
 
- `cd scripts`
- `chmod +x cleanup-nextcloud-aws.sh`
- `./cleanup-nextcloud-aws.sh`
 
Falls während des Löschens (z.B. bei Security Groups) eine längere, seitenweise Ausgabe erscheint, kann mit der Taste `q` zur Shell zurückgekehrt werden.
 
### Variante 2: Manuell in der AWS-Konsole
 
Alternativ können die gleichen Ressourcen in der AWS Management Console manuell gelöscht werden:
 
- EC2-Instanzen terminieren
- Keypair löschen
- Security Groups löschen, sobald sie von keiner Instanz mehr verwendet werden.

---

Für alle technischen Details zum Skript und zur Architektur siehe `docs/Dokumentation.md`.
