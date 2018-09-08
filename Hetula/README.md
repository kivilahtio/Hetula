# Hetula

Secure storage for private patron data.

## Requirements

- Ubuntu 18.04 or later
- Systemd
- MariaDB

## Installation

### Install system package dependencies

apt-get install
  - git
  - tig
  - cpanminus
  - unzip
  - build-essential
  - libssl-dev
  - libipc-system-simple-perlcpanm
  - mariadb-server

cpanm Module::Build

### Configure database

CREATE DATABASE hetula;
CREATE USER 'hetula'@'localhost' IDENTIFIED WITH unix_socket;
GRANT ALL ON hetula.* to 'hetula'@'localhost';

#### Create test database

CREATE DATABASE hetula_test;
GRANT ALL ON hetula_test.* to 'hetula'@'localhost';

### Clone Hetula

cd /home/hetula
git clone https://github.com/KohaSuomi/Hetula.git

### Build, test, install

perl ./Build.PL
./Build
sudo ./Build install

#### Follow instructions from './Build install' to configure all the configuration files

./Build test
./Build realclean

### Restart systemd service

systemctl restart hetula

Hetula is automatically enabled on boot.
It listens on port 8000.

## Using Hetula

### Swagger-UI

Easiest way to access all of Hetula's services is to use the Swagger UI to maintain the application.
Swagger-UI is available at

<hostname>/api/v1/doc/

You can login as the super admin using the admin name, password and organization from the applicable configuration file.

### Server-side scripts

Hetula has some commands to automate recurring tasks.

On the server, execute

`MOJO_MODE=testing perl script/hetula help`

to see the available commands.

#### perl hetula addOrganization

Helper to quickly configure a new organization and an admin for that organization to manage the organization's users.

#### perl hetula batchImportSsn

Migrate a bunch of ssns to Hetula and get another list where the ssn ids are.

## Adding a new organization to Hetula

### Loading a batch of ssns into Hetula

Hetula has a REST batch-endpoint for reading in a large amount of ssns quickly.

Alternatively one can use the Mojolicious command

`batchImportSsn`

## Hetula Javascript client

See ../libhetula-javascript/README.md

## Hetula development

### Database upgrades/downgrades

Hetula uses DBIx::Class::Migration to automate DB migrations.

After modifying the DBIC schema, prepare an upgrade/install/downgrade point with the command:

`dbic-migration -Ilib --schema_class Hetula::Schema --database MySQL --dsn "dbi:mysql:database=hetula;host=localhost" prepare`

Hetula automatically installs the correct DB version and configures the minimum admin-user,
when it starts for the first time and the DB access is properly configured in hetula.conf.

For more information, the DBIx::Class::Migration provides a good tutorial for managing DB changes.

