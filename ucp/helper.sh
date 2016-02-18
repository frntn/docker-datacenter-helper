#!/bin/bash

cd "$(dirname "$0")"

# set default values
: ${UCP_ADMIN_USER:=admin}
: ${UCP_ADMIN_PASSWORD:=orca}

# get controller IP and SSL certificate fingerprint
ipucp=$(vagrant ssh controller -c "ip addr show dev eth1" | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
fingerprint="$(openssl s_client -connect "${ipucp}:443" </dev/null 2>/dev/null | openssl x509 -fingerprint -noout | cut -d'=' -f2)"

# node1 joining
vagrant up node1
ipnode1=$(vagrant ssh node1 -c "ip addr show dev eth1" | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
vagrant ssh node1 -c "docker run --rm -it -e UCP_ADMIN_USER=$UCP_ADMIN_USER -e UCP_ADMIN_PASSWORD=$UCP_ADMIN_PASSWORD -v /var/run/docker.sock:/var/run/docker.sock --name ucp docker/ucp join --san node1.docker.local --host-address $ipnode1 --url https://$ipucp --fingerprint $fingerprint --fresh-install --replica"

# node2 joining
vagrant up node2
ipnode2=$(vagrant ssh node2 -c "ip addr show dev eth1" | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
vagrant ssh node2 -c "docker run --rm -it -e UCP_ADMIN_USER=$UCP_ADMIN_USER -e UCP_ADMIN_PASSWORD=$UCP_ADMIN_PASSWORD -v /var/run/docker.sock:/var/run/docker.sock --name ucp docker/ucp join --san node2.docker.local --host-address $ipnode2 --url https://$ipucp --fingerprint $fingerprint --fresh-install --replica"

# download client bundle
AUTHTOKEN=$(curl -sk -d "{\"username\":\"$UCP_ADMIN_USER\",\"password\":\"$UCP_ADMIN_PASSWORD\"}" https://$ipucp/auth/login | jq -r .auth_token)
curl -sSLk -H "Authorization: Bearer $AUTHTOKEN" https://$ipucp/api/clientbundle -o bundle/bundle.zip

# extract client bundle
cd bundle
unzip -o bundle.zip
rm bundle.zip
cd ..

for i in controller node1 node2
do
  vagrant ssh $i -c "
ip=\$(ip addr show dev eth1 | grep -E '\\<inet\\>' | awk '{print \$2}' | cut -d'/' -f1)
echo 'DOCKER_OPTS=\"\$DOCKER_OPTS --cluster-advertise '\$ip':12376 --cluster-store etcd://$ipucp:12379 --cluster-store-opt kv.cacertfile=/var/lib/docker/discovery_certs/ca.pem --cluster-store-opt kv.certfile=/var/lib/docker/discovery_certs/cert.pem --cluster-store-opt kv.keyfile=/var/lib/docker/discovery_certs/key.pem\"' | sudo tee -a /etc/default/docker >/dev/null
sudo service docker restart
"
done

