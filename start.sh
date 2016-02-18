#!/bin/bash -u

cd "$(dirname "$0")"

function start_dtr {
  set -x
  time vagrant destroy registry -f >  logs/dtr_${logdate}.log
  time vagrant up registry         >> logs/dtr_${logdate}.log
  set +x
}

function start_dtr_demo {
  set -x
  vagrant ssh registry -c /vagrant/dtr/demo.sh > logs/dtr_demo_${logdate}.log
  set +x
}

function start_ucp {
  set -x
  time vagrant destroy controller node1 node2 -f >  logs/ucp_${logdate}.log
  time vagrant up controller                     >> logs/ucp_${logdate}.log
  time ./ucp/helper.sh                           >> logs/ucp_${logdate}.log
  set +x

  # wait for all docker engines to restart and sync with 
  # their new multi-host networking setup (can take some time...)
  sleep 90

  cd ucp/bundle/
  source env.sh
  docker version
  docker info
}

logdate="$(date +%Y%m%d_%H%M)"

case "${1,,}" in
  'ucp'|'dtr'|'dtr_demo') main="start_${1,,}";;
esac

$main
