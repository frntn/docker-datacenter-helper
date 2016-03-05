# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

$UCP_INSTALL = <<UCP
ip=$(ip addr show dev eth1 | grep -E "\\<inet\\>" | awk '{print $2}' | cut -d'/' -f1)
docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp install --host-address $ip --san ${HOSTNAME}.docker.local --san "*.tcp.ngrok.io"

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

boxes = YAML::load(File.read(File.dirname(__FILE__) + "/boxes.yaml"))

# UCP nodes
if boxes['ucp'].include?('nodes')
  nodes=boxes['ucp']['nodes']
  ucp_controllers = []
  ucp_endpoints = []
  nodes.each { |node|
    if node.include?('type') && node['type'] == 'controller'
      ucp_controllers.push(node['name']) 
    else
      ucp_endpoints.push(node['name'])
    end
  }
end
ucp_main_controller = [ucp_controllers.shift]
ucp_replica_controllers = ucp_controllers

# DTR nodes
if boxes['dtr'].include?('nodes')
  nodes=boxes['dtr']['nodes']
  dtr_registries = []
  nodes.each { |node| dtr_registries.push(node['name']) }
end

Vagrant.configure(2) do |config|
  config.vm.box = "boxcutter/ubuntu1404"
  config.vm.network "public_network", bridge: "wlan0"

  # Use cache across VMs
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box # or :machine
    config.cache.auto_detect = true
  end

  # DTR provisioning
  dtr_registries.each do |dtr_registry|
    config.vm.define dtr_registry do |registry|
      registry.vm.provision "docker", images: ["docker/trusted-registry"]
      registry.vm.provision "shell" , inline: $DTR_INSTALL
      registry.vm.hostname = "#{registry}.docker.local"
    end
  end

  # UCP nodes provisioning
  ucp_nodes = ucp_main_controller + ucp_replica_controllers + ucp_endpoints
  ucp_nodes.each do |ucp_endpoint|
    config.vm.define ucp_endpoint do |node|
      node.vm.provision "docker", images: ["docker/ucp"]
      node.vm.hostname = "#{ucp_endpoint}.docker.local"
      # Docker suggests a minimum of 1.50 GB for UCP hosts
      node.vm.provider :virtualbox do |vbox|
        vbox.memory = 1024
      end
    end
  end

  # UCP main controller specific provisioning
  ucp_main_controller.each do |ucp_controller|
    config.vm.define ucp_controller do |controller|
      controller.vm.provision "shell" , inline: $UCP_INSTALL
    end
  end

end
