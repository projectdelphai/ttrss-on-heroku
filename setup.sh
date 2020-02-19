#!/bin/bash

# Script variables
GITREPO="https://github.com/dittos/ttrss-mirror"
VERSION="17.4"

PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"

# Test packages
echo -e "Testing if necessary packages are installed . . ."
type heroku >/dev/null 2>&1 || { echo >&2 "I require the heroku-toolbelt but it's not installed.  Aborting."; exit 1; }
type git >/dev/null 2>&1 || { echo >&2 "I require git but it's not installed.  Aborting."; exit 1; }
type psql >/dev/null 2>&1 || { echo >&2 "I require psql but it's not installed.  Aborting."; exit 1; }

# Check if user is logged into heroku
heroku auth:token >/dev/null 2>&1
if [[ "$?" != 0 ]]; then
    echo -e "We have everything we need! Now log in with your heroku account (set one up at https://id.heroku.com/signup)"
    heroku login
fi

# App Name
echo -n "What should this app be called? (i.e. the url will look like this: appname.heroku.com ) *TIP* DO NOT NAME IT ttrss *TIP* : "
read -r APPNAME

cd "src" || exit

git init -q
heroku apps:create "$APPNAME"

curl -s -L "$GITREPO/archive/$VERSION.tar.gz" | tar --strip-components=1 -zx

heroku addons:create heroku-postgresql:hobby-dev -a "$APPNAME"

cp config.php-dist config.php
DBINFO=$(heroku pg:credentials:url -a "$APPNAME" | head -n3 | tail -n1)
DBNAME=$(echo "$DBINFO" | sed 's/.*dbname=//' | sed 's/ host=.*//g')
DBHOST=$(echo "$DBINFO" | sed 's/.*host=//g' | sed 's/ port=.*//g')
DBPORT=$(echo "$DBINFO" | sed 's/.*port=//g' | sed 's/ user=.*//g')
DBUSER=$(echo "$DBINFO" | sed 's/.*user=//g' | sed 's/ password=.*//g')
DBPASS=$(echo "$DBINFO" | sed 's/.*password=//g' | sed 's/ sslmode=.*//g')

sed -i "" "s/localhost/$DBHOST/g" config.php
sed -i "" "s/USER', "\""fox/USER', "\""$DBUSER/g" config.php
sed -i "" "s/NAME', "\""fox/NAME', "\""$DBNAME/g" config.php
sed -i "" "s/XXXXXX/$DBPASS/g" config.php
sed -i "" "s/DB_PORT', '')/DB_PORT', '$DBPORT')/g" config.php
sed -i "" "s/http:\/\/example\.org\/tt-rss\//https:\/\/$APPNAME\.herokuapp\.com\//g" config.php
sed -i "" "s/SIMPLE_UPDATE_MODE', false)/SIMPLE_UPDATE_MODE', true)/g" config.php
sed -i "" "s/FORCE_ARTICLE_PURGE', 0/FORCE_ARTICLE_PURGE', 1/g" config.php

heroku pg:psql -a $APPNAME < ./schema/ttrss_schema_pgsql.sql >/dev/null

touch Procfile
cat <<EOF >> Procfile
web: ~/web-boot.sh
worker: while true; do php ~/update.php --feeds; sleep 300; done
EOF

touch web-boot.sh
cat <<EOF >> web-boot.sh
sed -i 's/^ServerLimit 1/ServerLimit 8/' ~/.heroku/php/etc/apache2/httpd.conf
sed -i 's/^MaxClients 1/MaxClients 8/' ~/.heroku/php/etc/apache2/httpd.conf

vendor/bin/heroku-php-apache2
EOF

chmod +x web-boot.sh
git add . >/dev/null
git commit --quiet -m "Initial commit."
git push --quiet heroku master

echo "Finished creating the ttrss server. Creating updater application"

heroku apps:create $APPNAME-updater

ORIGDBURL=$(heroku config -a $APPNAME | head -n 2 | tail -n 1 | sed 's@.*postgres://@@')

heroku config:add DATABASE_URL="$ORIGDBURL" -a "$APPNAME"-updater

git remote add "$APPNAME-updater" "https://git.heroku.com/$APPNAME-updater.git"
git add . >/dev/null
git commit --quiet -m 'Finishing updater.'
git push --quiet "$APPNAME-updater" master

heroku ps:scale web=0 worker=1 -a "$APPNAME-updater"
heroku ps:scale web=0 worker=0 -a "$APPNAME"
heroku ps:scale web=1 worker=0 -a "$APPNAME"

heroku open --app "$APPNAME"
