#!/bin/bash
# cleanup-nextcloud-aws.sh
# Räumt Ressourcen des m346-nextcloud Deploy-Skripts auf:
# - EC2 Web + DB Instanzen terminieren
# - zugehörige Security Groups löschen
# - erzeugtes Keypair löschen (per Tag gefunden)
# Achtung: endgültige Löschung der Instanzen!

set -e

AWS_REGION="us-east-1"
PROJECT_NAME="m346-nextcloud"

echo "[*] Region: ${AWS_REGION}"
export AWS_REGION

########################
# Instanzen finden
########################
echo "[*] Suche EC2-Instanzen mit Name-Tag ${PROJECT_NAME}-web / ${PROJECT_NAME}-db ..."

WEB_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${PROJECT_NAME}-web" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

DB_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${PROJECT_NAME}-db" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

echo "[*] Gefundene Web-Instance: ${WEB_INSTANCE_ID:-<keine>}"
echo "[*] Gefundene DB-Instance : ${DB_INSTANCE_ID:-<keine>}"

########################
# Instanzen terminieren
########################
IDS_TO_TERMINATE=""
[ -n "${WEB_INSTANCE_ID}" ] && IDS_TO_TERMINATE+=" ${WEB_INSTANCE_ID}"
[ -n "${DB_INSTANCE_ID}" ] && IDS_TO_TERMINATE+=" ${DB_INSTANCE_ID}"

if [ -n "${IDS_TO_TERMINATE}" ]; then
  echo "[*] Terminiere Instanzen:${IDS_TO_TERMINATE}"
  aws ec2 terminate-instances --instance-ids ${IDS_TO_TERMINATE}
  aws ec2 wait instance-terminated --instance-ids ${IDS_TO_TERMINATE}   # wartet bis wirklich weg[web:52][web:55]
else
  echo "[*] Keine zu terminierenden Instanzen gefunden."
fi

########################
# Security Groups löschen
########################
echo "[*] Lösche Security Groups ..."

WEB_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${PROJECT_NAME}-web-sg" \
  --query 'SecurityGroups[].GroupId' \
  --output text)

DB_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${PROJECT_NAME}-db-sg" \
  --query 'SecurityGroups[].GroupId' \
  --output text)

if [ -n "${WEB_SG_ID}" ]; then
  echo "[*] Lösche Web-SG: ${WEB_SG_ID}"
  aws ec2 delete-security-group --group-id "${WEB_SG_ID}"   # SG nach ID löschen[web:41][web:51]
else
  echo "[*] Keine Web-SG gefunden."
fi

if [ -n "${DB_SG_ID}" ]; then
  echo "[*] Lösche DB-SG: ${DB_SG_ID}"
  aws ec2 delete-security-group --group-id "${DB_SG_ID}"
else
  echo "[*] Keine DB-SG gefunden."
fi

########################
# Keypair finden & löschen
########################
echo "[*] Versuche, Keypair zu finden ..."

KEY_NAME=$(aws ec2 describe-key-pairs \
  --query "KeyPairs[?starts_with(KeyName, \`${PROJECT_NAME}-key-\`)].KeyName | [-1]" \
  --output text)

if [ -n "${KEY_NAME}" ] && [ "${KEY_NAME}" != "None" ]; then
  echo "[*] Lösche Keypair: ${KEY_NAME}"
  aws ec2 delete-key-pair --key-name "${KEY_NAME}"           # Keypair per Name löschen[web:47][web:50]
  if [ -f "${KEY_NAME}.pem" ]; then
    echo "[*] Entferne lokale Key-Datei: ${KEY_NAME}.pem"
    rm -f "${KEY_NAME}.pem"
  fi
else
  echo "[*] Kein passendes Keypair gefunden."
fi

echo "======================================================="
echo " Cleanup abgeschlossen für Projekt: ${PROJECT_NAME}"
echo "======================================================="
