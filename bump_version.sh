VERSION1=$1
VERSION2=$2

if [ -n "$VERSION1" -a -n "$VERSION2" ]; then

  find lib/ -name "*.pm" -exec sed -i -e "/our.*VERSION/s/$VERSION1/$VERSION2/" {} \;
  sed -i -e "/^Version/s/$VERSION1/$VERSION2/" perl-Power-Outlet.spec

else

  echo "Syntax: $0 version1 version2"

fi
