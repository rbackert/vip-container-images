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

# Make sure to check the core files are there before trying to install WordPress.
echo "Waiting for core files to be copied"
i=0;
while [ ! -f /wp/wp-includes/pomo/mo.php ]
do
  sleep 0.5
  i=$((i+1))
  # Roughly 1 minute
  if [ $i -eq 120 ]; then
    echo "ERROR: WordPress core files not found. Please try to restart or destroy the environment"
    exit 1;
  fi
done


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

echo "Waiting for MySQL to come online..."
second=0
while ! mysqladmin ping -h "${db_host}" --silent && [ "${second}" -lt 60 ]; do
  sleep 1
  second=$((second+1))
done
if ! mysqladmin ping -h "${db_host}" --silent; then
    echo "ERROR: mysql has failed to come online"
    exit 1;
fi

echo "Checking for database connectivity..."
if ! mysql -h "$db_host" -u wordpress -pwordpress wordpress -e "SELECT 'testing_db'" >/dev/null 2>&1; then
  echo "No WordPress database exists, provisioning..."
  echo "GRANT ALL ON *.* TO 'wordpress'@'localhost' IDENTIFIED BY 'wordpress' WITH GRANT OPTION;" | mysql -h "$db_host" -u "$db_admin_user"
  echo "GRANT ALL ON *.* TO 'wordpress'@'%' IDENTIFIED BY 'wordpress' WITH GRANT OPTION;" | mysql -h "$db_host" -u "$db_admin_user"
  echo "CREATE DATABASE wordpress;" | mysql -h "$db_host" -u "$db_admin_user"
fi

echo "Copying dev-env-plugin.php to mu-plugins"
cp /dev-tools/dev-env-plugin.php /wp/wp-content/mu-plugins/

echo "Checking for WordPress installation..."

site_exist_check_output=$(wp option get siteurl 2>&1);

site_exist_return_value=$?;
if echo "$site_exist_check_output" | grep -Eq "(Site .* not found)|(The site you have requested is not installed)"; then
  echo "No installation found, installing WordPress..."

  # Ensuring wp-config-defaults is up to date
  cp /dev-tools/wp-config-defaults.php /wp/config/

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

  if [ "$(echo "${LANDO_INFO}" | jq .elasticsearch.service)" != 'null' ] && [ "$(echo "${LANDO_INFO}" | jq .['demo-app-code.service'])" != 'null' ]; then
    wp config set VIP_ENABLE_VIP_SEARCH true --raw
    wp config set VIP_ENABLE_VIP_SEARCH_QUERY_INTEGRATION true --raw
    echo "Automatically set constants VIP_ENABLE_VIP_SEARCH and VIP_ENABLE_VIP_SEARCH_QUERY_INTEGRATION to true. For more information, see https://docs.wpvip.com/how-tos/vip-search/enable/"
    echo "To disable the Enterprise Search integration, please run:"
    if [ -n "${LANDO_APP_NAME}" ]; then
      echo "vip dev-env exec --slug ${LANDO_APP_NAME} -- wp config delete VIP_ENABLE_VIP_SEARCH"
      echo "vip dev-env exec --slug ${LANDO_APP_NAME} -- wp config delete VIP_ENABLE_VIP_SEARCH_QUERY_INTEGRATION"
    else
      echo "wp config delete VIP_ENABLE_VIP_SEARCH"
      echo "wp config delete VIP_ENABLE_VIP_SEARCH_QUERY_INTEGRATION"
    fi
  fi

  if wp cli has-command vip-search; then
    wp vip-search index --skip-confirm --setup
  fi

  wp user add-cap 1 view_query_monitor
elif [ "$site_exist_return_value" != 0 ] ; then
  echo "ERROR: Could not find out if site exists."
  echo "$site_exist_check_output"
else
  echo "WordPress already installed"
fi
