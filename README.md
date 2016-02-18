*It all started Feb 15 2016 from this official Docker 
[post on twitter](https://twitter.com/docker/status/699276372204773376)*

# frntn/docker-datacenter-helper

This repo will help you start an *Up & Running* Docker's Datacenter solutions made 
with the two following (commercial) products :

  * `DTR` : *Docker Trusted Registry* offering on-prem image management and storage
  * `UCP` : *Docker Universal Control Plane* offering on-prem management solution for Docker apps

Both requires a **C**ommercial **S**upport (CS) subscription.

You can get a free 30-days trial here : https://hub.docker.com/enterprise/trial

## Usage

*Note:  
if you want **unattended install** you must specify your network interface in 
`Vagrantfile`->`config.vm.network`. On linux, you can extract this information
using this command : `ip -o -4 route get 8.8.8.8 | cut -f5 -d' '`*

### A. Start your Registery (DTR)

#### A1. spin up the `registry` host. 

```bash
vagrant up registry 
# takes approx 20min on fresh install with a decent connection (1Mo/s)
```

#### A2. configure DTR service

Get registry host IP address
```bash
./getip.sh registry
# results will be like 'Y.Y.Y.Y'
```

From your host browser go to `https://Y.Y.Y.Y` (the certificate is not trusted
so you have to accept the *insecure* connection. That's the expected behavior).

Now go to `Settings`->`general` to update the domain name to
`registry.docker.local` (Don't forget to hit `save and restart` at the bottom 
of the page)

![registry-editdomain](img/registry-editdomain.png?raw=true)

Then go to `Settings`->`License` and upload your license.

![registry-addlicense](img/registry-addlicense.png?raw=true)

You will also **need** to setup a minimal authentication in `Settings`->`Auth`

![registry-adduser](img/registry-adduser.png?raw=true)

And finally create :

1. An `organisation` and
2. A `repository` inside that organisation

Now you might still have red box warning about docker engine incompatibility.
That's not a problem: Just a version checking bug on `1.4.2` which is the latest
at the time of writing.

#### A3. demo helper

Start the `dtr/helper.sh` script to see in action a demo of a customized jenkins
(build, push, run)
```bash
vagrant ssh registry -c /vagrant/dtr/helper.sh
# takes approx 10min
```

This will :

1. build a custom jenkins from official image
2. push the custom image on the DTR
3. run a container pulled from that remote image stored on the DTR

You're done. You can safely open your browser to http://Y.Y.Y.Y:8080 :)

### B. Universal Controle Plance

#### B1. start your UCP cluster

```bash
./start.sh ucp
```

This will :

1. Destroy previously created UCP vms (if any)
2. Spin up the master `controller` vm
3. Spin up the replicas `node1` and `node2` vm
4. Configure multi-host networking

Now you just have to setup your UCP instance and you're ready to go

#### B2. configure the service

Get UCP dashboard url
```bash
./dashboard.sh ucp
```

Open your browser to the given url (the certificate is not trusted so 
you have to accept the *insecure* connection. That's the expected behavior).

Connect using defaults `admin`/`orca` 

Upload your license in the settings page

![controller-addlicense](img/controller-addlicense.png?raw=true)

Change the default passowrd in the profile page 

![controller-editprofile](img/controller-editprofile.png?raw=true)

#### B3. launch your first application

From your admin workstation (typically your host in this context), we want to 
be able to user the docker client against the UCP controller and nodes.

```bash
cd ucp/bundle/
source env.sh  # <-- your docker client now speaks with your "remote" UCP cluster
docker version # <-- the 'server:' now mentions 'ucp/0.8.0'
```

Then spinup the demo application against the UCP cluster

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

