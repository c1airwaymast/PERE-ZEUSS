#!/usr/bin/env bash
set -euo pipefail

# ========================================
# Script d'installation automatique Postal SMTP
# Domain: electricym.net
# Admin: admin@electricym.net
# IP: 159.69.199.74
# ========================================

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ====== CONFIGURATION ======
DOMAIN="${DOMAIN:-electricym.net}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@electricym.net}"
HOST_IP="${HOST_IP:-159.69.199.74}"

# Mots de passe générés automatiquement (plus sécurisé)
DB_ROOT_PASS="${DB_ROOT_PASS:-$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)}"
DB_PASS="${DB_PASS:-$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)}"
ADMIN_PASS="${ADMIN_PASS:-$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)}"

# Version stable de Postal
POSTAL_VERSION="${POSTAL_VERSION:-3.3.4}"

# Sous-domaines
SMTP_HOSTNAME="smtp.${DOMAIN}"
RETURN_PATH_DOMAIN="bounce.${DOMAIN}"
TRACK_DOMAIN="track.${DOMAIN}"

# Répertoire d'installation
INSTALL_DIR="/opt/postal"

# ====== VÉRIFICATIONS PRÉALABLES ======
log_info "Vérification des prérequis..."

# Vérifier si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   log_error "Ce script doit être exécuté en tant que root"
fi

# Vérifier la présence de Docker
if ! command -v docker &> /dev/null; then
    log_warning "Docker n'est pas installé. Installation en cours..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

# Vérifier Docker Compose
if ! docker compose version &> /dev/null; then
    log_warning "Docker Compose n'est pas installé. Installation en cours..."
    apt-get update && apt-get install -y docker-compose-plugin
fi

# Vérifier les outils nécessaires
for tool in openssl curl dig; do
    if ! command -v $tool &> /dev/null; then
        log_warning "$tool n'est pas installé. Installation..."
        apt-get update && apt-get install -y $tool
    fi
done

# ====== NETTOYAGE ÉVENTUEL D'UNE INSTALLATION PRÉCÉDENTE ======
if [ -d "$INSTALL_DIR" ]; then
    log_warning "Une installation précédente a été détectée dans $INSTALL_DIR"
    read -p "Voulez-vous la supprimer et réinstaller? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Arrêt des conteneurs existants..."
        cd "$INSTALL_DIR" 2>/dev/null && docker compose down -v 2>/dev/null || true
        cd /
        log_info "Suppression de l'ancienne installation..."
        rm -rf "$INSTALL_DIR"
    else
        log_error "Installation annulée. Veuillez sauvegarder ou supprimer l'installation existante."
    fi
fi

# ====== CRÉATION DE LA STRUCTURE ======
log_info "Création de la structure des répertoires..."
mkdir -p "${INSTALL_DIR}"/{config,logs,data/{mariadb,redis},caddy/{data,config}}
cd "${INSTALL_DIR}"

# ====== GÉNÉRATION DES CLÉS ======
log_info "Génération de la clé de signature..."
if [ ! -f config/signing.key ]; then
    openssl genrsa -out config/signing.key 2048
    chmod 600 config/signing.key
fi

# Secret Rails
RSECRET="$(openssl rand -hex 64)"

# ====== CRÉATION DU FICHIER DE CONFIGURATION POSTAL ======
log_info "Création de la configuration Postal..."
cat > config/postal.yml <<YAML
version: 2

postal:
  web_hostname: ${DOMAIN}
  web_protocol: https
  smtp_hostname: ${SMTP_HOSTNAME}
  use_ip_pools: false
  default_maximum_delivery_attempts: 18
  default_maximum_hold_expiry_days: 7
  suppression_list_automatic_removal_days: 30
  
main_db:
  host: mariadb
  username: postal
  password: ${DB_PASS}
  database: postal
  pool_size: 25

message_db:
  host: mariadb
  username: postal
  password: ${DB_PASS}
  prefix: postal

smtp_server:
  default_bind_address: "0.0.0.0"
  default_port: 25
  tls_enabled: true
  tls_certificate_path: /etc/ssl/certs/ssl-cert-snakeoil.pem
  tls_private_key_path: /etc/ssl/private/ssl-cert-snakeoil.key
  proxy_protocol: false
  log_connections: true
  
smtp_relay:
  enabled: false
  
web_server:
  default_bind_address: "0.0.0.0"
  default_port: 5000
  
dns:
  mx_records:
    - ${SMTP_HOSTNAME}
  return_path_domain: ${RETURN_PATH_DOMAIN}
  track_domain: ${TRACK_DOMAIN}
  helo_hostname: ${SMTP_HOSTNAME}
  dkim_identifier: postal
  domain_verify_prefix: postal-verification
  custom_return_path_prefix: psrp
  
rails:
  secret_key: ${RSECRET}
  environment: production
  
general:
  use_local_ns_for_domains: false
  
logging:
  rails_log_enabled: true
  smtp_log_enabled: true
YAML

# ====== CONFIGURATION CADDY (REVERSE PROXY) ======
log_info "Configuration du reverse proxy Caddy..."
cat > caddy/Caddyfile <<CADDY
{
    email ${ADMIN_EMAIL}
    acme_dns cloudflare {env.CF_API_TOKEN}
}

${DOMAIN} {
    encode zstd gzip
    
    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
    
    reverse_proxy postal-web:5000 {
        header_up X-Forwarded-Proto {scheme}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
    }
    
    log {
        output file /data/access.log
    }
}

${TRACK_DOMAIN} {
    encode zstd gzip
    
    reverse_proxy postal-web:5000 {
        header_up X-Forwarded-Proto {scheme}
        header_up X-Postal-Track-Host 1
    }
}

${RETURN_PATH_DOMAIN} {
    encode zstd gzip
    
    reverse_proxy postal-web:5000 {
        header_up X-Forwarded-Proto {scheme}
    }
}
CADDY

# ====== DOCKER COMPOSE ======
log_info "Création du fichier Docker Compose..."
cat > docker-compose.yml <<YAML
services:
  mariadb:
    image: mariadb:10.11
    container_name: postal-mariadb
    environment:
      MARIADB_DATABASE: postal
      MARIADB_ROOT_PASSWORD: ${DB_ROOT_PASS}
      MARIADB_USER: postal
      MARIADB_PASSWORD: ${DB_PASS}
    command: >
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --innodb_log_file_size=256M
      --max_connections=200
      --innodb_buffer_pool_size=512M
    volumes:
      - ./data/mariadb:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-p\${DB_ROOT_PASS}"]
      interval: 10s
      timeout: 5s
      retries: 30
      start_period: 30s
    restart: unless-stopped
    networks: [postal-net]

  redis:
    image: redis:7-alpine
    container_name: postal-redis
    command: ["redis-server", "--appendonly", "yes", "--maxmemory", "256mb", "--maxmemory-policy", "allkeys-lru"]
    volumes:
      - ./data/redis:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 30
    restart: unless-stopped
    networks: [postal-net]

  postal-web:
    image: ghcr.io/postalserver/postal:${POSTAL_VERSION}
    container_name: postal-web
    depends_on:
      mariadb:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      WAIT_FOR_TARGETS: "mariadb:3306 redis:6379"
      RAILS_ENV: production
    volumes:
      - ./config:/config
      - ./logs:/logs
    command: ["postal", "web-server"]
    restart: unless-stopped
    networks: [postal-net]

  postal-smtp:
    image: ghcr.io/postalserver/postal:${POSTAL_VERSION}
    container_name: postal-smtp
    depends_on:
      postal-web:
        condition: service_started
    cap_add:
      - NET_BIND_SERVICE
    environment:
      WAIT_FOR_TARGETS: "mariadb:3306 redis:6379"
      RAILS_ENV: production
    volumes:
      - ./config:/config
      - ./logs:/logs
    command: ["postal", "smtp-server"]
    ports:
      - "25:25"
      - "587:587"
      - "2525:2525"
    restart: unless-stopped
    networks: [postal-net]

  postal-worker:
    image: ghcr.io/postalserver/postal:${POSTAL_VERSION}
    container_name: postal-worker
    depends_on:
      postal-web:
        condition: service_started
    environment:
      WAIT_FOR_TARGETS: "mariadb:3306 redis:6379"
      RAILS_ENV: production
    volumes:
      - ./config:/config
      - ./logs:/logs
    command: ["postal", "worker"]
    restart: unless-stopped
    networks: [postal-net]

  caddy:
    image: caddy:2-alpine
    container_name: postal-caddy
    depends_on:
      - postal-web
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - ./caddy/data:/data
      - ./caddy/config:/config
    restart: unless-stopped
    networks: [postal-net]

networks:
  postal-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.22.0.0/16
YAML

# ====== VALIDATION DE LA CONFIGURATION ======
log_info "Validation de la configuration Docker Compose..."
if ! docker compose config >/dev/null 2>&1; then
    log_error "La configuration Docker Compose est invalide"
fi

# ====== DÉMARRAGE DES SERVICES ======
log_info "Démarrage de MariaDB et Redis..."
docker compose up -d mariadb redis

# Attendre que les bases soient prêtes
log_info "Attente de la disponibilité des bases de données..."
sleep 20

# Vérifier que MariaDB est prêt
max_attempts=30
attempt=0
while ! docker exec postal-mariadb mysqladmin ping -h localhost -p"${DB_ROOT_PASS}" --silent 2>/dev/null; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        log_error "MariaDB n'a pas démarré après $max_attempts tentatives"
    fi
    log_info "Attente de MariaDB... (tentative $attempt/$max_attempts)"
    sleep 5
done
log_success "MariaDB est prêt"

# Vérifier que Redis est prêt
attempt=0
while ! docker exec postal-redis redis-cli ping 2>/dev/null | grep -q PONG; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        log_error "Redis n'a pas démarré après $max_attempts tentatives"
    fi
    log_info "Attente de Redis... (tentative $attempt/$max_attempts)"
    sleep 5
done
log_success "Redis est prêt"

log_info "Démarrage de Postal et du proxy..."
docker compose up -d postal-web postal-smtp postal-worker caddy

# Attendre que Postal soit prêt
sleep 10

# ====== INITIALISATION DE LA BASE DE DONNÉES ======
log_info "Initialisation de la base de données Postal..."
if docker compose run --rm postal-web postal initialize 2>&1 | tee /tmp/postal_init.log | grep -q "already been initialized"; then
    log_warning "La base de données était déjà initialisée"
else
    log_success "Base de données initialisée avec succès"
fi

# ====== CRÉATION AUTOMATIQUE DE L'UTILISATEUR ADMIN ======
log_info "Création de l'utilisateur administrateur..."

# Créer un script Ruby pour créer l'utilisateur sans interaction
cat > /tmp/create_admin.rb <<RUBY
#!/usr/bin/env ruby
require '/opt/postal/app/lib/postal'

# Créer l'utilisateur admin
user = User.create!(
  email: '${ADMIN_EMAIL}',
  password: '${ADMIN_PASS}',
  password_confirmation: '${ADMIN_PASS}',
  first_name: 'Admin',
  last_name: 'User',
  admin: true
)

if user.persisted?
  puts "Utilisateur admin créé avec succès!"
  puts "Email: ${ADMIN_EMAIL}"
  puts "Mot de passe: ${ADMIN_PASS}"
else
  puts "Erreur lors de la création de l'utilisateur: #{user.errors.full_messages.join(', ')}"
  exit 1
end
RUBY

# Copier et exécuter le script dans le conteneur
docker cp /tmp/create_admin.rb postal-web:/tmp/create_admin.rb
if docker exec postal-web ruby /tmp/create_admin.rb 2>/dev/null; then
    log_success "Utilisateur administrateur créé"
else
    log_warning "L'utilisateur existe peut-être déjà ou création manuelle nécessaire"
    log_info "Tentative de création manuelle..."
    echo -e "${ADMIN_EMAIL}\n${ADMIN_PASS}\n${ADMIN_PASS}\nAdmin\nUser\ny" | docker compose run --rm postal-web postal make-user 2>/dev/null || true
fi

# Nettoyer
rm -f /tmp/create_admin.rb /tmp/postal_init.log

# ====== CONFIGURATION DU FIREWALL ======
log_info "Configuration du firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp comment 'SSH' 2>/dev/null || true
    ufw allow 80/tcp comment 'HTTP' 2>/dev/null || true
    ufw allow 443/tcp comment 'HTTPS' 2>/dev/null || true
    ufw allow 25/tcp comment 'SMTP' 2>/dev/null || true
    ufw allow 587/tcp comment 'SMTP Submission' 2>/dev/null || true
    ufw allow 2525/tcp comment 'SMTP Alternative' 2>/dev/null || true
    ufw --force enable 2>/dev/null || true
    log_success "Firewall configuré"
fi

# ====== SAUVEGARDE DES INFORMATIONS ======
log_info "Sauvegarde des informations de connexion..."
cat > "${INSTALL_DIR}/credentials.txt" <<EOF
========================================
INFORMATIONS DE CONNEXION POSTAL
========================================
Date d'installation: $(date)
Version Postal: ${POSTAL_VERSION}

ACCÈS WEB:
----------
URL: https://${DOMAIN}
Email: ${ADMIN_EMAIL}
Mot de passe: ${ADMIN_PASS}

BASE DE DONNÉES:
----------------
Root Password: ${DB_ROOT_PASS}
Postal DB Password: ${DB_PASS}

CONFIGURATION SMTP:
------------------
Serveur SMTP: ${SMTP_HOSTNAME}
Ports: 25, 587, 2525
TLS: Activé

DOMAINES:
---------
Principal: ${DOMAIN}
SMTP: ${SMTP_HOSTNAME}
Return Path: ${RETURN_PATH_DOMAIN}
Tracking: ${TRACK_DOMAIN}

ENREGISTREMENTS DNS À CONFIGURER:
---------------------------------
1. A Record:
   ${DOMAIN} -> ${HOST_IP}
   ${SMTP_HOSTNAME} -> ${HOST_IP}
   ${RETURN_PATH_DOMAIN} -> ${HOST_IP}
   ${TRACK_DOMAIN} -> ${HOST_IP}

2. MX Record:
   ${DOMAIN} -> 10 ${SMTP_HOSTNAME}

3. SPF Record:
   ${DOMAIN} -> "v=spf1 ip4:${HOST_IP} ~all"

4. DMARC Record:
   _dmarc.${DOMAIN} -> "v=DMARC1; p=quarantine; rua=mailto:${ADMIN_EMAIL}"

5. PTR Record (Reverse DNS):
   ${HOST_IP} -> ${SMTP_HOSTNAME}

COMMANDES UTILES:
----------------
Voir les logs: docker compose logs -f
Redémarrer: docker compose restart
Arrêter: docker compose down
Mise à jour: docker compose pull && docker compose up -d

========================================
EOF

chmod 600 "${INSTALL_DIR}/credentials.txt"

# ====== CRÉATION DU SCRIPT DE VÉRIFICATION ======
log_info "Création du script de vérification..."
cat > "${INSTALL_DIR}/check-postal.sh" <<'CHECK'
#!/bin/bash
echo "=== Vérification de l'état de Postal ==="
echo ""
echo "État des conteneurs:"
docker compose ps
echo ""
echo "Santé des services:"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"
echo ""
echo "Logs récents (erreurs uniquement):"
docker compose logs --tail=20 2>&1 | grep -i error || echo "Aucune erreur récente"
echo ""
echo "Test de connexion SMTP:"
nc -zv localhost 25 2>&1
nc -zv localhost 587 2>&1
echo ""
echo "Test de connexion Web:"
curl -sI https://${DOMAIN} | head -n1
CHECK

chmod +x "${INSTALL_DIR}/check-postal.sh"

# ====== VÉRIFICATION FINALE ======
log_info "Vérification de l'installation..."
sleep 10

# Vérifier que tous les conteneurs sont en cours d'exécution
if docker compose ps | grep -q "Exit\|Restarting"; then
    log_warning "Certains conteneurs ont des problèmes. Vérification des logs..."
    docker compose logs --tail=50
else
    log_success "Tous les conteneurs sont en cours d'exécution"
fi

# ====== AFFICHAGE DES INFORMATIONS FINALES ======
echo ""
echo "========================================="
echo -e "${GREEN}INSTALLATION TERMINÉE AVEC SUCCÈS!${NC}"
echo "========================================="
echo ""
echo -e "${BLUE}Accès au panneau d'administration:${NC}"
echo "URL: https://${DOMAIN}"
echo "Email: ${ADMIN_EMAIL}"
echo "Mot de passe: ${ADMIN_PASS}"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "1. Les informations de connexion sont sauvegardées dans:"
echo "   ${INSTALL_DIR}/credentials.txt"
echo ""
echo "2. Configurez les enregistrements DNS suivants:"
echo "   - A: ${DOMAIN} -> ${HOST_IP}"
echo "   - A: ${SMTP_HOSTNAME} -> ${HOST_IP}"
echo "   - A: ${RETURN_PATH_DOMAIN} -> ${HOST_IP}"
echo "   - A: ${TRACK_DOMAIN} -> ${HOST_IP}"
echo "   - MX: ${DOMAIN} -> 10 ${SMTP_HOSTNAME}"
echo "   - TXT (SPF): v=spf1 ip4:${HOST_IP} ~all"
echo ""
echo "3. Pour vérifier l'état de Postal:"
echo "   ${INSTALL_DIR}/check-postal.sh"
echo ""
echo "4. Pour voir les logs:"
echo "   cd ${INSTALL_DIR} && docker compose logs -f"
echo ""
echo "========================================="