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

# Download the file if it doesn't exist
# wget https://raw.githubusercontent.com/shanecp/setup-scripts/master/nginx/001_nginx_default.conf

# create nginx configuration
sudo cp `pwd`/001_nginx_default.conf /etc/nginx/sites-available/${application_name}.conf
sudo sed --in-place "s@PUBLIC_PATH@${public_path}@g" /etc/nginx/sites-available/${application_name}.conf
sudo sed --in-place "s@SERVER_NAME@${server_name}@g" /etc/nginx/sites-available/${application_name}.conf

sudo sed --in-place "s@SOCK_FILE_PATH@/var/run/php7.2-fpm-${application_name}.sock@g" /etc/nginx/sites-available/${application_name}.conf

# remove the default symlink
sudo rm /etc/nginx/sites-enabled/default

# create new symlink
sudo ln -s /etc/nginx/sites-available/${application_name}.conf /etc/nginx/sites-enabled/${application_name}.conf

echo "New config file created at /etc/nginx/sites-available/${application_name}.conf"
echo ""
echo "Starting Nginx test..."

sudo nginx -t

echo ""
echo "Configuration test completed. If there are no errors above, reload nginx"
echo "Done. Run `sudo service nginx reload` to restart nginx."
