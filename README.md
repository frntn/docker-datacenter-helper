*It all started Feb 15 2016 from this official Docker 
[post on twitter](https://twitter.com/docker/status/699276372204773376)*

![logo](../master/img/docker-datacenter.jpg?raw=true)

# frntn/docker-datacenter

*Quick & Dirty* repo to help you spin up a Docker environment with 
the following 2 commercial products integrated :

  * `UCP` : Docker Universal Control Plane
  * `DTR` : Docker Trusted Registry

Both requires a commercial support (CS) subscription.
You can get a free 30-days trial here : https://hub.docker.com/enterprise/trial

## TLDR

```
git clone https://github.com/frntn/docker-datacenter
cd docker-datacenter
vagrant up # take approx 30min on fresh install with a decent connection (1Mo/s)
```

*Note: if you have multiple network interfaces the `vagrant up` will prompt for
the good one. You can specify it in `Vagrantfile`->`config.vm.network` to
prevent this.*

## Some more details

```
# List servers and display status
vagrant status

# Get UCP server ip address
vagrant ssh ucp -c "ip addr show dev eth1"

# Get DTR server ip address
vagrant ssh dtr -c "ip addr show dev eth1"
```

On your host, open up your default browser and :

1. Go to UCP dashboard (https://ucp-vm-ip/), connect using the default auth 
(admin/orca) and change password.
![dashboard-ucp](../master/img/dashboard-ucp.png?raw=true)

2. Go to DTR dashboard (https://dtr-vm-ip/) and setup your domain name, upload
your license, add authentication
![dashboard-ucp](../master/img/dashboard-ucp.png?raw=true)

Additional setup information can be found
[here for UCP](http://ucp-beta-docs.s3-website-us-west-1.amazonaws.com/) and 
[here for DTR](https://docs.docker.com/docker-trusted-registry/configuration/) 

Eventually you may want to take a look at the official 
[UCP lab](https://github.com/docker/ucp_lab) and play/extend with your setup...

## Why ?

It can be difficult to have a valid setup while following the documentation 
which is still in very early stage and contains inconsistency or 
incompatibility between UCP and DTR. 

One example is the UCP documentation explains how to install CS engine 1.9 
and then pulls UCP latest which turns out to be 0.8 and only valid for CS 
engine 1.10.

*(Note: I'd be happy to help and contribute on that, but this is the 
commercial product and it's not available on github)*

## What ?

### DTR

From the [official product page](https://www.docker.com/products/docker-trusted-registry) :

> Docker Trusted Registry allows you to store and manage 
> your Docker images on-premise 
> or in your virtual private cloud to support security 
> or regulatory compliance requirements 
> in keeping data and applications your infrastructure

### UCP

From the [official product page](https://www.docker.com/products/docker-universal-control-plane) :

> Universal Control Plane offers an on-premises management 
> solution for Docker apps, regardless of where they run.
> It can be deployed to any private infrastructure 
> or public cloud

