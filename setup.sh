#!/bin/bash

# Script variables
GITREPO="https://github.com/dittos/ttrss-mirror"
VERSION="17.4"

PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"



# version=1.12

# clear

# Prompt the user
# echo -n "The ttrss code will be placed in a folder under $PWD. Is this okay? Y/N: "
# read -r query

# if [[ "$query" != [yY] ]]; then
#     exit 0
# fi

# echo -e "Good! Let's get started...\n"

# Test packages
echo -e "Testing if necessary packages are installed . . ."
type heroku >/dev/null 2>&1 || { echo >&2 "I require the heroku-toolbelt but it's not installed.  Aborting."; exit 1; }
type git >/dev/null 2>&1 || { echo >&2 "I require git but it's not installed.  Aborting."; exit 1; }
# type psql >/dev/null 2>&1 || { echo >&2 "I require psql but it's not installed.  Aborting."; exit 1; }

# Check if user is logged into heroku
heroku auth:token >/dev/null 2>&1
if [[ "$?" != 0 ]]; then
    echo -e "We have everything we need! Now log in with your heroku account (set one up at https://id.heroku.com/signup)"
    heroku login
fi

# App Name
echo -n "What should this app be called? (i.e. the url will look like this: appname.heroku.com ) *TIP* DO NOT NAME IT ttrss *TIP* : "
read -r APPNAME

# echo -n "$APPNAME is going to be created and git will begin tracking with heroku, rather than the repository you downloaded this from. Is this okay? Y/N: "
# read -r query

# if [[ "$query" != [yY] ]]; then
#    exit 0
# fi

# git clone $GITREPO --branch $VERSION --depth 1 src
mkdir src || exit
cd src || exit

git remote rm origin
git init
heroku apps:create "$APPNAME"
# echo "Registering application online. . ."
# sleep 10

curl -s -L "$GITREPO/archive/$VERSION.tar.gz" | tar --strip-components=1 -zx
# echo -e "\n"
# echo -n "Finished with the source code files. Right now there's no proper configuration or database to store our feeds. Let's fix that, shall we? Y/N: "
# read query
# if [ "$query" != Y ]; then
#    exit 0
# fi
heroku addons:create heroku-postgresql:hobby-dev -a "$APPNAME"
# echo -e "\nNow let's work on creating our config"
# sleep 2
cp config.php-dist config.php
# dbnick=$(heroku pg:info -a "$APPNAME" | sed 's/=== HEROKU_POSTGRESQL_//' | sed 's/_URL (DATABASE_URL)//' | sed 's/_URL//' | head -n 1)
DBINFO=$(heroku pg:credentials:url -a "$APPNAME" | head -n3 | tail -n1)
DBNAME=$(echo "$DBINFO" | sed 's/"dbname=//' | sed 's/ host=.*//g')
DBHOST=$(echo "$DBINFO" | sed 's/.*host=//g' | sed 's/ port=.*//g')
DBPORT=$(echo "$DBINFO" | sed 's/.*port=//g' | sed 's/ user=.*//g')
DBUSER=$(echo "$DBINFO" | sed 's/.*user=//g' | sed 's/ password=.*//g')
DBPASS=$(echo "$DBINFO" | sed 's/.*password=//g' | sed 's/ sslmode=.*//g')

sed -i "" "s/localhost/$DBHOST/g" config.php
sed -i "" "s/USER', "\""fox/USER', "\""$DBUSER/g" config.php
sed -i "" "s/NAME', "\""fox/NAME', "\""$DBNAME/g" config.php
sed -i "" "s/XXXXXX/$DBPASS/g" config.php
sed -i "" "s/DB_PORT', '')/DB_PORT', '$DBPORT')/g" config.php
# sed -i "" s@//define@define@g config.php
sed -i "" "s/http:\/\/example\.org\/tt-rss\//https:\/\/$APPNAME\.herokuapp\.com\//g" config.php
sed -i "" "s/SIMPLE_UPDATE_MODE', false)/SIMPLE_UPDATE_MODE', true)/g" config.php
sed -i "" "s/FORCE_ARTICLE_PURGE', 0/FORCE_ARTICLE_PURGE', 1/g" config.php
# sed -i "" "s/SESSION_CHECK_ADDRESS', 1/SESSION_CHECK_ADDRESS', 0/g" config.php

heroku pg:psql -a $APPNAME < ./schema/ttrss_schema_pgsql.sql

# echo -n "The configuration file is now completed. Check it out and edit any more options if you need to later. The database has also been created. Ready to upload to heroku? Y/N: "
# read query
# if [ "$query" != Y ]; then
#    exit 0
# fi

touch Procfile
cat <<EOF >> Procfile
web: ~/web-boot.sh
worker: while true; do php ~/update.php --feeds; sleep 300; done
EOF

touch web-boot.sh
cat <<EOF >> web-boot.sh
sed -i 's/^ServerLimit 1/ServerLimit 8/' ~/.heroku/php/etc/apache2/httpd.conf
sed -i 's/^MaxClients 1/MaxClients 8/' ~/.heroku/php/etc/apache2/httpd.conf

# vendor/bin/heroku-php-apache2
# EOF
# chmod +x web-boot.sh
# git add .
# git commit -m 'first commit'
# git push heroku master
# echo "Finished creating the ttrss server. Creating updater application"
# heroku apps:create $appname-updater
# echo "Waiting for application to register . . ."
# sleep 30
# origdburl=`heroku config --app $appname | head -n 2 | tail -n 1 | sed 's@.*postgres://@@'`
# heroku config:add DATABASE_URL=$origdburl --app $appname-updater
# git remote add $appname-updater git@heroku.com:$appname-updater.git
# echo -n "Ready to push the updater to heroku? Y/N: "
# read query
# if [ "$query" != Y ]; then
#    exit 0
# fi
# git add .
# git commit -m 'finishing updater'
# git push $appname-updater master
# sleep 5
# heroku ps:scale web=0 worker=1 --app $appname-updater
# heroku ps:scale web=0 worker=0 --app $appname
# heroku ps:scale web=1 worker=0 --app $appname

# echo "Your app is now created and you can visit it now. The username is admin and the password is password"
# echo -n "Would you like to open your default browser to view it now? Y/N: "
# read query
# if [ "$query" == Y ]; then
#    heroku open --app $appname
# fi
