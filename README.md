# frntn/docker-datacenter-helper

**Get Docker's official datacenter solutions _up & running_ in no time**  
**100% _unattended_ installation !**

Docker Datacenter solution is made of two commercial products :

  * `DTR` or `Docker Trusted Registry`: offers on-premise image management and storage
  * `UCP` or `Universal Control Plane`: offers on-premise docker applications management

Both requires a CS subscription _(**C**ommercial **S**upport)_

You can get a free 30-days trial here : https://hub.docker.com/enterprise/trial

## Table of Contents

- [Usage](#usage)
  - [A. Docker Trusted Registry](#a-docker-trusted-registry)
    - [A1. start your DTR](#a1-start-your-dtr)
    - [A2. dtr asciicast](#a2-dtr-asciicast)
  - [B. Universal Control Plane](#b-universal-control-plane)
    - [B1. start your UCP cluster](#b1-start-your-ucp-cluster)
    - [B2. ucp asciicast](#b2-ucp-asciicast)
    - [B3. launch demo](#b3-launch-demo)
- [Miscellaneous](#miscellaneous)

## Usage

*Note1: if you want __unattended install__ you must specify your network interface in 
`Vagrantfile`->`config.vm.network`. On linux, you can extract this information
using this command : `ip -o -4 route get 8.8.8.8 | cut -f5 -d' '`*

*Note2: I strongly recommend the usage of __vagrant cachier__ plugin 
[more info](https://github.com/fgrehm/vagrant-cachier)*

### A. Docker Trusted Registry

#### A1. start your DTR

Drop your `docker_subscription.lic` license file at the root of the project, then start your DTR instance(s) :

```bash
./start_dtr
```

This will _provision_ and _configure_ the DTR nodes defined in [config.yml](config.yml) file

The script will automate all the install process (including license upload).
You'll endup with a full functionnal and ready to use private registry.

Upon completion, URL to your registry dashboard will be echoed to stdout.

#### A2. DTR Asciicast

Below is an asciicast capturing the `start_dtr` script output with the default settings :
[![dtr-asciicast](https://asciinema.org/a/5uyrknsjg7u2fad6ii0wgizd4.png)](https://asciinema.org/a/5uyrknsjg7u2fad6ii0wgizd4?autoplay=1&speed=2&theme=asciinema&size=medium)

And here is an asciicast capturing the log file content for that same `start_dtr` exec :
[![dtr-asciicast](https://asciinema.org/a/5uyrknsjg7u2fad6ii0wgizd4.png)](https://asciinema.org/a/5uyrknsjg7u2fad6ii0wgizd4?autoplay=1&speed=2&theme=asciinema&size=medium)

### B. Universal Control Plane

#### B1. start your UCP cluster

Drop your `docker_subscription.lic` license file at the root of the project, then start your DTR instance(s) :

```bash
./start_ucp
```

This will _provision_ and _configure_ the UCP cluster nodes defined in [config.yml](config.yml) file

The script will automate all the install process (including license upload).
You'll endup with a full functionnal and ready to use universal docker platform.

Upon completion, URL(s) to your controller(s) dashboard(s) will be echoed to stdout.

#### A2. UCP Asciicast

Below is an asciicast capturing the `start_ucp` script output with the default settings :
[![dtr-asciicast](https://asciinema.org/a/5uyrknsjg7u2fad6ii0wgizd4.png)](https://asciinema.org/a/5uyrknsjg7u2fad6ii0wgizd4?autoplay=1&speed=2&theme=asciinema&size=medium)

And here is an asciicast capturing the log file content for that same `start_ucp` exec :
[![dtr-asciicast](https://asciinema.org/a/5uyrknsjg7u2fad6ii0wgizd4.png)](https://asciinema.org/a/5uyrknsjg7u2fad6ii0wgizd4?autoplay=1&speed=2&theme=asciinema&size=medium)

#### B3. launch demo

To use the demo application, we want our local docker client to point to this newly created UCP cluster :

```bash
# before check
docker version # <-- the 'Server' section mentions 'Version: x.y.z'

# load environment variable so your docker client points to remote docker server
cd ucp/bundle/
source env.sh  # <-- your docker client now speaks with your "remote" UCP cluster

# after check
docker version # <-- the 'Server' now mentions 'Version: ucp/x.y.z'
```

Then we can now spin up the demo application :

```bash
cd ucp/application
docker-compose up -d
```

Back to the UCP dashboard you can see the newly deployed application :

![registry-adduser](img/ucp-dashboard.png?raw=true)

**Congratulations : you've just created your very fist application on an UCP cluster ! :)**

## Miscellaneous

  * Docker Trusted Registry [official product page](https://www.docker.com/products/docker-trusted-registry) and [solution brief](https://www.docker.com/sites/default/files/Solutions_Brief_Docker%20Trusted%20Registry_V2%20%281%29.pdf)
  * Docker Universal Control Plane [official product page](https://www.docker.com/products/docker-universal-control-plane) and [solution brief](https://www.docker.com/sites/default/files/Solutions_UCP_V3.pdf)

![official-logo](img/docker-datacenter.jpg?raw=true)

