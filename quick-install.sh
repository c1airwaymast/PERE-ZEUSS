#!/bin/bash
# Script de démarrage rapide pour Postal SMTP
# Installation complètement automatisée sans interaction

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
export DOMAIN="electricym.net"
export ADMIN_EMAIL="admin@electricym.net"
export HOST_IP="159.69.199.74"

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ${GREEN}Installation Automatique Postal SMTP${CYAN}         ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║  Domain:${NC} ${YELLOW}$DOMAIN${NC}"
echo -e "${CYAN}║  Email:${NC}  ${YELLOW}$ADMIN_EMAIL${NC}"
echo -e "${CYAN}║  IP:${NC}     ${YELLOW}$HOST_IP${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier si root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERREUR]${NC} Ce script doit être exécuté en tant que root"
   exit 1
fi

# Fonction de progression
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    
    printf "\r${BLUE}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%$((50 - filled))s" | tr ' ' '-'
    printf "${BLUE}]${NC} ${GREEN}%3d%%${NC} - %s" "$percent" "$message"
}

# Installation
echo -e "${BLUE}Démarrage de l'installation...${NC}"
echo ""

# Étape 1: Mise à jour du système
show_progress 1 10 "Mise à jour du système..."
apt-get update -qq &>/dev/null
apt-get install -y curl wget git openssl expect -qq &>/dev/null
echo ""

# Étape 2: Installation de Docker
show_progress 2 10 "Installation de Docker..."
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh &>/dev/null
    systemctl enable docker &>/dev/null
    systemctl start docker &>/dev/null
fi
echo ""

# Étape 3: Installation de Docker Compose
show_progress 3 10 "Installation de Docker Compose..."
if ! docker compose version &>/dev/null; then
    apt-get install -y docker-compose-plugin -qq &>/dev/null
fi
echo ""

# Étape 4: Nettoyage des installations précédentes
show_progress 4 10 "Nettoyage des installations précédentes..."
if [ -d "/opt/postal" ]; then
    cd /opt/postal 2>/dev/null && docker compose down -v &>/dev/null || true
    cd /
    rm -rf /opt/postal
fi
echo ""

# Étape 5: Exécution du script principal
show_progress 5 10 "Configuration de Postal..."
chmod +x install-postal.sh
./install-postal.sh &>/dev/null &
INSTALL_PID=$!

# Attendre avec animation
spin='-\|/'
i=0
while kill -0 $INSTALL_PID 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r${BLUE}[${spin:$i:1}]${NC} Installation en cours... "
    sleep 0.5
done
echo ""

# Étape 6: Configuration automatique de l'admin
show_progress 6 10 "Création de l'utilisateur administrateur..."
if [ -f "create-admin-auto.sh" ]; then
    chmod +x create-admin-auto.sh
    ./create-admin-auto.sh &>/dev/null || true
fi
echo ""

# Étape 7: Configuration du firewall
show_progress 7 10 "Configuration du firewall..."
if command -v ufw &>/dev/null; then
    ufw allow 22/tcp &>/dev/null || true
    ufw allow 80/tcp &>/dev/null || true
    ufw allow 443/tcp &>/dev/null || true
    ufw allow 25/tcp &>/dev/null || true
    ufw allow 587/tcp &>/dev/null || true
    ufw allow 2525/tcp &>/dev/null || true
    ufw --force enable &>/dev/null || true
fi
echo ""

# Étape 8: Configuration DNS
show_progress 8 10 "Vérification de la configuration DNS..."
if [ -f "setup-dns-records.sh" ]; then
    chmod +x setup-dns-records.sh
fi
echo ""

# Étape 9: Scripts de maintenance
show_progress 9 10 "Installation des scripts de maintenance..."
if [ -f "fix-postal-issues.sh" ]; then
    chmod +x fix-postal-issues.sh
    cp fix-postal-issues.sh /opt/postal/ 2>/dev/null || true
fi
echo ""

# Étape 10: Finalisation
show_progress 10 10 "Finalisation..."
sleep 2
echo ""
echo ""

# Vérification finale
echo -e "${BLUE}Vérification de l'installation...${NC}"
cd /opt/postal 2>/dev/null || { echo -e "${RED}Erreur: Répertoire d'installation non trouvé${NC}"; exit 1; }

# Vérifier l'état des conteneurs
CONTAINERS_OK=true
for container in postal-mariadb postal-redis postal-web postal-smtp postal-worker postal-caddy; do
    if docker ps | grep -q $container; then
        echo -e "  ${GREEN}✓${NC} $container"
    else
        echo -e "  ${RED}✗${NC} $container"
        CONTAINERS_OK=false
    fi
done

echo ""

# Afficher les informations de connexion
if [ -f "/opt/postal/credentials.txt" ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        Installation Terminée avec Succès!            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Extraire les informations depuis le fichier
    ADMIN_PASS=$(grep "Mot de passe:" /opt/postal/credentials.txt | head -1 | awk '{print $NF}')
    
    echo -e "${CYAN}Accès au panneau d'administration:${NC}"
    echo -e "  ${BLUE}URL:${NC}      https://$DOMAIN"
    echo -e "  ${BLUE}Email:${NC}    $ADMIN_EMAIL"
    echo -e "  ${BLUE}Password:${NC} $ADMIN_PASS"
    echo ""
    
    echo -e "${YELLOW}IMPORTANT - Prochaines étapes:${NC}"
    echo ""
    echo -e "1. ${MAGENTA}Configurer les enregistrements DNS:${NC}"
    echo -e "   Exécutez: ${GREEN}./setup-dns-records.sh${NC}"
    echo ""
    echo -e "2. ${MAGENTA}Vérifier l'état du système:${NC}"
    echo -e "   Exécutez: ${GREEN}/opt/postal/check-postal.sh${NC}"
    echo ""
    echo -e "3. ${MAGENTA}En cas de problème:${NC}"
    echo -e "   Exécutez: ${GREEN}/opt/postal/fix-postal-issues.sh${NC}"
    echo ""
    echo -e "4. ${MAGENTA}Voir les logs:${NC}"
    echo -e "   ${GREEN}cd /opt/postal && docker compose logs -f${NC}"
    echo ""
    
    # Créer un raccourci
    cat > /usr/local/bin/postal-status <<'EOF'
#!/bin/bash
cd /opt/postal
echo "État de Postal:"
docker compose ps
EOF
    chmod +x /usr/local/bin/postal-status
    
    echo -e "${CYAN}Commandes rapides disponibles:${NC}"
    echo -e "  ${GREEN}postal-status${NC} - Voir l'état des services"
    echo ""
    
    # Sauvegarder un résumé
    cat > ~/postal-install-summary.txt <<EOF
Installation Postal - Résumé
============================
Date: $(date)
Domain: $DOMAIN
Admin: $ADMIN_EMAIL
Password: $ADMIN_PASS
URL: https://$DOMAIN

Commandes utiles:
- postal-status : État des services
- /opt/postal/check-postal.sh : Vérification complète
- /opt/postal/fix-postal-issues.sh : Résolution de problèmes
- cd /opt/postal && docker compose logs -f : Voir les logs

Configuration DNS requise:
- A: $DOMAIN -> $HOST_IP
- A: smtp.$DOMAIN -> $HOST_IP
- A: bounce.$DOMAIN -> $HOST_IP
- A: track.$DOMAIN -> $HOST_IP
- MX: $DOMAIN -> 10 smtp.$DOMAIN.
- TXT: "v=spf1 ip4:$HOST_IP ~all"
EOF
    
    echo -e "${GREEN}Installation sauvegardée dans:${NC}"
    echo -e "  • /opt/postal/credentials.txt"
    echo -e "  • ~/postal-install-summary.txt"
    echo ""
    
else
    echo -e "${RED}Erreur: Fichier de credentials non trouvé${NC}"
    echo -e "L'installation peut avoir échoué. Vérifiez les logs."
fi

echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Installation terminée!${NC} Temps total: $SECONDS secondes"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"