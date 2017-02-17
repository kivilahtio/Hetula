# Hetula
Secure storage for private patron data.

#h2. Installation

apt-get install
  - git
  - tig
  - cpanminus
  - build-essential
  - libssl-dev
  - libipc-system-simple-perlcpanm
  - sqlite3

cpanm Dist::Zilla

dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm

dzil install


