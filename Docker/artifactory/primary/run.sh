#!/bin/bash

CLUSTER_HOME=/var/opt/jfrog/cluster

node="art-primary"

# Set the licence key
echo -n "$ART_PRIMARY_LICENSE" > /etc/opt/jfrog/artifactory/artifactory.lic

# Create the cluster.properties the first time
if [ ! -f $CLUSTER_HOME/ha-etc/cluster.properties ]; then
	mkdir -p $CLUSTER_HOME/{ha-etc/{UI,plugins},ha-data/{filestore,tmp},ha-backup}
    echo security.token=$(uuidgen) >$CLUSTER_HOME/ha-etc/cluster.properties
    cp -R /var/opt/jfrog/artifactory/etc/* $CLUSTER_HOME/ha-etc/.
fi

# Recreate the storage.propreties if the necessary env var are set
if [ ! -z "$DATABASE_CONNECTION_STRING" ] && [ ! -z "$DATABASE_USER" ] && [ ! -z "$DATABASE_PASSWORD" ]; then
cat >$CLUSTER_HOME/ha-etc/storage.properties <<EOF
type=mysql
driver=com.mysql.jdbc.Driver
url=$DATABASE_CONNECTION_STRING
username=$DATABASE_USER
password=$DATABASE_PASSWORD
EOF
fi

cat >/etc/opt/jfrog/artifactory/ha-node.properties <<EOF
node.id="art-primary"
cluster.home=$CLUSTER_HOME
primary=true
context.url=http://$(hostname -I|awk '{print $1}'):8081/artifactory
membership.port=10042
EOF

# Wait for mysql
# Extract mysql hostname and port from the jdbc url
mysql_host_port=$(echo $DATABASE_CONNECTION_STRING | sed -e 's,^jdbc:mysql:\/\/\(.*\)$,\1:,g' | cut -d/ -f1)
echo "mysql host : $mysql_host_port"
while ! curl -s "$mysql_host_port" > /dev/null; do echo 'waiting for mysql'; sleep 3; done

/opt/jfrog/artifactory/bin/artifactory.sh
