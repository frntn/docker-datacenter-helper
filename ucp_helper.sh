#!/bin/bash

: ${UCP_ADMIN_USER:=admin}
: ${UCP_ADMIN_PASSWORD:=orca}

ipucp=$(vagrant ssh controller -c "ip addr show dev eth1" | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
fingerprint="$(openssl s_client -connect "${ipucp}:443" </dev/null 2>/dev/null | openssl x509 -fingerprint -noout | cut -d'=' -f2)"

vagrant up node1
ipnode1=$(vagrant ssh node1 -c "ip addr show dev eth1" | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
vagrant ssh node1 -c "docker run --rm -it -e UCP_ADMIN_USER=$UCP_ADMIN_USER -e UCP_ADMIN_PASSWORD=$UCP_ADMIN_PASSWORD -v /var/run/docker.sock:/var/run/docker.sock --name ucp docker/ucp join --san node1.docker.local --host-address $ipnode1 --url https://$ipucp --fingerprint $fingerprint"

vagrant up node2
ipnode2=$(vagrant ssh node2 -c "ip addr show dev eth1" | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
vagrant ssh node2 -c "docker run --rm -it -e UCP_ADMIN_USER=$UCP_ADMIN_USER -e UCP_ADMIN_PASSWORD=$UCP_ADMIN_PASSWORD -v /var/run/docker.sock:/var/run/docker.sock --name ucp docker/ucp join --san node2.docker.local --host-address $ipnode2 --url https://$ipucp --fingerprint $fingerprint"

