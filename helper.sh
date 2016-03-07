#!/bin/bash

{
set -u
cd "$(dirname "$0")"

function get_ip {
  node=${1:-"controller"}
  vagrant ssh $node -c      \
    'ip addr show dev eth1' \
    2>/dev/null             \
    | grep -E '\<inet\>'    \
    | awk '{print $2}'      \
    | cut -d'/' -f1
}

function create_snapshot {
  echo "==> Create ${action^^} snapshots ($func)"
  for node in $snapshot_nodes
  do 
    vagrant snapshot save "$node" "$func"
  done
}

function dtr_provision {
  # Destroy previous if asked
  if [ "$DTR_PURGE" = true ]
  then
    vagrant destroy $DTR_NODES -f
  fi

  # Start all DTR nodes
  vagrant up $DTR_NODES

  echo; echo "---------- END VAGRANT PROVISIONING ----------"; echo
}

function dtr_configure {
  for node in $DTR_NODES
  do
    curlopts="-sSLk -X PUT"
    curlhead="Content-Type: application/json;charset=UTF-8"

    echo "==> $node: Setup domain name"
    dtr_ip=$(get_ip $node)
    dtr_settings='{"loadBalancerHTTPPort":80,"loadBalancerHTTPSPort":443,"domainName":"'$node'.docker.local","notaryServer":"","notaryCert":"","notaryVerifyCert":false,"authBypassCA":"","authBypassOU":"","httpProxy":"","httpsProxy":"","noProxy":"","disableUpgrades":false,"releaseChannel":""}'
    curl $curlopts -H "$curlhead" -d "$dtr_settings" https://$dtr_ip/api/v0/admin/settings/http | awk '{print "    '$node': "$0}'

    sleep 30 # <-- wait for the service to restart (https cert update)

    echo "==> $node: Upload license"
    curl $curlopts -H "$curlhead" -d @<(jq -c '.' $DTR_LICENSE) https://$dtr_ip/api/v0/admin/settings/license | awk '{print "    '$node': "$0}'

    echo "==> $node: Add admin account"
    dtr_admin='{"method":"managed","managed":{"users":[{"username":"'$DTR_USER'","password":"'$DTR_PASS'","isNew":true,"isAdmin":true,"isReadWrite":false,"isReadOnly":false,"teamsChanged":true}]}}'
    curl $curlopts -H "$curlhead" -d "$dtr_admin" https://$dtr_ip/api/v0/admin/settings/auth | awk '{print "    '$node': "$0}'
  done

  echo; echo "---------- END DTR CONFIGURATION ----------"; echo
}

function start_dtr_demo {
  vagrant ssh $DTR_NODES -c /vagrant/dtr/demo.sh
}

function ucp_provision {
  # Destroy previous if asked
  if [ "$UCP_PURGE" = true ]
  then
    vagrant destroy $UCP_NODES -f
  fi

  # Start all UCP nodes
  vagrant up $UCP_NODES

  echo; echo "---------- END VAGRANT PROVISIONING ----------"; echo
}

function ucp_configure {

  echo "==> Get authorization token"
  ucp_main_controller_ip=$(get_ip $UCP_MAIN_CONTROLLER)
  authorization=$(
  curl -sSLk -X POST \
    -d @<(echo '{"username":"'${UCP_USER}'","password":"'${UCP_PASS}'"}') \
    --header "Content-Type: application/json;charset=UTF-8"  \
    "https://$ucp_main_controller_ip/auth/login" | jq -r '.auth_token'
  )

  echo "==> Upload license"
  echo '{"license_config":'$(jq -c '.' $UCP_LICENSE)',"auto_refresh": true}' > mylicense.lic
  curl -sSLk -X POST \
    -d @mylicense.lic \
    --header "Content-Type: application/json;charset=UTF-8" \
    --header "Authorization: Bearer $authorization"  \
    "https://$ucp_main_controller_ip/api/config/license"

  main="$UCP_MAIN_CONTROLLER"
  ipucp=$(vagrant ssh $main -c "ip addr show dev eth1" 2>/dev/null | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
  fingerprint="$(openssl s_client -connect "${ipucp}:443" </dev/null 2>/dev/null | openssl x509 -fingerprint -noout | cut -d'=' -f2)"

  echo "==> Join replica nodes to main cluster controller ($main)"
  replica="--replica"
  for node in $UCP_REPLICA_CONTROLLERS
  do
    #vagrant up $node
    ipnode=$(vagrant ssh $node -c "ip addr show dev eth1" 2>/dev/null | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
    vagrant ssh $node -c "
      docker run \
        --rm          \
        --tty         \
        --name ucp    \
        --interactive \
        -e UCP_ADMIN_USER=$UCP_USER             \
        -e UCP_ADMIN_PASSWORD=$UCP_PASS     \
        -v /var/run/docker.sock:/var/run/docker.sock  \
                                                      \
        docker/ucp join             \
        --san ${node}.docker.local  \
        --host-address $ipnode      \
        --url https://$ipucp        \
        --fingerprint $fingerprint  \
        --fresh-install             \
        $replica
    " 2>/dev/null | awk '{print "    '$node': "$0}'
  done

  echo "==> Join standard nodes to cluster ($main)"
  replica=""
  for node in $UCP_ENDPOINTS
  do
    #vagrant up $node
    ipnode=$(vagrant ssh $node -c "ip addr show dev eth1" 2>/dev/null | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
    vagrant ssh $node -c "
      docker run      \
        --rm          \
        --tty         \
        --name ucp    \
        --interactive \
        -e UCP_ADMIN_USER=$UCP_USER             \
        -e UCP_ADMIN_PASSWORD=$UCP_PASS     \
        -v /var/run/docker.sock:/var/run/docker.sock  \
                                                      \
        docker/ucp join             \
        --san ${node}.docker.local  \
        --host-address $ipnode      \
        --url https://$ipucp        \
        --fingerprint $fingerprint  \
        --fresh-install             \
        $replica
    " 2>/dev/null | awk '{print "    '$node': "$0}'
  done

  # overlay networks require access to a key-value store
  echo "==> Add Multi-Host Networking Support to Docker Daemons"
  for node in $UCP_NODES
  do
    vagrant ssh $node -c "
      ip=\$(ip addr show dev eth1 | grep -E '\\<inet\\>' | awk '{print \$2}' | cut -d'/' -f1)
      {
        echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-advertise '\$ip':12376\"'
        echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store etcd://$ipucp:12379\"'
        echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store-opt kv.cacertfile=/var/lib/docker/discovery_certs/ca.pem\"'
        echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store-opt kv.certfile=/var/lib/docker/discovery_certs/cert.pem\"'
        echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store-opt kv.keyfile=/var/lib/docker/discovery_certs/key.pem\"'
      } | sudo tee -a /etc/default/docker
      sudo service docker restart
    " 2>/dev/null | awk '{print "    '$node': "$0}'
  done

  # wait for all docker engines to restart and sync with 
  # their new multi-host networking setup (can take some time...)
  sleep 240

  echo "==> Download Client Bundle"
  cd ucp/bundle
  AUTHTOKEN=$(curl -sk -d "{\"username\":\"$UCP_USER\",\"password\":\"$UCP_PASS\"}" https://$ipucp/auth/login | jq -r .auth_token)
  curl -sSLk -H "Authorization: Bearer $AUTHTOKEN" https://$ipucp/api/clientbundle -o bundle.zip

  echo "==> Extract Client Bundle"
  unzip -o bundle.zip | awk '{print "    "$0}'
  rm bundle.zip

  echo "==> Load Client Bundle"
  source env.sh

  echo; echo "---------- END UCP CONFIGURATION ----------"; echo

  echo "==> Check docker version ('Version: ucp/x.x.x' expected for 'Server:' section)"
  docker version | sed -n '1,2p;9,10p' | awk '{print "    "$0}'

  echo "==> Show Nodes and Cluster Managers count"
  docker info | grep -E "^Nodes:|^Cluster Managers:" | awk '{print "    "$0}'
}

# === BEGIN ===================================================================

: ${DTR_PURGE:=false}
: ${DTR_LICENSE:="docker_subscription.lic"}
: ${DTR_REGISTRIES:="registry"}
: ${DTR_USER:="frntn"}
: ${DTR_PASS:="demopass"}

: ${UCP_PURGE:=false}
: ${UCP_LICENSE:="docker_subscription.lic"}
: ${UCP_MAIN_CONTROLLER:="controller1"}
: ${UCP_REPLICA_CONTROLLERS:=""}
: ${UCP_ENDPOINTS:="client1 client2"}

DTR_NODES="$DTR_REGISTRIES"
UCP_NODES="$UCP_MAIN_CONTROLLER $UCP_REPLICA_CONTROLLERS $UCP_ENDPOINTS"
UCP_USER="admin"
UCP_PASS="orca"

# DISPATCHER
action="${1,,}"
case "$action" in
  'ucp')
    snapshot_nodes="$UCP_NODES"
    dashboard_nodes="$UCP_MAIN_CONTROLLER $UCP_REPLICA_CONTROLLERS"
    user="$UCP_USER"
    pass="$UCP_PASS"
    ;;
  'dtr') 
    main="start_$action"
    snapshot_nodes="$DTR_NODES"
    dashboard_nodes="$DTR_NODES"
    user="$DTR_USER"
    pass="$DTR_PASS"
    ;;
  *)
    echo >&2 "$0: FATAL: unknown action '$action'"
    exit 255
    ;;
esac

# LOFGILE
logdate="$(date +%Y%m%d_%H%M)"
logf="logs/${action}_${logdate}.log"
echo; echo "Log file is '$logf'"; echo

# PROVISION
echo "==> Provision ${action^^} nodes"
cd "$(dirname "$0")"
func="${action}_provision"
$func >> $logf
create_snapshot

# CONFIGURE
echo "==> Configure ${action^^} nodes"
cd "$(dirname "$0")"
func="${action}_configure"
$func >> $logf
create_snapshot

# DASHBOARDS
echo
echo "=========================================" 
echo "= User: $user"
echo "= ------------------------------------- ="
echo "= Password: $pass"
echo "= ------------------------------------- ="
echo "= Dashboard URL(s):"
echo "="
for node in $dashboard_nodes
do 
  echo -e "= $node\thttps://$(get_ip $node)/"
done
echo "=========================================" 
echo

}
