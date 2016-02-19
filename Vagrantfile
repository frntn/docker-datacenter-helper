# -*- mode: ruby -*-
# vi: set ft=ruby :

$UCP_INSTALL = <<UCP
ip=$(ip addr show dev eth1 | grep -E "\\<inet\\>" | awk '{print $2}' | cut -d'/' -f1)
docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp install --host-address $ip --san controller.docker.local --san "*.tcp.ngrok.io"

# install ngrok
sudo apt-get update
sudo apt-get install unzip
wget -qL -O ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
unzip ngrok.zip

# access ngrok webui from outside the VM
sysctl -w net.ipv4.conf.eth1.route_localnet=1
iptables -t nat -I PREROUTING -p tcp -d $ip/32 --dport 4040 -j DNAT --to-destination 127.0.0.1:4040
UCP

$DTR_INSTALL = <<DTR
docker run --rm docker/trusted-registry info | bash
docker run --rm docker/trusted-registry install | bash
DTR

ucp_nodes = ["controller", "node1", "node2"]

Vagrant.configure(2) do |config|
  config.vm.box = "boxcutter/ubuntu1404"
  config.vm.network "public_network", bridge: "wlan0"

  # Docker suggests a minimum of 1.50 GB for UCP host
  # 1GB for all will be enough for testing purpose
  config.vm.provider :virtualbox do |vbox|
    vbox.memory = 1024
  end

  # DTR provisioning
  config.vm.define :registry do |dtr|
    dtr.vm.provision "docker", images: ["docker/trusted-registry"]
    dtr.vm.provision "shell" , inline: $DTR_INSTALL
    dtr.vm.hostname = "registry.docker.local"
  end

  # UCP nodes and controller provisioning
  ucp_nodes.each do |ucp_node|
    config.vm.define ucp_node do |node|
      node.vm.provision "docker", images: ["docker/ucp"]
      node.vm.hostname = "#{ucp_node}.docker.local"
    end
  end

  # UCP controller-specific provisioning
  config.vm.define :controller do |ucp|
    ucp.vm.provision "shell" , inline: $UCP_INSTALL
  end

end
