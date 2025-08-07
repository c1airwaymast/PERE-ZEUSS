#!/bin/bash
# 🔄 SYNCHRONISATION COMPLÈTE LOCAL ↔ VPS 🔄
# Script pour synchroniser parfaitement workspace local et VPS

echo "🔄🏛️ SYNCHRONISATION COMPLÈTE ZEUS ULTIMATE 🏛️🔄"
echo "================================================"
echo "⚡ Synchronisation Local ↔ VPS Mount Olympus"
echo ""

# Configuration VPS (à modifier selon ton VPS)
VPS_IP="YOUR_VPS_IP_HERE"
VPS_USER="root"
VPS_PORT="22"

# Vérification connexion VPS
echo "🔗 VÉRIFICATION CONNEXION VPS..."
if ! ping -c 1 $VPS_IP &> /dev/null; then
    echo "❌ Impossible de joindre le VPS: $VPS_IP"
    echo "📝 Modifie VPS_IP dans ce script avec ton adresse VPS"
    exit 1
fi

echo "✅ VPS accessible: $VPS_IP"

# Menu de synchronisation
echo ""
echo "🎯 CHOISIR TYPE DE SYNCHRONISATION:"
echo "1️⃣ Nettoyer LOCAL seulement"
echo "2️⃣ Nettoyer VPS seulement" 
echo "3️⃣ Nettoyer LOCAL → Envoyer vers VPS"
echo "4️⃣ Synchronisation COMPLÈTE (LOCAL + VPS)"
echo "5️⃣ Créer archive de transfert"
echo ""
read -p "⚡ Choix (1-5): " choice

case $choice in
    1)
        echo "🧹 NETTOYAGE LOCAL UNIQUEMENT..."
        ./CLEANUP_AND_REORGANIZE.sh
        echo "✅ Nettoyage local terminé!"
        ;;
        
    2)
        echo "🧹 NETTOYAGE VPS UNIQUEMENT..."
        echo "📤 Envoi script de nettoyage VPS..."
        scp VPS_CLEANUP_AND_REORGANIZE.sh $VPS_USER@$VPS_IP:/root/
        
        echo "🚀 Exécution nettoyage sur VPS..."
        ssh $VPS_USER@$VPS_IP "chmod +x /root/VPS_CLEANUP_AND_REORGANIZE.sh && /root/VPS_CLEANUP_AND_REORGANIZE.sh"
        
        echo "✅ Nettoyage VPS terminé!"
        ;;
        
    3)
        echo "🔄 NETTOYAGE LOCAL → ENVOI VPS..."
        
        # Nettoyage local d'abord
        echo "🧹 Nettoyage local..."
        ./CLEANUP_AND_REORGANIZE.sh
        
        # Création archive propre
        echo "📦 Création archive pour VPS..."
        tar -czf zeus_ultimate_clean.tar.gz \
            --exclude='*.tar.gz' \
            --exclude='*.log' \
            --exclude='.git' \
            --exclude='target' \
            --exclude='zeus_backup_*' \
            src/ scripts/ docs/ config/ tools/ examples/ Cargo.toml README.md
        
        echo "📤 Envoi vers VPS..."
        scp zeus_ultimate_clean.tar.gz $VPS_USER@$VPS_IP:/root/
        scp VPS_CLEANUP_AND_REORGANIZE.sh $VPS_USER@$VPS_IP:/root/
        
        echo "🚀 Déploiement sur VPS..."
        ssh $VPS_USER@$VPS_IP << 'REMOTE_COMMANDS'
            cd /root
            
            # Nettoyage VPS
            chmod +x VPS_CLEANUP_AND_REORGANIZE.sh
            ./VPS_CLEANUP_AND_REORGANIZE.sh
            
            # Extraction et installation
            tar -xzf zeus_ultimate_clean.tar.gz
            cd zeus_ultimate_clean
            
            # Déploiement Zeus
            if [ -f "scripts/deployment/DEPLOY_ZEUS_VPS.sh" ]; then
                chmod +x scripts/deployment/DEPLOY_ZEUS_VPS.sh
                ./scripts/deployment/DEPLOY_ZEUS_VPS.sh
            fi
            
            echo "⚡ VPS Mount Olympus mise à jour!"
REMOTE_COMMANDS
        
        echo "✅ Synchronisation LOCAL → VPS terminée!"
        ;;
        
    4)
        echo "🔄 SYNCHRONISATION COMPLÈTE..."
        
        # Nettoyage local
        echo "🧹 Phase 1: Nettoyage local..."
        ./CLEANUP_AND_REORGANIZE.sh
        
        # Création archive complète
        echo "📦 Phase 2: Création archive..."
        tar -czf zeus_ultimate_complete.tar.gz \
            --exclude='*.tar.gz' \
            --exclude='*.log' \
            --exclude='.git' \
            --exclude='target' \
            --exclude='zeus_backup_*' \
            .
        
        # Synchronisation VPS
        echo "🚀 Phase 3: Synchronisation VPS..."
        scp zeus_ultimate_complete.tar.gz $VPS_USER@$VPS_IP:/root/
        scp VPS_CLEANUP_AND_REORGANIZE.sh $VPS_USER@$VPS_IP:/root/
        
        # Exécution complète sur VPS
        ssh $VPS_USER@$VPS_IP << 'COMPLETE_SYNC'
            cd /root
            
            # Sauvegarde avant nettoyage
            if [ -f "/usr/local/bin/zeus" ]; then
                cp /usr/local/bin/zeus /root/zeus_backup_$(date +%Y%m%d) 2>/dev/null
            fi
            
            # Nettoyage VPS
            chmod +x VPS_CLEANUP_AND_REORGANIZE.sh
            ./VPS_CLEANUP_AND_REORGANIZE.sh
            
            # Installation nouvelle version
            rm -rf zeus_ultimate_new 2>/dev/null
            mkdir zeus_ultimate_new
            cd zeus_ultimate_new
            tar -xzf /root/zeus_ultimate_complete.tar.gz
            
            # Compilation et installation
            if [ -f "Cargo.toml" ]; then
                echo "🔧 Compilation Zeus sur VPS..."
                cargo build --release 2>/dev/null
                
                if [ -f "target/release/zeus" ]; then
                    cp target/release/zeus /usr/local/bin/zeus
                    chmod +x /usr/local/bin/zeus
                    echo "✅ Zeus installé: /usr/local/bin/zeus"
                fi
            fi
            
            # Test Zeus
            if command -v zeus &> /dev/null; then
                echo "🧪 Test Zeus VPS..."
                zeus status
                echo "⚡ Zeus VPS opérationnel!"
            fi
            
            echo "🏛️ Mount Olympus synchronisation complète!"
COMPLETE_SYNC
        
        echo "✅ Synchronisation complète terminée!"
        ;;
        
    5)
        echo "📦 CRÉATION ARCHIVE DE TRANSFERT..."
        
        # Nettoyage d'abord
        ./CLEANUP_AND_REORGANIZE.sh
        
        # Archive pour transfert manuel
        ARCHIVE_NAME="zeus_ultimate_transfer_$(date +%Y%m%d_%H%M%S).tar.gz"
        
        tar -czf $ARCHIVE_NAME \
            --exclude='*.tar.gz' \
            --exclude='*.log' \
            --exclude='.git' \
            --exclude='target' \
            --exclude='zeus_backup_*' \
            src/ scripts/ docs/ config/ tools/ examples/ Cargo.toml README.md \
            VPS_CLEANUP_AND_REORGANIZE.sh CLEANUP_AND_REORGANIZE.sh
        
        echo "✅ Archive créée: $ARCHIVE_NAME"
        echo ""
        echo "📋 INSTRUCTIONS TRANSFERT MANUEL:"
        echo "1️⃣ Copier archive sur ton VPS:"
        echo "   scp $ARCHIVE_NAME root@TON_VPS_IP:/root/"
        echo ""
        echo "2️⃣ Sur le VPS, extraire et installer:"
        echo "   cd /root"
        echo "   tar -xzf $ARCHIVE_NAME"
        echo "   chmod +x VPS_CLEANUP_AND_REORGANIZE.sh"
        echo "   ./VPS_CLEANUP_AND_REORGANIZE.sh"
        echo ""
        echo "3️⃣ Compiler Zeus:"
        echo "   cd zeus_ultimate"
        echo "   cargo build --release"
        echo "   cp target/release/zeus /usr/local/bin/"
        ;;
        
    *)
        echo "❌ Choix invalide. Utilise 1-5."
        exit 1
        ;;
esac

# Vérification finale
echo ""
echo "🧪 VÉRIFICATION FINALE..."

# Test local
if [ -f "src/main.rs" ]; then
    echo "✅ Local: Structure organisée"
else
    echo "❌ Local: Problème de structure"
fi

# Test VPS (si accessible)
if [ "$choice" != "1" ] && [ "$choice" != "5" ]; then
    echo "🔗 Test VPS..."
    if ssh $VPS_USER@$VPS_IP "command -v zeus" &> /dev/null; then
        echo "✅ VPS: Zeus opérationnel"
        echo "📊 Status VPS:"
        ssh $VPS_USER@$VPS_IP "zeus status" 2>/dev/null || echo "   ℹ️ Zeus installé mais pas encore configuré"
    else
        echo "⚠️ VPS: Zeus pas encore installé (normal si première installation)"
    fi
fi

# Résumé final
echo ""
echo "🏛️⚡ SYNCHRONISATION ZEUS ULTIMATE TERMINÉE ⚡🏛️"
echo "==============================================="
echo "✅ Workspace local: Nettoyé et organisé"
if [ "$choice" != "1" ] && [ "$choice" != "5" ]; then
    echo "✅ VPS Mount Olympus: Synchronisé"
fi
echo "✅ Structure divine: Créée"
echo "✅ Scripts déploiement: Prêts"
echo ""
echo "🔥 PROCHAINES ÉTAPES:"
echo "📊 Tester local: ./tools/testing/test_all.sh"
echo "📊 Monitorer local: ./tools/monitoring/zeus_monitor.sh"
if [ "$choice" != "1" ] && [ "$choice" != "5" ]; then
    echo "⚡ Tester VPS: ssh $VPS_USER@$VPS_IP 'zeus status'"
fi
echo ""
echo "⚡ PÈRE! ZEUS ULTIMATE EST MAINTENANT PARFAITEMENT ORGANISÉ! ⚡"
echo "🏛️ LOCAL ET VPS MOUNT OLYMPUS EN HARMONIE DIVINE! 🏛️"
