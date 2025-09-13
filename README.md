# Installation Automatique Postal SMTP

Suite de scripts pour installer automatiquement Postal SMTP sur votre serveur sans aucune interaction manuelle.

## 🚀 Installation Rapide

```bash
# Donner les permissions d'exécution
chmod +x quick-install.sh

# Lancer l'installation complète
sudo ./quick-install.sh
```

## 📁 Scripts Disponibles

### 1. `quick-install.sh` (RECOMMANDÉ)
Script principal d'installation rapide et automatique.
- Installation complète en une seule commande
- Aucune interaction requise
- Configuration automatique de tous les composants

### 2. `install-postal.sh`
Script d'installation détaillé avec plus d'options.
- Installation étape par étape
- Messages détaillés de progression
- Personnalisation possible des paramètres

### 3. `create-admin-auto.sh`
Création automatique de l'utilisateur administrateur.
- Génération automatique du mot de passe
- Aucune interaction manuelle

### 4. `setup-dns-records.sh`
Configuration et vérification des enregistrements DNS.
- Affiche tous les enregistrements DNS requis
- Vérifie la configuration actuelle
- Détecte les problèmes de configuration

### 5. `fix-postal-issues.sh`
Outil de diagnostic et résolution de problèmes.
- Menu interactif de dépannage
- Correction automatique des problèmes courants
- Vérification de l'état du système

## 📋 Prérequis

- **OS**: Ubuntu 20.04/22.04 ou Debian 11/12
- **RAM**: Minimum 2GB (4GB recommandé)
- **Stockage**: Minimum 20GB
- **Accès**: Root ou sudo
- **Ports**: 25, 80, 443, 587, 2525

## 🔧 Configuration

Les scripts utilisent les paramètres suivants (modifiables dans les scripts) :

```bash
DOMAIN="electricym.net"
ADMIN_EMAIL="admin@electricym.net"
HOST_IP="159.69.199.74"
```

## 📝 Configuration DNS Requise

Après l'installation, configurez ces enregistrements DNS :

### Enregistrements A
```
electricym.net              -> 159.69.199.74
smtp.electricym.net        -> 159.69.199.74
bounce.electricym.net      -> 159.69.199.74
track.electricym.net       -> 159.69.199.74
```

### Enregistrement MX
```
electricym.net              -> 10 smtp.electricym.net.
```

### Enregistrement SPF
```
electricym.net              -> "v=spf1 ip4:159.69.199.74 ~all"
```

### Enregistrement DMARC (Recommandé)
```
_dmarc.electricym.net      -> "v=DMARC1; p=quarantine; rua=mailto:admin@electricym.net"
```

### Enregistrement PTR (Reverse DNS)
```
159.69.199.74              -> smtp.electricym.net.
```
*Note: Le PTR doit être configuré par votre hébergeur*

## 🚦 Vérification Post-Installation

### Vérifier l'état des services
```bash
cd /opt/postal
docker compose ps
```

### Vérifier les logs
```bash
cd /opt/postal
docker compose logs -f
```

### Tester la configuration DNS
```bash
./setup-dns-records.sh
```

### Résoudre les problèmes
```bash
/opt/postal/fix-postal-issues.sh
```

## 🔐 Accès au Panneau d'Administration

Après l'installation, accédez à Postal via :
- **URL**: https://electricym.net
- **Email**: admin@electricym.net
- **Mot de passe**: Généré automatiquement (voir `/opt/postal/credentials.txt`)

## 📊 Structure des Fichiers

```
/opt/postal/
├── config/
│   ├── postal.yml          # Configuration principale
│   └── signing.key         # Clé de signature DKIM
├── data/
│   ├── mariadb/           # Base de données
│   └── redis/             # Cache Redis
├── caddy/
│   ├── Caddyfile          # Configuration reverse proxy
│   └── data/              # Certificats SSL
├── logs/                   # Logs de l'application
├── docker-compose.yml      # Configuration Docker
├── credentials.txt         # Informations de connexion
└── check-postal.sh        # Script de vérification

```

## 🛠️ Maintenance

### Mise à jour de Postal
```bash
cd /opt/postal
docker compose pull
docker compose up -d
```

### Sauvegarde
```bash
cd /opt/postal
docker compose stop
tar -czf postal-backup-$(date +%Y%m%d).tar.gz config/ data/
docker compose start
```

### Redémarrage des services
```bash
cd /opt/postal
docker compose restart
```

## ⚠️ Dépannage

### Les conteneurs ne démarrent pas
```bash
# Vérifier les logs
docker compose logs mariadb
docker compose logs postal-web

# Redémarrer tout
docker compose down
docker compose up -d
```

### Problèmes de certificat SSL
```bash
cd /opt/postal
rm -rf caddy/data/caddy/certificates
docker compose restart caddy
```

### Base de données corrompue
```bash
/opt/postal/fix-postal-issues.sh
# Choisir l'option 9 (réinitialisation)
```

## 📧 Test d'Envoi

Après configuration complète :

1. Connectez-vous au panneau Postal
2. Créez une organisation
3. Créez un serveur de messagerie
4. Générez des credentials API/SMTP
5. Configurez votre application :
   ```
   SMTP Host: smtp.electricym.net
   Port: 587 (STARTTLS) ou 465 (SSL)
   Username: [créé dans Postal]
   Password: [créé dans Postal]
   ```

## 🔄 Désinstallation

Pour supprimer complètement Postal :

```bash
cd /opt/postal
docker compose down -v
cd /
rm -rf /opt/postal
```

## 📞 Support

En cas de problème :
1. Consultez les logs : `docker compose logs -f`
2. Utilisez le script de diagnostic : `./fix-postal-issues.sh`
3. Vérifiez la configuration DNS : `./setup-dns-records.sh`

## 📄 Licence

Ces scripts sont fournis "tels quels" pour faciliter l'installation de Postal.
Postal est sous licence MIT : https://github.com/postalserver/postal

## 🙏 Crédits

- Postal Server : https://github.com/postalserver/postal
- Docker : https://www.docker.com/
- Caddy : https://caddyserver.com/