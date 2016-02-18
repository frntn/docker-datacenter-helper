#!/bin/bash -u

case "${1,,}" in
  'ucp') node=controller;;
  'dtr') node=registry;;
esac

ip=$(vagrant ssh $node -c      \
  'ip addr show dev eth1' \
  | grep -E '\<inet\>'    \
  | awk '{print $2}'      \
  | cut -d'/' -f1)

echo
echo "${1^^} dashboard => https://$ip/"
echo 
