#!/bin/bash

set -u

cd "$(dirname "$0")"

# set default values
: ${UCP_ADMIN_USER:=admin}
: ${UCP_ADMIN_PASSWORD:=orca}
: ${ucp_controllers:="controllerA"}
: ${ucp_nodes:="node1 node2"}
: ${ucp_all:="$ucp_controllers $ucp_nodes"}

for controller in $ucp_controllers
do
  # get controller IP and SSL certificate fingerprint
  ipucp=$(vagrant ssh $controller -c "ip addr show dev eth1" | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
  fingerprint="$(openssl s_client -connect "${ipucp}:443" </dev/null 2>/dev/null | openssl x509 -fingerprint -noout | cut -d'=' -f2)"

  # joining nodes
  for node in $ucp_nodes
  do
  set -x
    ipnode=$(vagrant ssh $node -c "ip addr show dev eth1" | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
    vagrant ssh $node -c "
      docker run      \
        --rm          \
        --tty         \
        --interactive \
        -e UCP_ADMIN_USER=$UCP_ADMIN_USER            \
        -e UCP_ADMIN_PASSWORD=$UCP_ADMIN_PASSWORD    \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --name ucp docker/ucp join \
        --san node1.docker.local   \
        --host-address $ipnode     \
        --url https://$ipucp       \
        --fingerprint $fingerprint \
        --fresh-install            \
        --replica
      "
  set +x
  done
done

# download client bundle
AUTHTOKEN=$(curl -sk -d "{\"username\":\"$UCP_ADMIN_USER\",\"password\":\"$UCP_ADMIN_PASSWORD\"}" https://$ipucp/auth/login | jq -r .auth_token)
curl -sSLk -H "Authorization: Bearer $AUTHTOKEN" https://$ipucp/api/clientbundle -o bundle/bundle.zip

# extract client bundle
cd bundle
unzip -o bundle.zip
rm bundle.zip
cd ..

# overlay networks require access to a key-value store
echo "restart docker with multi-host networking support"
for i in $all
do
  vagrant ssh $i -c "
ip=\$(ip addr show dev eth1 | grep -E '\\<inet\\>' | awk '{print \$2}' | cut -d'/' -f1)
echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-advertise '\$ip':12376\"'                                         | sudo tee -a /etc/default/docker >/dev/null
echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store etcd://$ipucp:12379\"'                                      | sudo tee -a /etc/default/docker >/dev/null
echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store-opt kv.cacertfile=/var/lib/docker/discovery_certs/ca.pem\"' | sudo tee -a /etc/default/docker >/dev/null
echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store-opt kv.certfile=/var/lib/docker/discovery_certs/cert.pem\"' | sudo tee -a /etc/default/docker >/dev/null
echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-store-opt kv.keyfile=/var/lib/docker/discovery_certs/key.pem\"'   | sudo tee -a /etc/default/docker >/dev/null
sudo service docker restart
"
done

