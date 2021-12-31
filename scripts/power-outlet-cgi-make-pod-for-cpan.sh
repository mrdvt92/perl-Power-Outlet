#!/bin/sh

for F in power-outlet.cgi power-outlet-json.cgi
do
  echo $F
  podselect $F > $F.pod
done

