#!/usr/bin/env bash
# GS Atelier — bootstrap WordPress + WooCommerce on Ubuntu (OCI)
# Target: VM.Standard.E2.1.Micro (1 GB RAM) with swap
set -euo pipefail

DOMAIN="${DOMAIN:-gsatelier.com.br}"
WP_TITLE="${WP_TITLE:-GS Atelier}"
WP_ADMIN_USER="${WP_ADMIN_USER:-gsadmin}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-contato@gsatelier.com.br}"
# Passwords: set via env or auto-generated
WP_ADMIN_PASS="${WP_ADMIN_PASS:-}"
DB_NAME="${DB_NAME:-gsatelier}"
DB_USER="${DB_USER:-gsatelier}"
DB_PASS="${DB_PASS:-}"
SWAP_GB="${SWAP_GB:-2}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Rode como root: sudo bash $0"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "==> [1/8] Swap ${SWAP_GB}G"
if ! swapon --show | grep -q '/swapfile'; then
  fallocate -l "${SWAP_GB}G" /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=$((SWAP_GB * 1024))
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  # Prefer RAM; use swap before OOM
  sysctl vm.swappiness=20
  grep -q 'vm.swappiness' /etc/sysctl.conf || echo 'vm.swappiness=20' >> /etc/sysctl.conf
fi
free -h

echo "==> [2/8] Pacotes base"
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  nginx mysql-server \
  php-fpm php-mysql php-xml php-curl php-mbstring php-zip php-gd php-imagick php-intl \
  unzip curl ca-certificates ufw fail2ban

# Detect PHP-FPM socket
PHP_SOCK="$(ls /var/run/php/php*-fpm.sock 2>/dev/null | head -n1 || true)"
if [[ -z "${PHP_SOCK}" ]]; then
  echo "PHP-FPM socket não encontrado"; exit 1
fi
PHP_VER="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"

echo "==> [3/8] Endurecer PHP-FPM para 1GB RAM"
PHP_INI="/etc/php/${PHP_VER}/fpm/pool.d/www.conf"
sed -i 's/^;*\s*pm\s*=.*/pm = ondemand/' "$PHP_INI"
sed -i 's/^;*\s*pm.max_children\s*=.*/pm.max_children = 3/' "$PHP_INI"
sed -i 's/^;*\s*pm.process_idle_timeout\s*=.*/pm.process_idle_timeout = 10s/' "$PHP_INI"
sed -i 's/^;*\s*pm.max_requests\s*=.*/pm.max_requests = 100/' "$PHP_INI"
# memory
PHP_FPM_INI="/etc/php/${PHP_VER}/fpm/php.ini"
sed -i 's/^memory_limit\s*=.*/memory_limit = 128M/' "$PHP_FPM_INI"
sed -i 's/^upload_max_filesize\s*=.*/upload_max_filesize = 32M/' "$PHP_FPM_INI"
sed -i 's/^post_max_size\s*=.*/post_max_size = 32M/' "$PHP_FPM_INI"
systemctl restart "php${PHP_VER}-fpm"

echo "==> [4/8] MySQL database"
if [[ -z "${DB_PASS}" ]]; then
  DB_PASS="$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-20)"
fi
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

# Reduce MySQL footprint
cat >/etc/mysql/conf.d/gsatelier-lowmem.cnf <<EOF
[mysqld]
innodb_buffer_pool_size=64M
performance_schema=OFF
max_connections=30
tmp_table_size=16M
max_heap_table_size=16M
EOF
systemctl restart mysql

echo "==> [5/8] WordPress core"
mkdir -p /var/www/gsatelier
cd /tmp
curl -fsSL https://wordpress.org/latest.tar.gz -o wordpress.tar.gz
tar -xzf wordpress.tar.gz
rsync -a wordpress/ /var/www/gsatelier/
chown -R www-data:www-data /var/www/gsatelier

if [[ -z "${WP_ADMIN_PASS}" ]]; then
  WP_ADMIN_PASS="$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-20)"
fi

# wp-cli
if ! command -v wp >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
  chmod +x /usr/local/bin/wp
fi

sudo -u www-data wp config create \
  --path=/var/www/gsatelier \
  --dbname="${DB_NAME}" \
  --dbuser="${DB_USER}" \
  --dbpass="${DB_PASS}" \
  --dbhost=localhost \
  --skip-check

sudo -u www-data wp core install \
  --path=/var/www/gsatelier \
  --url="http://${DOMAIN}" \
  --title="${WP_TITLE}" \
  --admin_user="${WP_ADMIN_USER}" \
  --admin_password="${WP_ADMIN_PASS}" \
  --admin_email="${WP_ADMIN_EMAIL}" \
  --skip-email

echo "==> [6/8] WooCommerce + ajustes"
sudo -u www-data wp plugin install woocommerce --activate --path=/var/www/gsatelier
sudo -u www-data wp language core install pt_BR --path=/var/www/gsatelier || true
sudo -u www-data wp site switch-language pt_BR --path=/var/www/gsatelier || true
sudo -u www-data wp rewrite structure '/%postname%/' --path=/var/www/gsatelier
sudo -u www-data wp option update blogdescription 'Camisas exclusivas' --path=/var/www/gsatelier
sudo -u www-data wp option update woocommerce_default_country 'BR:SP' --path=/var/www/gsatelier || true
sudo -u www-data wp option update woocommerce_currency 'BRL' --path=/var/www/gsatelier || true

echo "==> [7/8] Nginx"
cat >/etc/nginx/sites-available/gsatelier <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN};
    root /var/www/gsatelier;
    index index.php;

    client_max_body_size 32M;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }

    location ~* /\. {
        deny all;
    }
}
EOF
ln -sfn /etc/nginx/sites-available/gsatelier /etc/nginx/sites-enabled/gsatelier
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "==> [8/8] Firewall"
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable || true
systemctl enable --now fail2ban

CREDS="/root/gsatelier-credentials.txt"
cat >"$CREDS" <<EOF
GS Atelier — WordPress credentials
=================================
Site URL:      http://${DOMAIN}
Admin:         http://${DOMAIN}/wp-admin
User:          ${WP_ADMIN_USER}
Pass:          ${WP_ADMIN_PASS}
Email:         ${WP_ADMIN_EMAIL}

DB name:       ${DB_NAME}
DB user:       ${DB_USER}
DB pass:       ${DB_PASS}

Swap:          ${SWAP_GB}G
Next:
1) No OCI Security List / NSG: liberar TCP 22, 80, 443
2) DNS A de ${DOMAIN} e www -> IP público desta VM
3) Instalar SSL: apt install -y certbot python3-certbot-nginx && certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}
4) Configurar WooCommerce (Pix via Mercado Pago / PagBank)
EOF
chmod 600 "$CREDS"

echo
echo "OK. Credenciais em ${CREDS}"
cat "$CREDS"
