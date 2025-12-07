#!/bin/bash
###############################################################################
#  _   _           _            _                 _           _ 
# | \ | | ___  ___| | ___   ___| |__   ___   ___ | | ___  ___| |
# |  \| |/ _ \/ __| |/ _ \ / __| '_ \ / _ \ / _ \| |/ _ \/ __| |
# | |\  |  __/ (__| | (_) | (__| | | | (_) | (_) | |  __/\__ \_|
# |_| \_|\___|\___|_|\___/ \___|_| |_|\___/ \___/|_|\___||___(_)
#
#  Vollautomatisches Nextcloud-Deployment auf AWS (us-east-1)
#  - Sucht Subnet dynamisch
#  - Erzeugt eigenes Keypair automatisch
#  - Nutzt latest Nextcloud-Archiv
#  - Zwei EC2-Instanzen: Web (Nextcloud) + DB (MariaDB)
###############################################################################

set -e

########################
# Region & Grundeinstellungen
########################

export AWS_REGION="us-east-1"
aws configure set region us-east-1 >/dev/null 2>&1 || true

PROJECT_NAME="m346-nextcloud"
INSTANCE_TYPE="t3.micro"

# Nextcloud / DB Einstellungen
NC_DB_NAME="nextcloud"
NC_DB_USER="ncuser"
NC_DB_PASS="NcDbPass123!"
DB_ROOT_PASS="RootPass123!"
NC_URL="https://download.nextcloud.com/server/releases/latest.tar.bz2"   # immer aktuelle Version [web:1][web:2][web:17]

########################
# Ubuntu 22.04 AMI holen
########################
AMI_FILTER="ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"

echo "┌──────────────────────────────────────────────┐"
echo "│ [*] Ermittle Ubuntu 22.04 AMI in ${AWS_REGION} ... │"
echo "└──────────────────────────────────────────────┘"
AMI_ID=$(aws ec2 describe-images \
  --owners "099720109477" \
  --filters "Name=name,Values=${AMI_FILTER}" "Name=architecture,Values=x86_64" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text)

echo "[*] Verwende AMI: ${AMI_ID}"

########################
# Default-Subnet dynamisch holen
########################
echo
echo "┌──────────────────────────────────────────────┐"
echo "│ [*] Ermittle Default-Subnet in ${AWS_REGION} ... │"
echo "└──────────────────────────────────────────────┘"
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=default-for-az,Values=true" \
  --query 'Subnets[0].SubnetId' \
  --output text)

if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" = "None" ]; then
  echo "[!] Konnte kein Default-Subnet finden – breche ab."
  exit 1
fi

echo "[*] Verwende Subnet: ${SUBNET_ID}"

VPC_ID=$(aws ec2 describe-subnets --subnet-ids "${SUBNET_ID}" --query 'Subnets[0].VpcId' --output text)

########################
# Eigenes Keypair erzeugen
########################
KEY_NAME="${PROJECT_NAME}-key-$(date +%s)"

echo
echo "┌─────────────────────────────┐"
echo "│ [*] Erzeuge Keypair: ${KEY_NAME} │"
echo "└─────────────────────────────┘"
aws ec2 create-key-pair \
  --key-name "${KEY_NAME}" \
  --query "KeyMaterial" \
  --output text > "${KEY_NAME}.pem"

chmod 400 "${KEY_NAME}.pem"

########################
# Security Groups
########################
echo
echo "┌──────────────────────────────────────────────┐"
echo "│ [*] Erstelle Security Group für Webserver ... │"
echo "└──────────────────────────────────────────────┘"
WEB_SG_ID=$(aws ec2 create-security-group \
  --group-name "${PROJECT_NAME}-web-sg" \
  --description "Web SG for Nextcloud" \
  --vpc-id "${VPC_ID}" \
  --query 'GroupId' \
  --output text)

echo
echo "┌────────────────────────────────────────────┐"
echo "│ [*] Erstelle Security Group für DB ...    │"
echo "└────────────────────────────────────────────┘"
DB_SG_ID=$(aws ec2 create-security-group \
  --group-name "${PROJECT_NAME}-db-sg" \
  --description "DB SG for Nextcloud" \
  --vpc-id "${VPC_ID}" \
  --query 'GroupId' \
  --output text)

echo
echo "┌────────────────────────────────────┐"
echo "│ [*] Konfiguriere Web-SG (HTTP+SSH) │"
echo "└────────────────────────────────────┘"
aws ec2 authorize-security-group-ingress \
  --group-id "${WEB_SG_ID}" \
  --ip-permissions '[
    {"IpProtocol":"tcp","FromPort":80,"ToPort":80,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]},
    {"IpProtocol":"tcp","FromPort":22,"ToPort":22,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}
  ]'

echo
echo "┌───────────────────────────────────────────────────────────────┐"
echo "│ [*] Konfiguriere DB-SG (3306 nur vom Web-SG, SSH weltweit)   │"
echo "└───────────────────────────────────────────────────────────────┘"
aws ec2 authorize-security-group-ingress \
  --group-id "${DB_SG_ID}" \
  --ip-permissions "[
    {\"IpProtocol\":\"tcp\",\"FromPort\":3306,\"ToPort\":3306,
     \"UserIdGroupPairs\":[{\"GroupId\":\"${WEB_SG_ID}\"}]},
    {\"IpProtocol\":\"tcp\",\"FromPort\":22,\"ToPort\":22,
     \"IpRanges\":[{\"CidrIp\":\"0.0.0.0/0\"}]}
  ]"

########################
# UserData: DB-Server
########################
DB_USER_DATA=$(cat <<EOF
#!/bin/bash
set -e

apt update -y
apt upgrade -y
apt install -y mariadb-server

systemctl enable mariadb
systemctl start mariadb

DB_ROOT_PASS="${DB_ROOT_PASS}"
NC_DB_NAME="${NC_DB_NAME}"
NC_DB_USER="${NC_DB_USER}"
NC_DB_PASS="${NC_DB_PASS}"

mysql -u root <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
FLUSH PRIVILEGES;
SQL

mysql -u root -p"\${DB_ROOT_PASS}" <<SQL
CREATE DATABASE IF NOT EXISTS \\\`${NC_DB_NAME}\\\`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '\${NC_DB_USER}'@'%' IDENTIFIED BY '\${NC_DB_PASS}';
GRANT ALL PRIVILEGES ON \\\`${NC_DB_NAME}\\\`.* TO '\${NC_DB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf || true
systemctl restart mariadb

IP=\$(hostname -I | awk '{print \$1}')

echo "==================================="  > /root/db-info.txt
echo "MariaDB für Nextcloud bereit"        >> /root/db-info.txt
echo "DB Name : \${NC_DB_NAME}"            >> /root/db-info.txt
echo "User    : \${NC_DB_USER}"            >> /root/db-info.txt
echo "Pass    : \${NC_DB_PASS}"            >> /root/db-info.txt
echo "Host    : \${IP}"                    >> /root/db-info.txt
echo "==================================="  >> /root/db-info.txt
EOF
)

########################
# DB-Instance starten
########################
echo
echo "┌────────────────────────────┐"
echo "│ [*] Starte DB-Instance ... │"
echo "└────────────────────────────┘"
DB_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "${AMI_ID}" \
  --instance-type "${INSTANCE_TYPE}" \
  --key-name "${KEY_NAME}" \
  --subnet-id "${SUBNET_ID}" \
  --security-group-ids "${DB_SG_ID}" \
  --user-data "${DB_USER_DATA}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PROJECT_NAME}-db}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

aws ec2 wait instance-running --instance-ids "${DB_INSTANCE_ID}"

DB_PRIVATE_IP=$(aws ec2 describe-instances \
  --instance-ids "${DB_INSTANCE_ID}" \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text)

echo "[*] DB Private IP: ${DB_PRIVATE_IP}"

########################
# UserData: Web-Server
########################
WEB_USER_DATA=$(cat <<EOF
#!/bin/bash
set -e

apt update -y
apt upgrade -y
apt install -y apache2 libapache2-mod-php php \
  php-gd php-mysql php-curl php-mbstring php-intl \
  php-xml php-zip php-gmp php-bcmath php-imagick \
  wget bzip2

a2enmod php* rewrite headers env dir mime
systemctl enable apache2
systemctl restart apache2

NC_URL="${NC_URL}"
WEBROOT="/var/www"
NCDIR="\${WEBROOT}/nextcloud"
APACHE_CONF="/etc/apache2/sites-available/nextcloud.conf"

DB_NAME="${NC_DB_NAME}"
DB_USER="${NC_DB_USER}"
DB_PASS="${NC_DB_PASS}"
DB_HOST="${DB_PRIVATE_IP}"

cd /tmp
wget "\${NC_URL}" -O nextcloud-latest.tar.bz2
tar -xjf nextcloud-latest.tar.bz2
mv nextcloud "\${NCDIR}"

chown -R www-data:www-data "\${NCDIR}"
find "\${NCDIR}" -type d -exec chmod 750 {} \;
find "\${NCDIR}" -type f -exec chmod 640 {} \;

cat > "\${APACHE_CONF}" <<VHOST
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot \${NCDIR}

    <Directory \${NCDIR}>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
VHOST

a2dissite 000-default.conf || true
a2ensite nextcloud.conf
systemctl reload apache2

PHPINI=\$(php -r 'echo php_ini_loaded_file();')
if [ -n "\$PHPINI" ]; then
  sed -i 's/^memory_limit.*/memory_limit = 512M/' "\$PHPINI"
  sed -i 's/^upload_max_filesize.*/upload_max_filesize = 512M/' "\$PHPINI"
  sed -i 's/^post_max_size.*/post_max_size = 512M/' "\$PHPINI"
  sed -i 's/^max_execution_time.*/max_execution_time = 360/' "\$PHPINI"
fi

systemctl restart apache2

echo "================================================"  > /root/web-info.txt
echo "Nextcloud Webserver vorbereitet."                 >> /root/web-info.txt
echo "Öffne im Browser die Public-IP dieses Servers."   >> /root/web-info.txt
echo "Nutze im Installer folgende DB-Daten:"            >> /root/web-info.txt
echo "  DB Name : \${DB_NAME}"                          >> /root/web-info.txt
echo "  User    : \${DB_USER}"                          >> /root/web-info.txt
echo "  Pass    : \${DB_PASS}"                          >> /root/web-info.txt
echo "  Host    : \${DB_HOST}"                          >> /root/web-info.txt
echo "================================================"  >> /root/web-info.txt
EOF
)

########################
# Web-Instance starten
########################
echo
echo "┌─────────────────────────────┐"
echo "│ [*] Starte Web-Instance ... │"
echo "└─────────────────────────────┘"
WEB_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "${AMI_ID}" \
  --instance-type "${INSTANCE_TYPE}" \
  --key-name "${KEY_NAME}" \
  --subnet-id "${SUBNET_ID}" \
  --security-group-ids "${WEB_SG_ID}" \
  --user-data "${WEB_USER_DATA}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PROJECT_NAME}-web}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

aws ec2 wait instance-running --instance-ids "${WEB_INSTANCE_ID}"

WEB_PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "${WEB_INSTANCE_ID}" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

########################
# Ausgabe
########################
echo
echo "======================================================="
echo "   ____            _           _                 _     "
echo "  |  _ \ _ __ ___ | |__   ___ | | ___   __ _  __| |    "
echo "  | |_) | '__/ _ \| '_ \ / _ \| |/ _ \ / _\` |/ _\` |    "
echo "  |  __/| | | (_) | | | | (_) | | (_) | (_| | (_| |    "
echo "  |_|   |_|  \___/|_| |_|\___/|_|\___/ \__,_|\__,_|    "
echo
echo " Deployment abgeschlossen (Region ${AWS_REGION})."
echo ""
echo " Webserver:"
echo "   Instance ID : ${WEB_INSTANCE_ID}"
echo "   Public IP   : ${WEB_PUBLIC_IP}"
echo "   URL         : http://${WEB_PUBLIC_IP}"
echo ""
echo " Datenbankserver:"
echo "   Instance ID  : ${DB_INSTANCE_ID}"
echo "   Private IP   : ${DB_PRIVATE_IP}"
echo ""
echo " SSH-Keypair wurde erzeugt:"
echo "   Datei: ${KEY_NAME}.pem"
echo "   Nutzung z.B.: ssh -i ${KEY_NAME}.pem ubuntu@${WEB_PUBLIC_IP}"
echo ""
echo " Trage im Nextcloud-Installer ein:"
echo "   DB Name : ${NC_DB_NAME}"
echo "   User    : ${NC_DB_USER}"
echo "   Pass    : ${NC_DB_PASS}"
echo "   Host    : ${DB_PRIVATE_IP}"
echo "======================================================="
