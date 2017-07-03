# Hetula
Secure storage for private patron data.

# Requirements

- Ubuntu 16.04 or later
- Systemd

# Installation

# Install system package dependencies

apt-get install
  - git
  - tig
  - cpanminus
  - build-essential
  - libssl-dev
  - libipc-system-simple-perlcpanm
  - sqlite3

cpanm Module::Build

# Clone Hetula

cd /home/hetula
git clone https://github.com/KohaSuomi/Hetula.git

# Configure environment variables

echo "HETULA_HOME=/home/hetula/Hetula/Hetula" >> /etc/environment
source /etc/environment

# Build, test, install

perl ./Build.PL
./Build
./Build test
sudo ./Build install
./Build realclean


# Configure hetula

nano /etc/hetula/hetula.conf

# Restart systemd service

systemctl restart hetula



Hetula is automatically enabled on boot.
It listens on port 8080.

