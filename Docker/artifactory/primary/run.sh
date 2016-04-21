#!/bin/bash

ha_home=/var/opt/jfrog/cluster

node="art-primary"

# Set the licence key
echo "$ART_PRIMARY_LICENSE" > /etc/opt/jfrog/artifactory/artifactory.lic

# Create the cluster.properties the first time
if [ ! -f $ha_home/ha-etc/cluster.properties ]; then
    echo security.token=$(uuidgen) >$ha_home/ha-etc/cluster.properties
fi

# Recreate the storage.propreties if the necessary env var are set
if [ ! -z "$DATABASE_CONNECTION_STRING" ] && [ ! -z "$DATABASE_USER" ] && [ ! -z "$DATABASE_PASSWORD" ]; then
cat >$ha_home/ha-etc/storage.properties <<EOF
type=mysql
driver=com.mysql.jdbc.Driver
url=$DATABASE_CONNECTION_STRING
username=$DATABASE_USER
password=$DATABASE_PASSWORD
EOF
fi

cat >/etc/opt/jfrog/artifactory/ha-node.properties <<EOF
node.id="art-primary"
cluster.home=$ha_home
primary=true
context.url=http://$(hostname -I|awk '{print $1}'):8081/artifactory
membership.port=10042
EOF

/opt/jfrog/artifactory/bin/artifactory.sh

#. /etc/init.d/artifactory wait
