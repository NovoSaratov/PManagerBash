#!/bin/bash

# Prompt for MySQL root password
read -sp "Enter a password for MySQL root user: " ROOT_PASS
echo

# Prompt for phpMyAdmin user password
read -sp "Enter a password for phpMyAdmin user: " PHPMYADMIN_PASS
echo

# Prompt for database details
read -p "Enter the name of the new database: " DB_NAME
read -p "Enter the username for the new database: " DB_USER
read -sp "Enter the password for the new database user: " DB_PASS
echo

# Update the system
echo "Updating the system..."
sudo apt update && sudo apt upgrade -y

# Install Apache
echo "Installing Apache..."
sudo apt install apache2 -y

# Install UFW
echo "Installing UFW..."
sudo apt install ufw -y

# Configure UFW
echo "Configuring UFW to allow necessary services..."
sudo ufw allow OpenSSH
sudo ufw allow 'Apache Full'
sudo ufw enable

# Install MySQL
echo "Installing MySQL..."
sudo apt install mysql-server -y

# Configure MySQL root user password
echo "Setting MySQL root password..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$ROOT_PASS'; FLUSH PRIVILEGES;"

# Install PHP and necessary extensions
echo "Installing PHP and extensions..."
sudo apt install php libapache2-mod-php php-mysql -y

# Restart Apache to load PHP module
echo "Restarting Apache..."
sudo systemctl restart apache2

# Set up MySQL database
echo "Creating MySQL database and user..."
sudo mysql -u root -p$ROOT_PASS -e "CREATE DATABASE $DB_NAME;"
sudo mysql -u root -p$ROOT_PASS -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -u root -p$ROOT_PASS -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -u root -p$ROOT_PASS -e "FLUSH PRIVILEGES;"

# Create the entries table
echo "Creating entries table..."
sudo mysql -u root -p$ROOT_PASS $DB_NAME <<EOF
CREATE TABLE entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    website TEXT NOT NULL,
    username TEXT NOT NULL,
    password_encrypted TEXT NOT NULL
);
EOF

# Install phpMyAdmin
echo "Installing phpMyAdmin..."
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASS"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $ROOT_PASS"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASS"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt install phpmyadmin -y

# Configure phpMyAdmin with Apache
echo "Configuring phpMyAdmin with Apache..."
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Restart Apache
echo "Restarting Apache to apply changes..."
sudo systemctl restart apache2

# Get the server's IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

# Final output with dynamic IP
echo "Setup complete."
echo "Visit http://$SERVER_IP/phpmyadmin to manage the database."
echo "Log in to phpMyAdmin with username: root and password: $ROOT_PASS"