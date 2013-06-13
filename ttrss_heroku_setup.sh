#! /bin/sh

clear
echo -n "The ttrss code will be placed in a folder under $PWD. Is this okay? Y/N: "
read query
if [ "$query" != Y ]; then
  exit 0
fi
echo -e "Good! Let's get started. . .\n"
echo -e "Testing if necessary packages are installed . . ."
type heroku >/dev/null 2>&1 || { echo >&2 "I require the heroku-toolbelt but it's not installed.  Aborting."; exit 1; }
type git >/dev/null 2>&1 || { echo >&2 "I require git but it's not installed.  Aborting."; exit 1; }
type git >/dev/null 2>&1 || { echo >&2 "I require git but it's not installed.  Aborting."; exit 1; }
echo -e "We have everything we need! Now log in with your heroku account (set one up at https://id.heroku.com/signup)"
heroku login
echo -n "What should this app be called? (i.e. the url will look like this: appname.heroku.com ) *TIP* DO NOT NAME IT ttrss *TIP* : "
read appname
git init
heroku create $appname
echo "Registering application online. . ."
sleep 20
wget https://github.com/gothfox/Tiny-Tiny-RSS/archive/1.8.tar.gz -O "1.8.tar.gz"
tar -xvzf "1.8.tar.gz"
cd Tiny-Tiny-RSS-1.8
mv * ../
cd ..
rm "1.8.tar.gz"
rm -r Tiny-Tiny-RSS-1.8
echo -e "\n"
echo -n "Finished with the source code files. Right now there's no proper configuration or database to store our feeds. Let's fix that, shall we? Y/N: "
read query
if [ "$query" != Y ]; then
  exit 0
fi
heroku addons:add heroku-postgresql:dev
echo -e "\nNow let's work on creating our config"
sleep 2
cp config.php-dist config.php
dbnick=`heroku pg:info | sed 's/=== HEROKU_POSTGRESQL_//' | sed 's/_URL (DATABASE_URL)//' | sed 's/_URL//' | head -n 1`
dbinfo=`heroku pg:credentials $dbnick | head -n 2 | tail -n 1`
dbname=`echo $dbinfo | sed 's/"dbname=//' | sed 's/ host=.*//g' `
dbhost=`echo $dbinfo | sed 's/.*host=//g' | sed 's/ port=.*//g'`
dbport="5432"
dbuser=`echo $dbinfo | sed 's/.*user=//g' | sed 's/ password=.*//g'`
dbpassword=`echo $dbinfo | sed 's/.*password=//g' | sed 's/ sslmode=.*//g'`
sed -i "s/localhost/$dbhost/g" config.php
sed -i "s/USER', "\""fox/USER', "\""$dbuser/g" config.php
sed -i "s/NAME', "\""fox/NAME', "\""$dbname/g" config.php
sed -i "s/XXXXXX/$dbpassword/g" config.php
sed -i s@//define@define@g config.php
sed -i s@http://yourserver/tt-rss/@https://$appname.herokuapp.com/@g config.php
sed -i "s/DB_PORT', '')/DB_PORT', '5432'/g" config.php
sed -i "s/SIMPLE_UPDATE_MODE', false)/SIMPLE_UPDATE_MODE', true)/g" config.php
sed -i "s/FORCE_ARTICLE_PURGE', 0/FORCE_ARTICLE_PURGE', 1/g" config.php
sed -i "s/SESSION_CHECK_ADDRESS', 1/SESSION_CHECK_ADDRESS', 0/g" config.php
heroku pg:psql $dbnick < schema/ttrss_schema_pgsql.sql
echo -n "The configuration file is now completed. Check it out and edit any more options if you need to later. The database has also been created. Ready to move on? Y/N: "
read query
if [ "$query" != Y ]; then
  exit 0
fi
echo "Let's enable mpbstring for php and we'll be almost done"
sleep 5
git clone https://github.com/yandod/heroku-libraries.git
cd heroku-libraries/php/mbstring
mv mbstring.so ../../../
cp example-php.ini ../../../php.ini
cd ../../../
sudo rm -r heroku-libraries
heroku config:add LD_LIBRARY_PATH=/app/php/ext:/app/apache/lib
echo -n "There, now ready to upload your data to Heroku? Y/N: "
read query
if [ "$query" != Y ]; then
  exit 0
fi
git add .
git commit -m 'first commit'
git push heroku master
echo "Finished creating the ttrss server. Creating updater application"
heroku apps:create $appname-updater
echo "Waiting for application to register . . ."
sleep 30
origdburl=`heroku config --app $appname | head -n 2 | tail -n 1 | sed 's@.*postgres://@@'`
heroku config:add DATABASE_URL=$origdburl --app $appname-updater
heroku config:add LD_LIBRARY_PATH=/app/php/ext:/app/apache/lib --app $appname-updater
touch Procfile
cat <<EOF >> Procfile
web: sh www/web-boot.sh
worker: while true; do ./php/bin/php -c www/php.ini ./www/update.php --feeds; sleep 300; done
EOF
touch web-boot.sh
cat <<EOF >> web-boot.sh
sed -i 's/^ServerLimit 1/ServerLimit 8/' /app/apache/conf/httpd.conf
sed -i 's/^MaxClients 1/MaxClients 8/' /app/apache/conf/httpd.conf

sh boot.sh
EOF
git remote add $appname-updater git@heroku.com:$appname-updater.git
git add .
git commit -m 'creating updater'
git push heroku master
git add .
git commit -m 'finishing updater'
git push $appname-updater master
sleep 5
heroku ps:scale web=0 worker=1 --app $appname-updater
heroku ps:scale web=0 worker=0 --app $appname
heroku ps:scale web=1 worker=0 --app $appname

echo "Your app is now created and you can visit it now. The username is admin and the password is password"
echo -n "Would you like to open your default browser to view it now? Y/N: "
read query
if [ "$query" == Y ]; then
heroku open --app $appname
fi
