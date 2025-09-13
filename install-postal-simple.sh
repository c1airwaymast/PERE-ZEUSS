#!/bin/bash
# Installation simplifiée Postal pour electricym.net

set -e

# Configuration
DOMAIN="electricym.net"
ADMIN_EMAIL="admin@electricym.net"
HOST_IP="159.69.199.74"

echo "Installation de Postal pour $DOMAIN..."

# Installer Docker si nécessaire
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh
fi

# Nettoyer ancienne installation
[ -d "/opt/postal" ] && rm -rf /opt/postal

# Créer structure
mkdir -p /opt/postal/{config,data,caddy}
cd /opt/postal

# Générer mots de passe
DB_PASS=$(openssl rand -hex 16)
ADMIN_PASS=$(openssl rand -hex 8)

# Clé de signature
openssl genrsa -out config/signing.key 2048

# Configuration Postal
cat > config/postal.yml <<EOF
version: 2
postal:
  web_hostname: $DOMAIN
  web_protocol: https
  smtp_hostname: smtp.$DOMAIN
main_db:
  host: mariadb
  username: postal
  password: $DB_PASS
  database: postal
message_db:
  host: mariadb
  username: postal
  password: $DB_PASS
  prefix: postal
smtp_server:
  default_bind_address: "0.0.0.0"
  default_port: 25
  tls_enabled: true
  tls_certificate_path: /etc/ssl/certs/ssl-cert-snakeoil.pem
  tls_private_key_path: /etc/ssl/private/ssl-cert-snakeoil.key
web_server:
  default_bind_address: "0.0.0.0"
  default_port: 5000
dns:
  mx_records:
    - smtp.$DOMAIN
  return_path_domain: bounce.$DOMAIN
  track_domain: track.$DOMAIN
rails:
  secret_key: $(openssl rand -hex 64)
EOF

# Caddy
cat > caddy/Caddyfile <<EOF
$DOMAIN {
    reverse_proxy postal-web:5000
}
EOF

# Docker Compose
cat > docker-compose.yml <<EOF
services:
  mariadb:
    image: mariadb:10
    environment:
      MARIADB_ROOT_PASSWORD: $DB_PASS
      MARIADB_DATABASE: postal
      MARIADB_USER: postal
      MARIADB_PASSWORD: $DB_PASS
    volumes:
      - ./data/mysql:/var/lib/mysql
    restart: always

  redis:
    image: redis:alpine
    restart: always

  postal-web:
    image: ghcr.io/postalserver/postal:3
    depends_on:
      - mariadb
      - redis
    volumes:
      - ./config:/config
    command: postal web-server
    restart: always

  postal-smtp:
    image: ghcr.io/postalserver/postal:3
    depends_on:
      - postal-web
    volumes:
      - ./config:/config
    command: postal smtp-server
    ports:
      - "25:25"
      - "587:587"
    restart: always

  postal-worker:
    image: ghcr.io/postalserver/postal:3
    depends_on:
      - postal-web
    volumes:
      - ./config:/config
    command: postal worker
    restart: always

  caddy:
    image: caddy:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile
      - ./caddy/data:/data
    restart: always

networks:
  default:
    name: postal
EOF

# Démarrer
docker compose up -d

# Attendre
sleep 30

# Initialiser
docker compose run --rm postal-web postal initialize || true

# Créer admin
echo -e "$ADMIN_EMAIL\n$ADMIN_PASS\n$ADMIN_PASS\nAdmin\nUser\ny" | docker compose run --rm postal-web postal make-user || true

# Afficher infos
echo "================================"
echo "Installation terminée!"
echo "URL: https://$DOMAIN"
echo "Email: $ADMIN_EMAIL"
echo "Password: $ADMIN_PASS"
echo "================================"

# Sauvegarder
echo "URL: https://$DOMAIN" > /opt/postal/credentials.txt
echo "Email: $ADMIN_EMAIL" >> /opt/postal/credentials.txt
echo "Password: $ADMIN_PASS" >> /opt/postal/credentials.txt