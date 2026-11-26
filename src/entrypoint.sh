#!/bin/sh
# FreshRSS's official entrypoint needs root (timezone symlink, sed on /etc,
# chown, Apache pid under /var/run, cron). TOS forbids root containers, so run
# the unmodified app with a private, writable copy of the Apache configuration
# as uid 1000 on port 8080, and perform the data-directory preparation the
# official entrypoint does with `cli/prepare.php`.
set -u

cd /var/www/FreshRSS

# The official entrypoint runs `./cli/prepare.php` before Apache (as root).
# Skipping it leaves data/favicons, data/tokens, data/cache, data/PubSubHubbub
# and data/users missing: the first-run page then emits "touch(): Unable to
# create file ..." warnings, the web installer cannot create the administrator,
# favicons are never cached and the API (token store) stays broken. The script
# only creates directories and files owned by the application user, so uid 1000
# can run it; a failure is loud in the container log but never blocks Apache.
# (`cli/access-permissions.sh` is deliberately NOT called: it refuses to run
# without root, and there is nothing to chown when we run as the data owner.)
if ! php -f ./cli/prepare.php >/dev/null; then
	echo "WARN: cli/prepare.php failed - data directories may be incomplete" >&2
fi

rm -rf /tmp/apache2
mkdir -p /tmp/apache2
cp -aL /etc/apache2/. /tmp/apache2/ 2>/dev/null || true

# The upstream ports.conf has Listen commented out and the vhost is *:80.
grep -q '^Listen 8080' /tmp/apache2/ports.conf || printf '\nListen 8080\n' >> /tmp/apache2/ports.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8080>/' /tmp/apache2/sites-enabled/FreshRSS.Apache.conf 2>/dev/null || true
sed -i 's|/var/run/apache2|/tmp/apache2|g; s|/var/lock/apache2|/tmp/apache2|g; s|/var/log/apache2|/tmp/apache2|g' /tmp/apache2/envvars

export APACHE_CONFDIR=/tmp/apache2
export APACHE_ENVVARS=/tmp/apache2/envvars
. /tmp/apache2/envvars
export APACHE_RUN_DIR=/tmp/apache2
export APACHE_LOCK_DIR=/tmp/apache2
export APACHE_LOG_DIR=/tmp/apache2
export APACHE_PID_FILE=/tmp/apache2/apache2.pid
mkdir -p "$APACHE_RUN_DIR"

exec apache2 -d /tmp/apache2 -f /tmp/apache2/apache2.conf -D FOREGROUND
