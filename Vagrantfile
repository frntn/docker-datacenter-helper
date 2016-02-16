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

  # Docker suggests a minimum of 1.50 GB for UCP. I give both 2GB.
  config.vm.provider :virtualbox do |vbox|
    vbox.memory = 2048
    vbox.cpus   = 2
  end

  # UCP provisioning
  config.vm.define :ucp do |ucp|
    ucp.vm.provision "docker", images: ["docker/ucp"]
    ucp.vm.provision "shell" , inline: $UCP_INSTALL
  end

  # DTR provisioning
  config.vm.define :dtr do |dtr|
    dtr.vm.provision "docker", images: ["docker/trusted-registry"]
    dtr.vm.provision "shell" , inline: $DTR_INSTALL
  end
end
