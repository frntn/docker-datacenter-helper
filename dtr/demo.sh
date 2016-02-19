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
echo $'junit:1.9\nwindows-slaves:1.1\njunit-attachments:1.3\nmultiple-scms:0.5\nmashup-portlets-plugin:1.0.6\ncvs:2.12\nscm-api:1.0\nldap:1.11\nbuild-pipeline-plugin:1.4.9\nmatrix-auth:1.2\njquery:1.11.2-0\nactive-directory:1.41\nsonargraph-plugin:1.6.4\ntranslation:1.12\nbuild-monitor-plugin:1.7+build.172\nparameterized-trigger:2.29\nexternal-monitor-job:1.4\nsimple-theme-plugin:0.3\nsubversion:2.5.4\njenkins-flowdock-plugin:1.1.8\ngroovy:1.27\nxunit:1.98\npam-auth:1.2\nssh-credentials:1.11\nsonar:2.3\nansicolor:0.4.2\ncredentials:1.24\ndashboard-view:2.9.6\nssh-slaves:1.10\nParameterized-Remote-Trigger:2.2.2\ngravatar:2.1\ngroovy-postbuild:2.2.2\ncobertura:1.9.7\njavadoc:1.3\nperformance:1.13\ngit-parameter:0.4.0\nshared-workspace:1.0.1\nproject-description-setter:1.1\njquery-ui:1.0.2\nmaven-plugin:2.12.1\nant:1.2\nmailer:1.16\ngreenballs:1.15\npromoted-builds:2.24\ngit:2.4.0\nantisamy-markup-formatter:1.3\nwebsocket:1.0.6\nmapdb-api:1.0.6.0\nmatrix-project:1.6\ntoken-macro:1.11\nscript-security:1.15\ngit-client:1.19.0' > plugins

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
