#!/bin/bash
# Script de diagnostic et résolution des problèmes Postal

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/opt/postal"

echo -e "${BLUE}=== Diagnostic et Résolution des Problèmes Postal ===${NC}"
echo ""

# Fonction pour vérifier et corriger les permissions
fix_permissions() {
    echo -e "${YELLOW}Correction des permissions...${NC}"
    chown -R 999:999 $INSTALL_DIR/data/mariadb 2>/dev/null || true
    chown -R 999:999 $INSTALL_DIR/data/redis 2>/dev/null || true
    chmod -R 755 $INSTALL_DIR/config
    chmod 600 $INSTALL_DIR/config/signing.key 2>/dev/null || true
    echo -e "${GREEN}Permissions corrigées${NC}"
}

# Fonction pour nettoyer et redémarrer les conteneurs
restart_containers() {
    echo -e "${YELLOW}Redémarrage des conteneurs...${NC}"
    cd $INSTALL_DIR
    docker compose down
    docker compose up -d
    sleep 10
    docker compose ps
}

# Fonction pour réinitialiser la base de données
reset_database() {
    echo -e "${RED}ATTENTION: Ceci va réinitialiser complètement la base de données!${NC}"
    read -p "Êtes-vous sûr? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd $INSTALL_DIR
        docker compose down -v
        rm -rf data/mariadb/*
        docker compose up -d mariadb redis
        sleep 20
        docker compose up -d
        sleep 10
        docker compose run --rm postal-web postal initialize
        echo -e "${GREEN}Base de données réinitialisée${NC}"
    fi
}

# Fonction pour vérifier la connectivité réseau
check_network() {
    echo -e "${BLUE}Vérification de la connectivité réseau...${NC}"
    
    # Vérifier les ports
    for port in 25 80 443 587 2525; do
        if nc -zv localhost $port 2>&1 | grep -q succeeded; then
            echo -e "${GREEN}Port $port: OK${NC}"
        else
            echo -e "${RED}Port $port: FERMÉ${NC}"
        fi
    done
    
    # Vérifier la résolution DNS
    echo ""
    echo "Résolution DNS:"
    for domain in electricym.net smtp.electricym.net; do
        if host $domain &>/dev/null; then
            echo -e "${GREEN}$domain: OK${NC}"
        else
            echo -e "${RED}$domain: ÉCHEC${NC}"
        fi
    done
}

# Fonction pour vérifier les logs
check_logs() {
    echo -e "${BLUE}Dernières erreurs dans les logs:${NC}"
    cd $INSTALL_DIR
    docker compose logs --tail=50 2>&1 | grep -i error | tail -10 || echo "Aucune erreur récente"
}

# Fonction pour nettoyer les vieux logs
clean_logs() {
    echo -e "${YELLOW}Nettoyage des logs...${NC}"
    find $INSTALL_DIR/logs -type f -name "*.log" -mtime +7 -delete 2>/dev/null || true
    docker system prune -f
    echo -e "${GREEN}Logs nettoyés${NC}"
}

# Fonction pour mettre à jour Postal
update_postal() {
    echo -e "${BLUE}Mise à jour de Postal...${NC}"
    cd $INSTALL_DIR
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}Postal mis à jour${NC}"
}

# Fonction pour régénérer les certificats SSL
regenerate_ssl() {
    echo -e "${YELLOW}Régénération des certificats SSL...${NC}"
    cd $INSTALL_DIR
    rm -rf caddy/data/caddy/certificates
    docker compose restart caddy
    echo -e "${GREEN}Certificats SSL régénérés${NC}"
}

# Fonction pour vérifier l'état de santé
health_check() {
    echo -e "${BLUE}=== État de Santé du Système ===${NC}"
    echo ""
    
    # Vérifier l'espace disque
    echo "Espace disque:"
    df -h / | tail -1
    echo ""
    
    # Vérifier la mémoire
    echo "Mémoire:"
    free -h | grep Mem
    echo ""
    
    # Vérifier les conteneurs
    echo "État des conteneurs:"
    cd $INSTALL_DIR
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"
    echo ""
    
    # Vérifier les processus
    echo "Charge système:"
    uptime
}

# Menu principal
while true; do
    echo ""
    echo -e "${BLUE}=== Menu de Diagnostic Postal ===${NC}"
    echo "1. Vérifier l'état de santé"
    echo "2. Corriger les permissions"
    echo "3. Redémarrer les conteneurs"
    echo "4. Vérifier la connectivité réseau"
    echo "5. Afficher les dernières erreurs"
    echo "6. Nettoyer les logs"
    echo "7. Mettre à jour Postal"
    echo "8. Régénérer les certificats SSL"
    echo "9. Réinitialiser la base de données (DANGER)"
    echo "0. Quitter"
    echo ""
    read -p "Choisissez une option: " choice
    
    case $choice in
        1) health_check ;;
        2) fix_permissions ;;
        3) restart_containers ;;
        4) check_network ;;
        5) check_logs ;;
        6) clean_logs ;;
        7) update_postal ;;
        8) regenerate_ssl ;;
        9) reset_database ;;
        0) echo "Au revoir!"; exit 0 ;;
        *) echo -e "${RED}Option invalide${NC}" ;;
    esac
    
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
done