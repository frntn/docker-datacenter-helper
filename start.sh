#!/bin/bash

{

cd "$(dirname "$0")"

function get_ip {
  node=${1:-"controllerA"}
  vagrant ssh $node -c      \
    'ip addr show dev eth1' \
    | grep -E '\<inet\>'    \
    | awk '{print $2}'      \
    | cut -d'/' -f1
}

function start_dtr {
  time vagrant destroy registry -f
  time vagrant up registry
}

function start_dtr_demo {
  vagrant ssh registry -c /vagrant/dtr/demo.sh
}

function start_ucp {
  # Destroy previous if asked
  if [ "$UCP_PURGE" = true ]
  then
    time vagrant destroy $UCP_NODES -f
  fi

  # Start all UCP nodes
  time vagrant up $UCP_NODES

  # Get controllerA IP address + UCP authorization token
  controllerAip=$(get_ip)
  authorization=$(
  curl -sSLk -X POST \
    -d @<(echo '{"username":"'${UCP_ADMIN_USER}'","password":"'${UCP_ADMIN_PASSWORD}'"}') \
    --header "Content-Type: application/json;charset=UTF-8"  \
    "https://$controllerAip/auth/login" | jq -r '.auth_token'
  )
  # Embed downloaded license
set -x
  subscription=${UCP_LICENSE:-"docker_subscription.lic"}
  echo '{"license_config":'$(jq -c '.' $subscription)',"auto_refresh": true}' > mylicense.lic
  # Upload license to controllerA
  curl -sSLk -X POST \
    -d @mylicense.lic \
    --header "Content-Type: application/json;charset=UTF-8" \
    --header "Authorization: Bearer $authorization"  \
    "https://$controllerAip/api/config/license"
set +x

  # Join nodes and set multi-host networking
  time ./ucp/helper.sh

  # wait for all docker engines to restart and sync with 
  # their new multi-host networking setup (can take some time...)
  sleep 240

  # load config so that the local docker client talk to "remote" UCP
  cd ucp/bundle/
  source env.sh
  docker version
  docker info | grep -E "^Nodes:|^Cluster Managers:"
}

# DTR nodes
DTR_NODES="registry"

# UCP defaults
#: ${UCP_ADMIN_USER:="admin"}
#: ${UCP_ADMIN_PASSWORD:="orca"}
: ${UCP_PURGE:=false}
UCP_ADMIN_USER="admin"
UCP_ADMIN_PASSWORD="orca"
export UCP_ADMIN_USER UCP_ADMIN_PASSWORD UCP_PURGE

# UCP nodes
: ${UCP_CONTROLLERS:="controllerA controllerB"}
: ${UCP_CLIENTS:="client1 client2"}
UCP_NODES="$UCP_CONTROLLERS $UCP_CLIENTS"
export UCP_CONTROLLERS UCP_CLIENTS UCP_NODES

action="${1,,}"
case "$action" in
  'ucp')
    main="start_$action"
    snapshot_nodes="$UCP_NODES"
    dashboard_nodes="$UCP_CONTROLLERS"
    ;;
  'dtr'|'dtr_demo') 
    main="start_$action"
    snapshot_nodes="$DTR_NODES"
    dashboard_nodes="$DTR_NODES"
    ;;
  *)
    echo >&2 "$0: FATAL: unknown action '$action'"
    exit 255
    ;;
esac

logdate="$(date +%Y%m%d_%H%M)"
logf="logs/${action}_${logdate}.log"
echo; echo " ==> Log file is '$logf'"; echo

# MAIN()
$main >> $logf

# create snapshots
for node in $snapshot_nodes; do vagrant snapshot save $node $action; done

for node in $dashboard_nodes
do 
  echo
  echo "=========================================" 
  echo "= Dashboard -> https://$(get_ip $node)/"
  echo "=========================================" 
done

}
