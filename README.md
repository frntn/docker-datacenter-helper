
**Get Docker's official datacenter solutions _up & running_ in no time !**

# frntn/docker-datacenter-helper

  * `DTR` or `Docker Trusted Registry`: offers on-premise image management and storage
  * `UCP` or `Universal Control Plane`: offers on-premise docker applications management

Both requires a CS subscription _(**C**ommercial **S**upport)_

You can get a free 30-days trial here : https://hub.docker.com/enterprise/trial

## Table of Contents

- [Usage](#usage)
  - [A. Docker Trusted Registry](#a-docker-trusted-registry)
    - [A1. start your DTR](#a1-start-your-dtr)
    - [A2. configure the service](#a2-configure-the-service)
    - [A3. launch demo](#a3-launch-demo)
  - [B. Universal Control Plane](#b-universal-control-plane)
    - [B1. start your UCP cluster](#b1-start-your-ucp-cluster)
    - [B2. launch demo](#b2-launch-demo)
- [Miscellaneous](#miscellaneous)

## Usage

*Note1: if you want __unattended install__ you must specify your network interface in 
`Vagrantfile`->`config.vm.network`. On linux, you can extract this information
using this command : `ip -o -4 route get 8.8.8.8 | cut -f5 -d' '`*

*Note2: I strongly recommend the usage of __vagrant cachier__ plugin 
[more info](vagrant plugin install vagrant-cachier)*

### A. Docker Trusted Registry

#### A1. start your DTR

```bash
./start.sh dtr   # <-- approx 25min (with a decent 1Mo/s internet connection)
```

This will :

1. Destroy previously created DTR vm (if any)
2. Spin up the `registry` vm
4. Start the demo script from within the vm

Now you just have to setup your UCP instance and you're ready to go

#### A2. configure the service

**Get** DTR dashboard url

```bash
./dashboard.sh dtr
```

**Open** your browser to the given url (the certificate is not trusted so 
you have to accept the *insecure* connection. That's the expected behavior).

**Set** the domain name to `registry.docker.local` in `Settings`->`general` 
(Don't forget to hit `save and restart` at the bottom of the page)

![registry-editdomain](img/registry-editdomain.png?raw=true)

**Upload** your license in `Settings`->`License`

![registry-addlicense](img/registry-addlicense.png?raw=true)

**Create** an admin user in `Settings`->`Auth`
(if you want to use the demo script below, you'll need to create the following 
username/password : `frntn`/`demopass`)

![registry-adduser](img/registry-adduser.png?raw=true)

And finally **create** an `organisation` and a `repository` inside that organisation.
(if you want to use the demo script below, you'll need to create the following 
orgnisation/repository : `ci-infra`/`myjenkins`)

*Now you might still have red box warning about docker engine incompatibility.
That's not a problem: Just a version checking bug on `1.4.2` which is the latest
at the time of writing.*

#### A3. launch demo

**Start** the demo script to see the DTR in action

```bash
./start.sh dtr_demo   # <-- approx 15min (with a decent 1Mo/s internet connection)
```

This will :

1. *build* a custom jenkins from official image
2. *push* the custom image on the DTR
3. *run* a container pulled from that remote image stored on the DTR

Congratulations ! :)
You can now open the dashboard of your custom Jenkins instance.

### B. Universal Control Plane

#### B1. start your UCP cluster

```bash
./start_ucp   # <-- approx. 45min for a cluster of 6 nodes
```

This will start all ucp nodes defined in `nodes.yml`

The script will automate all the install process (including license upload).
You'll endup with a full functionnal and ready to use UCP cluster.

Upon completion, URL(s) to your controller(s) dashboard(s) will be echoed to stdout.
Connect to one of these with default credentials : `admin`/`orca`

#### B2. launch demo

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

We can now spinup the demo application :

```bash
cd ucp/application
docker-compose up -d
```

Congratulations ! :)
Back to the UCP dashboard you can see the newly deployed application :

![registry-adduser](img/ucp-dashboard.png?raw=true)

## Miscellaneous

  * Docker Trusted Registry [official product page](https://www.docker.com/products/docker-trusted-registry) and [solution brief](https://www.docker.com/sites/default/files/Solutions_Brief_Docker%20Trusted%20Registry_V2%20%281%29.pdf)
  * Docker Universal Control Plane [official product page](https://www.docker.com/products/docker-universal-control-plane) and [solution brief](https://www.docker.com/sites/default/files/Solutions_UCP_V3.pdf)

![official-logo](img/docker-datacenter.jpg?raw=true)

