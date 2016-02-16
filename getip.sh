#!/bin/bash

case "$1" in
  'controller'|'registry') node=$1;;
esac

vagrant ssh $node -c      \
  'ip addr show dev eth1' \
  | grep -E '\<inet\>'    \
  | awk '{print $2}'      \
  | cut -d'/' -f1
