# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

settings = YAML::load(File.read(File.dirname(__FILE__) + "/config.yml"))

# UCP nodes
if settings['ucp'].include?('nodes')
  nodes=settings['ucp']['nodes']
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
if settings['dtr'].include?('nodes')
  nodes=settings['dtr']['nodes']
  dtr_registries = []
  nodes.each { |node| dtr_registries.push(node['name']) }
end


$UCP_INSTALL = <<UCP
ip=$(ip addr show dev eth1 | grep -E "\\<inet\\>" | awk '{print $2}' | cut -d'/' -f1)
docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp install --host-address $ip --san ${HOSTNAME}.docker.local --san "*.tcp.ngrok.io"
UCP

$NGROK_INSTALL = <<NGROK
# install ngrok
sudo apt-get update
sudo apt-get install unzip
wget -qL -O ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
unzip ngrok.zip

# access ngrok webui from outside the VM
sysctl -w net.ipv4.conf.eth1.route_localnet=1
ip=$(ip addr show dev eth1 | grep -E "\\<inet\\>" | awk '{print $2}' | cut -d'/' -f1)
iptables -t nat -I PREROUTING -p tcp -d $ip/32 --dport 4040 -j DNAT --to-destination 127.0.0.1:4040
NGROK

$GITLABCI_INSTALL= "true"
if settings.include?('gitlabci') && settings['gitlabci'].include?('token')
  ci_token  = settings['gitlabci']['token']
  ci_url    = settings['gitlabci'].include?('url') ? settings['gitlabci']['url'] : 'https://gitlab.com/ci'
  ci_runner = settings['gitlabci'].include?('name') ? settings['gitlabci']['name'] : 'UCP Runner'
  ci_tags   = settings['gitlabci'].include?('tags') ? settings['gitlabci']['tags'] : %w( docker ucp )
  $GITLABCI_INSTALL = <<GITLABCI
# install gitlab-ci
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | sudo bash
sudo apt-get update -q
sudo apt-get install -qy gitlab-ci-multi-runner
sudo mkdir -p /builds
sudo chmod 1777 /builds
sudo usermod -aG docker gitlab-runner
sudo -u gitlab-runner gitlab-ci-multi-runner register \
     --non-interactive \
     --url "#{ci_url}" \
     --name "#{ci_runner}" \
     --registration-token "#{ci_token}" \
     --tag-list "#{ci_tags.flatten.join(' ')}" \
     --executor shell \
     --builds-dir /builds
echo " NOW CONNECT AND START COMMAND 'sudo -u gitlab-runner gitlab-ci-multi-runner run'"
GITLABCI
end

$DTR_INSTALL = <<DTR
docker run --rm docker/trusted-registry info | bash
docker run --rm docker/trusted-registry install | bash
DTR

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
      registry.vm.hostname = "#{dtr_registry}.docker.local"
    end
  end

  # UCP nodes provisioning : pull ucp image, setup hostname & memory
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

  # UCP controllers provisioning : install & register gitlabci
  ucp_controllers = ucp_main_controller + ucp_replica_controllers
  ucp_controllers.each do |ucp_controller|
    config.vm.define ucp_controller do |controller|
      controller.vm.provision "shell" , inline: $GITLABCI_INSTALL
    end
  end

  # UCP main controller specific provisioning : start ucp, install ngrok
  ucp_main_controller.each do |ucp_controller|
    config.vm.define ucp_controller do |controller|
      controller.vm.provision "shell" , inline: $UCP_INSTALL
      controller.vm.provision "shell" , inline: $NGROK_INSTALL
    end
  end

end
