#!/bin/bash
# Script pour créer automatiquement l'utilisateur admin Postal sans interaction

set -e

# Configuration
ADMIN_EMAIL="${1:-admin@electricym.net}"
ADMIN_PASS="${2:-$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)}"
CONTAINER="postal-web"

echo "Création automatique de l'utilisateur admin..."
echo "Email: $ADMIN_EMAIL"

# Méthode 1: Via expect (si disponible)
if command -v expect &> /dev/null; then
    expect -c "
    spawn docker exec -it $CONTAINER postal make-user
    expect \"Email:\"
    send \"$ADMIN_EMAIL\r\"
    expect \"Password:\"
    send \"$ADMIN_PASS\r\"
    expect \"Confirm Password:\"
    send \"$ADMIN_PASS\r\"
    expect \"First Name:\"
    send \"Admin\r\"
    expect \"Last Name:\"
    send \"User\r\"
    expect \"admin user?\"
    send \"y\r\"
    expect eof
    " 2>/dev/null && echo "Utilisateur créé avec succès!" && exit 0
fi

# Méthode 2: Via Rails console directement
docker exec $CONTAINER bash -c "
cd /opt/postal && rails runner \"
begin
  user = User.find_by(email: '$ADMIN_EMAIL')
  if user
    user.update!(
      password: '$ADMIN_PASS',
      password_confirmation: '$ADMIN_PASS',
      admin: true
    )
    puts 'Utilisateur mis à jour avec succès'
  else
    User.create!(
      email: '$ADMIN_EMAIL',
      password: '$ADMIN_PASS',
      password_confirmation: '$ADMIN_PASS',
      first_name: 'Admin',
      last_name: 'User',
      admin: true
    )
    puts 'Utilisateur créé avec succès'
  end
rescue => e
  puts \\\"Erreur: #{e.message}\\\"
  exit 1
end
\" 2>/dev/null
" || {
    # Méthode 3: Via input piped
    echo "Tentative alternative..."
    {
        echo "$ADMIN_EMAIL"
        echo "$ADMIN_PASS"
        echo "$ADMIN_PASS"
        echo "Admin"
        echo "User"
        echo "y"
    } | docker exec -i $CONTAINER postal make-user 2>/dev/null
}

echo ""
echo "================================"
echo "Utilisateur admin configuré:"
echo "Email: $ADMIN_EMAIL"
echo "Mot de passe: $ADMIN_PASS"
echo "================================"