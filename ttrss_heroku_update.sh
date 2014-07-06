echo -n "In which folder is your heroku installation hosted?: "
read folder
echo "Updating self"
sleep 3
/usr/bin/php update.php --update_self
echo "Recreating custom folders and files"
sleep 2
cd "../$folder"
old_folder=`find ../ -maxdepth 1 | grep old`
localuser=`whoami`
sudo mv $old_folder/.git ./
mv $old_folder/Procfile ./
mv $old_folder/composer.json ./
mv $old_folder/php.ini ./
mv $old_folder/web-boot.sh ./
sudo chown -R $localuser:users .git
echo "Creating new config file using old values"
cp config.php-dist config.php
echo -n "What is the name of your heroku app?: "
read app
dbnick=`heroku pg:info --app $app | sed 's/=== HEROKU_POSTGRESQL_//' | sed 's/_URL (DATABASE_URL)//' | sed 's/_URL//' | head -n 1`
dbinfo=`heroku pg:credentials $dbnick --app $app | head -n 2 | tail -n 1`
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
sed -i s@http://example.org/tt-rss/@https://$appname.herokuapp.com/@g config.php
sed -i "s/DB_PORT', '')/DB_PORT', '5432')/g" config.php
sed -i "s/SIMPLE_UPDATE_MODE', false)/SIMPLE_UPDATE_MODE', true)/g" config.php
sed -i "s/FORCE_ARTICLE_PURGE', 0/FORCE_ARTICLE_PURGE', 1/g" config.php
sed -i "s/SESSION_CHECK_ADDRESS', 1/SESSION_CHECK_ADDRESS', 0/g" config.php
echo -n "Ready to upload to Heroku? Y/N: "
read query
if [ "$query" != Y ]; then 
  exit 0
fi
git add -A
git commit -m 'upgraded ttrss version'
git push heroku master
echo -n "Ready to upload updater to Heroku? Y/N: "
read query
if [ "$query" != Y ]; then
  exit 0
fi
git push $app-updater master
echo "Removing old folder"
sudo rm -r $old_folder
