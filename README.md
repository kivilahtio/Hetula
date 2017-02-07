# Patron-Store
Secure storage for private patron data.

apt-get install cpanm
cpanm Dist::Zilla

dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm

dzil install


# If you want to run tests, you need the following packages:

apt-get install sqlite3

