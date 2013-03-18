#! /bin/sh

clear
echo -n "The ttrss code will be placed in a folder under $PWD. Is this okay?? Y/N: " 
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
wget https://github.com/gothfox/Tiny-Tiny-RSS/archive/1.7.4.tar.gz -O "1.7.4.tar.gz"
tar -xvzf "1.7.4.tar.gz"
cd Tiny-Tiny-RSS-1.7.4
mv * ../
cd ..
rm "1.7.4.tar.gz"
rm -r Tiny-Tiny-RSS-1.7.4
echo -e "\n"
echo -n "Finished with the source code files. Right now there's no proper configuration or database to store our feeds. Let's create one, shall we? Y/N: "
read query
if [ "$query" != Y ]; then
  exit 0
fi
heroku addons:add heroku-postgresql:dev
echo -e "\nNow let's work on creating our config"
sleep 2
cp config.php-dist config.php
dbnick=`heroku pg:info | sed 's/=== HEROKU_POSTGRESQL_//' | sed 's/_URL//' | head -n 1`
dbinfo=`heroku pg:credentials $dbnick | tail -n 1`
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
heroku pg:psql $dbnick < schema/ttrss_schema_pgsql.sql
echo -n "The configuration file is now completed. Check it out and edit any more options if you need to later. The database has also been created. Ready to move on? Y/N: "
read query
if [ "$query" != Y ]; then
  exit 0
fi
echo "Let's enable mpbstring for php and we'll be almost done"
wait 5
git clone https://github.com/yandod/heroku-libraries.git
cd heroku-libraries/php/mbstring
mv mbstring.so ../../../
cp example-php.ini ../../../php.ini
cd ../../../
sudo rm -r heroku-libraries
echo -n "There, now ready to upload your data to Heroku? Y/N: "
read query
if [ "$query" != Y ]; then
  exit 0
fi
git add .
git commit -m 'first commit'
git push heroku master
echo "Creating a script that will update your feeds. This will be placed in /usr/local/bin/updatrss"
touch updaterss
cat <<EOF >> updaterss
#! /bin/sh
cd $PWD/$appname
heroku run './php/bin/php -c www/php.ini ./www/update.php -feeds'
EOF
chmod +x updaterss
mv updaterss /usr/local/bin/updaterss
echo -n "The script updaterss was created. Whenever you want, you can update your feeds by running updaterss. Do you want to automate this script for every 30 minutes using a cronjob? Y/N: "
read query
if [ "$query" == Y ]; then
  crontab -l > file
  echo '*/30 * * * * /usr/local/bin/updaterss' >> file
  crontab file
else
  echo "Alright, then either run the script manually or update each feed through the online interface"
fi
echo "You're app is now created and you can visit it now. The username is admin and the password is password"
heroku open
