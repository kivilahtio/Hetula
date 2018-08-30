################
#### Hetula ####
################

Secure storage for private patron data.

### Requirements ###

- Ubuntu 18.04 or later
- Systemd
- MariaDB

### Installation ###

### Install system package dependencies ###

apt-get install
  - git
  - tig
  - cpanminus
  - build-essential
  - libssl-dev
  - libipc-system-simple-perlcpanm
  - mariadb-server

cpanm Module::Build

### Configure database ###

CREATE DATABASE hetula;
CREATE USER 'hetula'@'localhost' IDENTIFIED WITH unix_socket;
GRANT ALL ON hetula.* to 'hetula'@'localhost';

# Create test database

CREATE DATABASE hetula_test;
GRANT ALL ON hetula_test.* to 'hetula'@'localhost';

### Clone Hetula

cd /home/hetula
git clone https://github.com/KohaSuomi/Hetula.git

### Build, test, install

perl ./Build.PL
./Build
sudo ./Build install

# Follow instructions from './Build install' to configure all the configuration files

./Build test
./Build realclean

### Restart systemd service

systemctl restart hetula

Hetula is automatically enabled on boot.
It listens on port 8000.

### Using Hetula

## Swagger-UI

Easiest way to access all of Hetula's services is to use the Swagger UI to maintain the application.
Swagger-UI is available at

<hostname>/api/v1/doc/

You can login as the super admin using the admin name, password and organization from the applicable configuration file.

## Hetula Javascript client

See ../libhetula-javascript/README.md
