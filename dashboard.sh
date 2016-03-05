#!/bin/bash

set -u

case "${1,,}" in
  'ucp') nodes="controllerA controllerB";;
  'dtr') nodes="registry";;
esac

for node in $nodes
do
  ip=$(vagrant ssh $node -c \
    'ip addr show dev eth1' \
    | grep -E '\<inet\>'    \
    | awk '{print $2}'      \
    | cut -d'/' -f1)

  echo
  echo "${1^^} $node dashboard => https://$ip/"
  echo 

done

