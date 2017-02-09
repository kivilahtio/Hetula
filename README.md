# Patron-Store
Secure storage for private patron data.

#h2. Installation

apt-get install
  - git
  - tig
  - cpanminus
  - build-essential
  - libssl-dev
  - libipc-system-simple-perlcpanm

cpanm Dist::Zilla

dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm

dzil install


# If you want to run tests, you need the following packages:

apt-get install sqlite3

