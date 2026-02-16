OUT=README.md

echo > $OUT
for FILE in `cat README.MANIFEST`; do echo $FILE ; pod2markdown $FILE >> $OUT ; done

