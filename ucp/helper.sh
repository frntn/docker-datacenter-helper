#!/bin/bash
{
set -u
cd "$(dirname "$0")"

# Get main controller infos :
# =========================
#   1- NAME
main="$UCP_MAIN_CONTROLLER"

set -x

#   2- IP ADDRESS
ipucp=$(vagrant ssh $main -c "ip addr show dev eth1" | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)

#   3- SSL CERT FINGERPRINT
fingerprint="$(openssl s_client -connect "${ipucp}:443" </dev/null 2>/dev/null | openssl x509 -fingerprint -noout | cut -d'=' -f2)"


echo; echo "----> Join 'Replica Controllers' <----"; echo
# Join replica controllers :
# =========================
replica="--replica"
for node in $UCP_REPLICA_CONTROLLERS
do
  [ "$node" = "$main" ] && continue

  echo; echo "------> $node"; echo
  vagrant up $node
  ipnode=$(vagrant ssh $node -c "ip addr show dev eth1" | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
  vagrant ssh $node -c "
docker run \
--rm \
--tty \
--name ucp \
--interactive \
-e UCP_ADMIN_USER=$UCP_ADMIN_USER \
-e UCP_ADMIN_PASSWORD=$UCP_ADMIN_PASSWORD \
-v /var/run/docker.sock:/var/run/docker.sock \
\
docker/ucp join \
--san ${node}.docker.local \
--host-address $ipnode \
--url https://$ipucp \
--fingerprint $fingerprint \
--fresh-install \
$replica
"
done

echo; echo "----> Join 'Endpoints Nodes' <----"; echo
# Join endpoint nodes :
# ====================
replica=""
for node in $UCP_ENDPOINTS
do
  echo; echo "------> $node"; echo
  vagrant up $node
  ipnode=$(vagrant ssh $node -c "ip addr show dev eth1" | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
  vagrant ssh $node -c "
docker run \
--rm \
--tty \
--name ucp \
--interactive \
-e UCP_ADMIN_USER=$UCP_ADMIN_USER \
-e UCP_ADMIN_PASSWORD=$UCP_ADMIN_PASSWORD \
-v /var/run/docker.sock:/var/run/docker.sock \
\
docker/ucp join \
--san ${node}.docker.local \
--host-address $ipnode \
--url https://$ipucp \
--fingerprint $fingerprint \
--fresh-install \
$replica
"
done

set +x

echo; echo "----> Download Client Bundle <----"; echo
# download client bundle
AUTHTOKEN=$(curl -sk -d "{\"username\":\"$UCP_ADMIN_USER\",\"password\":\"$UCP_ADMIN_PASSWORD\"}" https://$ipucp/auth/login | jq -r .auth_token)
curl -sSLk -H "Authorization: Bearer $AUTHTOKEN" https://$ipucp/api/clientbundle -o bundle/bundle.zip

echo; echo "----> Extract Client Bundle <----"; echo
# extract client bundle
cd bundle
unzip -o bundle.zip
rm bundle.zip
cd ..

# overlay networks require access to a key-value store
echo; echo "----> Add Multi-Host Networking Support to Docker Daemons <----"; echo
for node in $UCP_NODES
do
  echo; echo "------> $node <----"; echo
  vagrant ssh $node -c "
ip=\$(ip addr show dev eth1 | grep -E '\\<inet\\>' | awk '{print \$2}' | cut -d'/' -f1)
echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-advertise '\$ip':12376\"'                                         | sudo tee -a /etc/default/docker >/dev/null
echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store etcd://$ipucp:12379\"'                                      | sudo tee -a /etc/default/docker >/dev/null
echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store-opt kv.cacertfile=/var/lib/docker/discovery_certs/ca.pem\"' | sudo tee -a /etc/default/docker >/dev/null
echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store-opt kv.certfile=/var/lib/docker/discovery_certs/cert.pem\"' | sudo tee -a /etc/default/docker >/dev/null
echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store-opt kv.keyfile=/var/lib/docker/discovery_certs/key.pem\"'   | sudo tee -a /etc/default/docker >/dev/null
sudo service docker restart
"
done
}
