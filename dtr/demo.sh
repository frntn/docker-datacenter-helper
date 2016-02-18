#!/bin/bash

: ${DTR_URL:="registry.docker.local"}
: ${DTR_EMAIL:="ci@docker.local"}
: ${DTR_USER:="frntn"}
: ${DTR_PASS:="demopass"}
: ${DTR_ORG:="ci-infra"}
: ${DTR_REPO:="myjenkins"}

wait=10
echo "
Before running this script, in the registry dashboard, you must have :
 - Uploaded your license, 
 - Created the '${DTR_USER}' user,
 - Created the '${DTR_ORG}' organisation,
 - Created the '${DTR_REPO}' repository,
 - Set your registry domain name to '${DTR_URL}',

Press Ctrl-C to abort (${wait}s)
"
for i in $(seq 1 $wait); do sleep 1; echo -n .; done; echo

cd "${HOME}"
mkdir -p jenkins-build && cd jenkins-build/
# create https.key and https.crt
#wget -qO- https://raw.githubusercontent.com/frntn/x509-san/master/gencert.sh | CRT_FILENAME="https" CRT_CN="docker.local" CRT_SAN="DNS:jenkins.docker.local" bash

# from https://docs.docker.com/docker-trusted-registry/quick-start/
echo "role-strategy:2.2.0" > plugins

cat <<EOF >Dockerfile
FROM jenkins:1.625.3

#New plugins must be placed in the plugins file
COPY plugins /usr/share/jenkins/plugins

#The plugins.sh script will install new plugins
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins

#Copy private key and cert to image
#COPY https.crt /var/lib/jenkins/https.crt
#COPY https.key /var/lib/jenkins/https.key

#Configure HTTP off and HTTPS on, using port 8443
#ENV JENKINS_OPTS --httpPort=-1 --httpsPort=8443 --httpsCertificate=/var/lib/jenkins/https.crt --httpsPrivateKey=/var/lib/jenkins/https.key
ENV JENKINS_OPTS --httpPort=8080
EOF

docker build -t "$DTR_URL/$DTR_ORG/$DTR_REPO" .
docker login -e "$DTR_EMAIL" -u "$DTR_USER" -p "$DTR_PASS" "$DTR_URL"
sleep 1 # without we may have the following error : "dial tcp 127.0.1.1:443: connection refused" 

# test the push
docker push "$DTR_URL/$DTR_ORG/$DTR_REPO"

# test the pull
docker rmi  "$DTR_URL/$DTR_ORG/$DTR_REPO"
docker pull "$DTR_URL/$DTR_ORG/$DTR_REPO"

# start the container
# (note: this setup is for demo purpose. IRL you should enable https and use volume for data to persist...)
docker run -p 8080:8080 -p 50000:50000 -d --name jenkins01 "$DTR_URL/$DTR_ORG/$DTR_REPO"

jen=$(ip addr show dev eth1 | grep -E '\<inet\>' | awk '{print $2}' | cut -d'/' -f1)
echo 
echo "Jenkins dashboard => http://$jen:8080"
echo 

: <<HELP

If you get something like

  The push refers to a repository [registry.docker.local/ci-infra/myjenkins] (len: 1)
  5c0e6ed9ae07: Preparing 
  unauthorized: authentication required

Be sure you have precreate the following :
  - "ci-infra" namespace (dashboard->organisation) 
  - "myjenkins" repo (dashboard->organisation->"ci-infra"->new repo)

HELP
