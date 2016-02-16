# -*- mode: ruby -*-
# vi: set ft=ruby :

$UCP_INSTALL = <<UCP
ip=$(ip addr show dev eth1 | grep -E "\\<inet\\>" | awk '{print $2}' | cut -d'/' -f1)
docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp install --host-address $ip --san ucp.docker.local
UCP

$DTR_INSTALL = <<DTR
docker run --rm docker/trusted-registry info | bash
docker run --rm docker/trusted-registry install | bash
DTR

Vagrant.configure(2) do |config|
  config.vm.box = "boxcutter/ubuntu1404"
  config.vm.network "public_network", bridge: "wlan0"
  config.vm.provision "docker", images: ["docker/ucp"]

  # Docker suggests a minimum of 1.50 GB for UCP host
  # 1GB for all will be enough for testing purpose
  config.vm.provider :virtualbox do |vbox|
    vbox.memory = 1024
  end

  # UCP provisioning
  config.vm.define :controller do |ucp|
    ucp.vm.hostname = "controller.docker.local"
    ucp.vm.provision "shell" , inline: $UCP_INSTALL
  end

  # DTR provisioning
  config.vm.define :registry do |dtr|
    dtr.vm.hostname = "registry.docker.local"
    dtr.vm.provision "docker", images: ["docker/trusted-registry"]
    dtr.vm.provision "shell" , inline: $DTR_INSTALL
  end

  # Additional nodes managed by UCP (join)
  config.vm.define :node1 do |node1|
    node1.vm.hostname = "node1.docker.local"
  end
  config.vm.define :node2 do |node2|
    node2.vm.hostname = "node2.docker.local"
  end

end
