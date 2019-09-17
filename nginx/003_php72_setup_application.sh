#!/bin/bash

# Exit if a statement returns a non-true value
set -o errexit
# Exit when using undeclared variables
set -o nounset

# get application path
echo "What is the name for the new application? (this will be used for the .sock file)"
read application_name

if [ $application_name == "" ]; then
	echo "Unable to continue without an application name."
	echo "Done."
	exit 1;
fi

# home_directory="$(eval echo ~${NON_ROOT_USERNAME})"
echo "What is the full path to the public directory? (eg. /home/<user>/${application_name}/public_html)"
read public_path

if [ $public_path == "" ]; then
	echo "Unable to continue without a public path."
	echo "Done."
	exit 1;
fi

hostname="$(eval echo hostname)"
echo "What is the domain (or server) name? eg. ${hostname}"
read server_name

if [ $server_name == "" ]; then
	echo "Unable to continue without a server name."
	echo "Done."
	exit 1;
fi

echo "Enter the username of the application owner. (Non-root, but sudo user required)"
read RUN_AS_USERNAME

if [ $RUN_AS_USERNAME == "" ]; then
	echo "Unable to continue without a username."
	echo "Done."
	exit 1;
fi

# ***************************************************************
# PHP Application setup
# ***************************************************************

# Fix php.ini config for Laravel
sudo sed --in-place "s@\;cgi.fix_pathinfo=1@cgi.fix_pathinfo=0@g" /etc/php/7.2/fpm/php.ini

# create application configuration
sudo cp /etc/php/7.2/fpm/pool.d/www.conf /etc/php/7.2/fpm/pool.d/${application_name}.conf

# change the vars
sudo sed --in-place "s@\[www\]@[${application_name}]@g" /etc/php/7.2/fpm/pool.d/${application_name}.conf
sudo sed --in-place "s^user = www-data$^user = ${RUN_AS_USERNAME}^" /etc/php/7.2/fpm/pool.d/${application_name}.conf
sudo sed --in-place "s^group = www-data$^group = ${RUN_AS_USERNAME}^" /etc/php/7.2/fpm/pool.d/${application_name}.conf

sudo sed --in-place "s@listen = /run/php/php7.2-fpm.sock@listen = /var/run/php7.2-fpm-${application_name}.sock@g" /etc/php/7.2/fpm/pool.d/${application_name}.conf


# ***************************************************************
# NGINX Application setup
# ***************************************************************

# Download the file if it doesn't exist
# wget https://raw.githubusercontent.com/shanecp/setup-scripts/master/nginx/001_nginx_default.conf

# create nginx configuration
sudo cp `pwd`/001_nginx_default.conf /etc/nginx/sites-available/${application_name}.conf
sudo sed --in-place "s@PUBLIC_PATH@${public_path}@g" /etc/nginx/sites-available/${application_name}.conf
sudo sed --in-place "s@SERVER_NAME@${server_name}@g" /etc/nginx/sites-available/${application_name}.conf

sudo sed --in-place "s@SOCK_FILE_PATH@/var/run/php7.2-fpm-${application_name}.sock@g" /etc/nginx/sites-available/${application_name}.conf

# Remove the default symlink
DEFAULT_NGINX_CONF=/etc/nginx/sites-enabled/default
if test -f "$DEFAULT_NGINX_CONF"; then
	sudo rm /etc/nginx/sites-enabled/default
fi

# create new symlink
sudo ln -s /etc/nginx/sites-available/${application_name}.conf /etc/nginx/sites-enabled/${application_name}.conf

echo "PHP config file created at /etc/php/7.2/fpm/pool.d/${application_name}.conf"
echo "Nginx config file created at /etc/nginx/sites-available/${application_name}.conf"
echo "Check the above files."

echo "Starting config tests..."

sudo php-fpm7.2 -t
sudo nginx -t

echo "Running as the user 'master'. For security, create a non-sudo user and run as that user"
echo "Restart php with `sudo service php7.2-fpm restart`"
echo "Restart nginx with `sudo service nginx reload`"
echo "Done."
