#!/bin/bash -u

cd "$(dirname "$0")"

function start_dtr {
  set -x
  time vagrant destroy registry -f >  dtr_${logdate}.log
  time vagrant up registry         >> dtr_${logdate}.log
  set +x
}

function start_ucp {
  set -x
  time vagrant destroy controller node1 node2 -f >  ucp_${logdate}.log
  time vagrant up controller                     >> ucp_${logdate}.log
  time ./ucp/helper.sh                           >> ucp_${logdate}.log
  set +x

  # wait for all docker engines to restart and sync with 
  # their new multi-host networking setup (can take some time...)
  sleep 30

  cd ucp/bundle/
  source env.sh
  docker version
  docker info
}

logdate="$(date +%Y%m%d_%H%M)"

case "${1,,}" in
  'ucp'|'dtr') main="start_${1,,}";;
esac

$main
