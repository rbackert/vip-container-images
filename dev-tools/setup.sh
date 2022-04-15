#!/bin/sh

if [ $# -lt 4 ]; then
  echo: "Syntax: setup.sh <db_host> <db_admin_user> <wp_domain> <wp_title> [<multisite_domain>]"
  exit 1
fi

db_host=$1
db_admin_user=$2
wp_url=$3
wp_title=$4
multisite_domain=$5

# Force-set owner to www-data otherwise we may run in to the permissions trouble during the initial start.
# It manifests as 'Warning: require(/wp/wp-includes/pomo/mo.php): failed to open stream: No such file or directory'
# Due to wp-includes being owned by root at the moment of script execution
# It doesn't happen often and hard to reproduce
chown --silent www-data -R /wp

if [ -r /wp/config/wp-config.php ]; then
  echo "Already existing wp-config.php file"
else
  cp /dev-tools/wp-config-defaults.php /wp/config/
  sed -e "s/%DB_HOST%/$db_host/" /dev-tools/wp-config.php.tpl > /wp/config/wp-config.php
  if [ -n "$multisite_domain" ]; then
    sed -e "s/%DOMAIN%/$multisite_domain/" /dev-tools/wp-config-multisite.php.tpl >> /wp/config/wp-config.php
  fi
  curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /wp/config/wp-config.php
fi

echo "Checking for database connectivity..."
if ! mysql -h "$db_host" -u wordpress -pwordpress wordpress -e "SELECT 'testing_db'" >/dev/null 2>&1; then
  echo "No WordPress database exists, provisioning..."
  echo "GRANT ALL ON *.* TO 'wordpress'@'localhost' IDENTIFIED BY 'wordpress' WITH GRANT OPTION;" | mysql -h "$db_host" -u root
  echo "GRANT ALL ON *.* TO 'wordpress'@'%' IDENTIFIED BY 'wordpress' WITH GRANT OPTION;" | mysql -h "$db_host" -u "$db_admin_user"
  echo "CREATE DATABASE wordpress;" | mysql -h "$db_host" -u "$db_admin_user"
fi

echo "Copying dev-env-plugin.php to mu-plugins"
cp /dev-tools/dev-env-plugin.php /wp/wp-content/mu-plugins/

echo "Checking for WordPress installation..."

if ! wp option get siteurl 2>/dev/null; then
  echo "No installation found, installing WordPress..."
  if [ -n "$multisite_domain" ]; then
    wp core multisite-install \
      --path=/wp \
      --url="$wp_url" \
      --title="$wp_title" \
      --admin_user="vipgo" \
      --admin_email="vip@localhost.local" \
      --admin_password="password" \
      --skip-email \
      --skip-plugins \
      --subdomains \
      --skip-config #2>/dev/null
  else
    wp core install \
      --path=/wp \
      --url="$wp_url" \
      --title="$wp_title" \
      --admin_user="vipgo" \
      --admin_email="vip@localhost.local" \
      --admin_password="password" \
      --skip-email \
      --skip-plugins #2>/dev/null
  fi

  if wp cli has-command elasticpress; then
    wp elasticpress index --yes --setup
  fi

  wp user add-cap 1 view_query_monitor
fi
