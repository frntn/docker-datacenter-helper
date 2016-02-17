# -*- mode: ruby -*-
# vi: set ft=ruby :

$UCP_INSTALL = <<UCP
ip=$(ip addr show dev eth1 | grep -E "\\<inet\\>" | awk '{print $2}' | cut -d'/' -f1)
docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp install --host-address $ip --san controller.docker.local
UCP

$DTR_INSTALL = <<DTR
curl -s 'https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e' | sudo apt-key add --import
sudo apt-get update && sudo apt-get install apt-transport-https
sudo apt-get install -y linux-image-extra-virtual
echo "deb https://packages.docker.com/1.9/apt/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update && sudo apt-get install -y docker-engine
sudo service docker start
sudo usermod -a -G docker vagrant

docker pull docker/trusted-registry
docker pull jenkins

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

  # UCP provisioning
  config.vm.define :controller do |ucp|
    ucp.vm.provision "shell" , inline: $UCP_INSTALL
  end

  # DTR provisioning
  config.vm.define :registry do |dtr|
    # DTR requires CS Docker Engine (CommercialSupport) 
    # it is incompatible with OS Docker Engine (OpenSource)
    # so we cannot let the provisioner install docker...
    dtr.vm.provision "shell" , inline: $DTR_INSTALL
    dtr.vm.hostname = "registry.docker.local"
  end

  # Additional nodes managed by UCP (join)
  ucp_nodes.each do |ucp_node|
    config.vm.define ucp_node do |node|
      # UCP latest image is 0.8 and only works 
      # with latest OS Docker Engine 1.10
      # so we let the provisioner install docker...
      node.vm.provision "docker", images: ["docker/ucp"]
      node.vm.hostname = "#{ucp_node}.docker.local"
    end
  end

end
