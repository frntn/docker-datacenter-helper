#!/bin/bash -u

cd "$(dirname "$0")"

function start_ucp {
  set -x
  time vagrant destroy controller node1 node2 -f > out.log
  time vagrant up controller >> out.log
  time ./ucp/helper.sh >> out.log
  set +x

  # wait for all docker engines to restart and sync with 
  # their new multi-host networking setup (can take some time...)
  sleep 30

  cd ucp/bundle/
  source env.sh
  docker version
  docker info
}

case "$1" in
  'ucp'|'dtr') main="start_$1";;
esac

$main
