#!/bin/bash

echo "make sure you run with sudo else the installation will fail"!
echo "Enter the domain name: "
read domain
echo "Enter django project name: "
read project_name
domain_path=$( echo ${domain} | tr '.' '_' )

sudo apt update
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
sudo apt install -y apache2 python3-pip python3-venv
sudo apt-get install libapache2-mod-wsgi-py3
sudo a2enmod wsgi
sudo a2enmod ssl
sudo service apache2 stop
mkdir /home/ubuntu/public_html

mkdir /home/ubuntu/public_html/$domain_path
python3 -m venv /home/ubuntu/public_html/$domain_path/venv
/home/ubuntu/public_html/$domain_path/venv/bin/python3 -m pip install django
/home/ubuntu/public_html/$domain_path/venv/bin/python3 -m django startproject $project_name /home/ubuntu/public_html/$domain_path/.

echo "
import os
ALLOWED_HOSTS = ['${domain}', 'www.${domain}']
STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'static/')
MEDIA_URL = 'media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media/')
STATICFILES=[STATIC_ROOT, MEDIA_ROOT]" >> /home/ubuntu/public_html/$domain_path/$project_name/settings.py

/home/ubuntu/public_html/$domain_path/venv/bin/python3 /home/ubuntu/public_html/$domain_path/manage.py makemigrations
/home/ubuntu/public_html/$domain_path/venv/bin/python3 /home/ubuntu/public_html/$domain_path/manage.py migrate
/home/ubuntu/public_html/$domain_path/venv/bin/python3 /home/ubuntu/public_html/$domain_path/manage.py collectstatic

sudo chmod -R 755 /home/ubuntu
sudo chown :www-data /home/ubuntu/public_html/$domain_path/db.sqlite3
sudo chown :www-data /home/ubuntu/public_html/$domain_path
sudo chown :www-data /home/ubuntu/public_html/$domain_path/$project_name
sudo chown -R ubuntu:ubuntu /home/ubuntu/public_html/

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
    <Directory /home/ubuntu/public_html/$domain_path/$project_name>
        <Files wsgi.py>
            Require all granted
        </Files>
    </Directory>
    WSGIPassAuthorization On
    WSGIDaemonProcess $domain_path python-path=/home/ubuntu/public_html/$domain_path/ python-home=/home/ubuntu/public_html/$domain_path/venv
    WSGIProcessGroup $domain_path
    WSGIScriptAlias / /home/ubuntu/public_html/$domain_path/$project_name/wsgi.py
</VirtualHost>" >> /etc/apache2/sites-available/$domain_path.conf
sudo a2ensite $domain_path.conf

echo "<VirtualHost *:443>
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
    <Directory /home/ubuntu/public_html/$domain_path/$project_name>
        <Files wsgi.py>
            Require all granted
        </Files>
    </Directory>
    WSGIPassAuthorization On
    WSGIDaemonProcess ssl_$domain_path python-path=/home/ubuntu/public_html/$domain_path/ python-home=/home/ubuntu/public_html/$domain_path/venv
    WSGIProcessGroup $domain_path
    WSGIScriptAlias / /home/ubuntu/public_html/$domain_path/$project_name/wsgi.py
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
</VirtualHost>" >> /etc/apache2/sites-available/ssl_$domain_path.conf
sudo a2ensite ssl_$domain_path.conf

sudo service apache2 restart
echo "Site Created"
