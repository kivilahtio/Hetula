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

### Configure environment variables

echo "HETULA_HOME=/home/hetula/Hetula/Hetula" >> /etc/environment
source /etc/environment

### Build, test, install

perl ./Build.PL
./Build
./Build test
sudo ./Build install
./Build realclean


### Configure hetula

nano /etc/hetula/hetula.conf

### Restart systemd service

systemctl restart hetula



Hetula is automatically enabled on boot.
It listens on port 8080.

