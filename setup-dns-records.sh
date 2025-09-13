#!/bin/bash
# Script pour afficher et vérifier la configuration DNS pour Postal

set -e

# Configuration
DOMAIN="electricym.net"
HOST_IP="159.69.199.74"
ADMIN_EMAIL="admin@electricym.net"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Sous-domaines
SMTP_HOSTNAME="smtp.${DOMAIN}"
RETURN_PATH_DOMAIN="bounce.${DOMAIN}"
TRACK_DOMAIN="track.${DOMAIN}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Configuration DNS pour Postal${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Fonction pour vérifier un enregistrement A
check_a_record() {
    local domain=$1
    local expected_ip=$2
    
    echo -n "Vérification A record pour $domain... "
    actual_ip=$(dig +short A $domain 2>/dev/null | head -1)
    
    if [ "$actual_ip" = "$expected_ip" ]; then
        echo -e "${GREEN}OK${NC} ($actual_ip)"
        return 0
    elif [ -z "$actual_ip" ]; then
        echo -e "${RED}NON CONFIGURÉ${NC}"
        return 1
    else
        echo -e "${YELLOW}INCORRECT${NC} (actuel: $actual_ip, attendu: $expected_ip)"
        return 1
    fi
}

# Fonction pour vérifier un enregistrement MX
check_mx_record() {
    local domain=$1
    local expected_mx=$2
    
    echo -n "Vérification MX record pour $domain... "
    actual_mx=$(dig +short MX $domain 2>/dev/null | awk '{print $2}' | sed 's/\.$//' | head -1)
    
    if [[ "$actual_mx" == *"$expected_mx"* ]]; then
        echo -e "${GREEN}OK${NC} ($actual_mx)"
        return 0
    elif [ -z "$actual_mx" ]; then
        echo -e "${RED}NON CONFIGURÉ${NC}"
        return 1
    else
        echo -e "${YELLOW}INCORRECT${NC} (actuel: $actual_mx, attendu: $expected_mx)"
        return 1
    fi
}

# Fonction pour vérifier un enregistrement TXT/SPF
check_spf_record() {
    local domain=$1
    
    echo -n "Vérification SPF record pour $domain... "
    spf_record=$(dig +short TXT $domain 2>/dev/null | grep "v=spf1" | head -1)
    
    if [[ "$spf_record" == *"ip4:$HOST_IP"* ]]; then
        echo -e "${GREEN}OK${NC}"
        return 0
    elif [ -z "$spf_record" ]; then
        echo -e "${RED}NON CONFIGURÉ${NC}"
        return 1
    else
        echo -e "${YELLOW}INCOMPLET${NC} (actuel: $spf_record)"
        return 1
    fi
}

# Fonction pour vérifier DMARC
check_dmarc_record() {
    local domain=$1
    
    echo -n "Vérification DMARC record pour _dmarc.$domain... "
    dmarc_record=$(dig +short TXT _dmarc.$domain 2>/dev/null | grep "v=DMARC1" | head -1)
    
    if [ -n "$dmarc_record" ]; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${YELLOW}NON CONFIGURÉ${NC} (optionnel mais recommandé)"
        return 1
    fi
}

# Fonction pour vérifier le PTR (reverse DNS)
check_ptr_record() {
    local ip=$1
    
    echo -n "Vérification PTR record pour $ip... "
    ptr_record=$(dig +short -x $ip 2>/dev/null | sed 's/\.$//' | head -1)
    
    if [[ "$ptr_record" == "$SMTP_HOSTNAME" ]]; then
        echo -e "${GREEN}OK${NC} ($ptr_record)"
        return 0
    elif [ -z "$ptr_record" ]; then
        echo -e "${RED}NON CONFIGURÉ${NC} (contactez votre hébergeur)"
        return 1
    else
        echo -e "${YELLOW}INCORRECT${NC} (actuel: $ptr_record, attendu: $SMTP_HOSTNAME)"
        return 1
    fi
}

# Récupérer la clé DKIM depuis Postal (si disponible)
get_dkim_key() {
    if [ -f /opt/postal/config/signing.key ]; then
        echo -e "${BLUE}Clé DKIM détectée${NC}"
        # Extraire la clé publique
        openssl rsa -in /opt/postal/config/signing.key -pubout 2>/dev/null | \
            grep -v "PUBLIC KEY" | tr -d '\n' | fold -w 200
    fi
}

echo -e "${YELLOW}=== Configuration DNS Requise ===${NC}"
echo ""
echo "Ajoutez les enregistrements DNS suivants dans votre zone DNS:"
echo ""

echo -e "${BLUE}1. Enregistrements A:${NC}"
echo "   $DOMAIN                  IN A     $HOST_IP"
echo "   $SMTP_HOSTNAME           IN A     $HOST_IP"
echo "   $RETURN_PATH_DOMAIN      IN A     $HOST_IP"
echo "   $TRACK_DOMAIN            IN A     $HOST_IP"
echo ""

echo -e "${BLUE}2. Enregistrement MX:${NC}"
echo "   $DOMAIN                  IN MX    10 $SMTP_HOSTNAME."
echo ""

echo -e "${BLUE}3. Enregistrement SPF:${NC}"
echo "   $DOMAIN                  IN TXT   \"v=spf1 ip4:$HOST_IP ~all\""
echo ""

echo -e "${BLUE}4. Enregistrement DMARC (recommandé):${NC}"
echo "   _dmarc.$DOMAIN           IN TXT   \"v=DMARC1; p=quarantine; rua=mailto:$ADMIN_EMAIL; ruf=mailto:$ADMIN_EMAIL; fo=1\""
echo ""

echo -e "${BLUE}5. Enregistrement PTR (Reverse DNS):${NC}"
echo "   $HOST_IP                 IN PTR   $SMTP_HOSTNAME."
echo "   ${YELLOW}Note: Cet enregistrement doit être configuré par votre hébergeur${NC}"
echo ""

# Afficher la clé DKIM si disponible
DKIM_KEY=$(get_dkim_key)
if [ -n "$DKIM_KEY" ]; then
    echo -e "${BLUE}6. Enregistrement DKIM:${NC}"
    echo "   postal._domainkey.$DOMAIN IN TXT \"v=DKIM1; k=rsa; p=$DKIM_KEY\""
    echo ""
fi

echo -e "${YELLOW}=== Vérification des Enregistrements DNS ===${NC}"
echo ""

# Vérifier les enregistrements
errors=0

# Vérifier les A records
for domain in $DOMAIN $SMTP_HOSTNAME $RETURN_PATH_DOMAIN $TRACK_DOMAIN; do
    check_a_record $domain $HOST_IP || ((errors++))
done

echo ""

# Vérifier MX
check_mx_record $DOMAIN $SMTP_HOSTNAME || ((errors++))

echo ""

# Vérifier SPF
check_spf_record $DOMAIN || ((errors++))

echo ""

# Vérifier DMARC
check_dmarc_record $DOMAIN || true  # Optionnel

echo ""

# Vérifier PTR
check_ptr_record $HOST_IP || true  # Peut nécessiter une action de l'hébergeur

echo ""

if [ $errors -eq 0 ]; then
    echo -e "${GREEN}✓ Tous les enregistrements DNS requis sont correctement configurés!${NC}"
else
    echo -e "${YELLOW}⚠ $errors enregistrement(s) DNS nécessite(nt) une configuration${NC}"
    echo ""
    echo -e "${BLUE}Instructions:${NC}"
    echo "1. Connectez-vous à votre panneau de contrôle DNS"
    echo "2. Ajoutez ou corrigez les enregistrements manquants ci-dessus"
    echo "3. Attendez la propagation DNS (peut prendre jusqu'à 48h)"
    echo "4. Relancez ce script pour vérifier à nouveau"
fi

echo ""
echo -e "${BLUE}=== Test d'Envoi d'Email ===${NC}"
echo ""
echo "Pour tester l'envoi d'emails après la configuration DNS:"
echo "1. Connectez-vous à https://$DOMAIN"
echo "2. Créez une organisation et un serveur de messagerie"
echo "3. Configurez les credentials SMTP dans votre application"
echo ""
echo "Exemple de configuration SMTP:"
echo "  Serveur: $SMTP_HOSTNAME"
echo "  Port: 587 (STARTTLS) ou 465 (SSL/TLS)"
echo "  Authentification: Oui"
echo "  Username: [créé dans Postal]"
echo "  Password: [créé dans Postal]"
echo ""

# Créer un fichier de configuration pour référence
cat > /tmp/postal-dns-config.txt <<EOF
Configuration DNS pour Postal - $DOMAIN
========================================
Date: $(date)

Enregistrements A:
$DOMAIN -> $HOST_IP
$SMTP_HOSTNAME -> $HOST_IP
$RETURN_PATH_DOMAIN -> $HOST_IP
$TRACK_DOMAIN -> $HOST_IP

Enregistrement MX:
$DOMAIN -> 10 $SMTP_HOSTNAME.

Enregistrement SPF:
$DOMAIN -> "v=spf1 ip4:$HOST_IP ~all"

Enregistrement DMARC:
_dmarc.$DOMAIN -> "v=DMARC1; p=quarantine; rua=mailto:$ADMIN_EMAIL"

Enregistrement PTR:
$HOST_IP -> $SMTP_HOSTNAME.

${DKIM_KEY:+Enregistrement DKIM:
postal._domainkey.$DOMAIN -> "v=DKIM1; k=rsa; p=$DKIM_KEY"}
EOF

echo -e "${GREEN}Configuration sauvegardée dans: /tmp/postal-dns-config.txt${NC}"