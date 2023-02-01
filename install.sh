#!/bin/bash

echo "Enter the domain name: "
read domain
domain_path=$( echo ${domain} | tr '.' '_' )

sudo apt update
sudo apt install -y apache2 letsencrypt python3-pip python3-venv python3-virtualenv python3-certbot-apache
sudo apt-get install libapache2-mod-wsgi-py3
sudo a2enmod wsgi
sudo service apache2 stop
mkdir /home/ubuntu/public_html

mkdir /home/ubuntu/public_html/$domain_path
cd /home/ubuntu/public_html/$domain_path
virtualenv /home/ubuntu/public_html/$domain_path/venv
/home/ubuntu/public_html/$domain_path/venv/bin/python3 -m pip install django
/home/ubuntu/public_html/$domain_path/venv/bin/python3 -m django startproject mysite 
mv /home/ubuntu/public_html/$domain_path/mysite /home/ubuntu/public_html/$domain_path/test
mv -v /home/ubuntu/public_html/$domain_path/test/* /home/ubuntu/public_html/$domain_path/
sudo rm -R /home/ubuntu/public_html/$domain_path/test

# Add the following code to settings.py
# sudo nano mysite/settings.py
# import os
# STATIC_ROOT = os.path.join(BASE_DIR, "static/") 
# STATICFILES=[STATIC_ROOT]

echo "
import os
ALLOWED_HOSTS = ['${domain}', 'www.${domain}']
STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'static/')
MEDIA_URL = 'media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media/')
STATICFILES=[STATIC_ROOT, MEDIA_ROOT]" >> /home/ubuntu/public_html/$domain_path/mysite/settings.py

/home/ubuntu/public_html/$domain_path/venv/bin/python3 /home/ubuntu/public_html/$domain_path/manage.py makemigrations
/home/ubuntu/public_html/$domain_path/venv/bin/python3 /home/ubuntu/public_html/$domain_path/manage.py migrate
/home/ubuntu/public_html/$domain_path/venv/bin/python3 /home/ubuntu/public_html/$domain_path/manage.py collectstatic
deactivate

sudo chmod 755 /home/ubuntu
sudo chmod 777 /home/ubuntu
sudo chmod 750 /home/ubuntu/public_html/$domain_path
sudo chown :www-data /home/ubuntu/public_html/$domain_path/db.sqlite3
sudo chown :www-data /home/ubuntu/public_html/$domain_path
sudo chown :www-data /home/ubuntu/public_html/$domain_path/mysite

cd /etc/apache2/sites-available

# paste the following config
echo "<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    Alias /static /home/ubuntu/public_html/$domain_path/static
    <Directory /home/ubuntu/public_html/$domain_path/static>
        Require all granted
    </Directory>
    Alias /media /home/ubuntu/public_html/$domain_path/media
    <Directory /home/ubuntu/public_html/$domain_path/media>
        Require all granted
    </Directory>
    <Directory /home/ubuntu/public_html/$domain_path/mysite>
        <Files wsgi.py>
            Require all granted
        </Files>
    </Directory>
    WSGIPassAuthorization On
    WSGIDaemonProcess $domain_path python-path=/home/ubuntu/public_html/$domain_path/ python-home=/home/ubuntu/public_html/$domain_path/venv
    WSGIProcessGroup $domain_path
    WSGIScriptAlias / /home/ubuntu/public_html/$domain_path/mysite/wsgi.py
</VirtualHost>" >> $domain_path.conf
sudo a2ensite $domain_path.conf
sudo service apache2 restart
echo "Site Created"
