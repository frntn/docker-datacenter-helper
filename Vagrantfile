# -*- mode: ruby -*-
# vi: set ft=ruby :

$UCP_INSTALL = <<UCP
ip=$(ip addr show dev eth1 | grep -E "\\<inet\\>" | awk '{print $2}' | cut -d'/' -f1)
docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp install --host-address $ip --san controller.docker.local
UCP

$DTR_INSTALL = <<DTR
docker run --rm docker/trusted-registry info | bash
docker run --rm docker/trusted-registry install | bash
DTR

ucp_nodes = ["controller", "node1", "node2"]

Vagrant.configure(2) do |config|
  config.vm.box = "boxcutter/ubuntu1404"
  config.vm.network "public_network", bridge: "eth0"

  # Docker suggests a minimum of 1.50 GB for UCP host
  # 1GB for all will be enough for testing purpose
  config.vm.provider :virtualbox do |vbox|
    vbox.memory = 1024
  end

  # DTR provisioning
  config.vm.define :registry do |dtr|
    dtr.vm.hostname = "registry.docker.local"
    dtr.vm.provision "docker", images: ["docker/trusted-registry"]
    dtr.vm.provision "shell" , inline: $DTR_INSTALL
  end

  # UCP provisioning
  config.vm.define :controller do |ucp|
    ucp.vm.provision "shell" , inline: $UCP_INSTALL
  end

  # Additional nodes managed by UCP (join)
  ucp_nodes.each do |ucp_node|
    config.vm.define ucp_node do |node|
      node.vm.provision "docker", images: ["docker/ucp"]
      node.vm.hostname = "#{ucp_node}.docker.local"
    end
  end

end
