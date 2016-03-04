#!/bin/bash

{

cd "$(dirname "$0")"

function start_dtr {
  time vagrant destroy registry -f >> $logf
  time vagrant up registry         >> $logf
}

function start_dtr_demo {
  vagrant ssh registry -c /vagrant/dtr/demo.sh >> $logf
}

function start_ucp_begin {
  set -x
  ${UCP_PURGE:=false} && time vagrant destroy $ucp_all -f >> $logf
  time vagrant up $ucp_all         >> $logf
  set +x

#  # wait for all docker engines to restart and sync with 
#  # their new multi-host networking setup (can take some time...)
#  sleep 240
#
#  cd ucp/bundle/
#  source env.sh
#  docker version
#  docker info
}

function start_ucp_end {
  set -x
  time ./ucp/helper.sh             >> $logf
  set +x
}

# DTR nodes
dtr_all="registry"

# UCP nodes
ucp_controllers="controllerA"
ucp_nodes="node1 node2"
ucp_all="$ucp_controllers $ucp_nodes"
export ucp_controllers ucp_nodes ucp_all

action="${1,,}"
case "$action" in
  'ucp_begin'|'ucp_end')
    main="start_$action"
    snapshot_nodes="$ucp_all"
    ;;
  'dtr'|'dtr_demo') 
    main="start_$action"
    snapshot_nodes="$dtr_all"
    ;;
  *)
    echo >&2 "$0: FATAL: unknown action '$action'"
    exit 255
    ;;
esac

logdate="$(date +%Y%m%d_%H%M)"
logf="logs/${action}_${logdate}.log"
echo; echo " ==> Log file is '$logf'"; echo

$main

for node in $snapshot_nodes; do vagrant snapshot save $node $action; done

}
