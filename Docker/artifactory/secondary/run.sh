#!/bin/bash

ha_home=/var/opt/jfrog/cluster

node=$(date +%s)

cat >/etc/opt/jfrog/artifactory/ha-node.properties <<EOF
node.id="$node"
cluster.home=$ha_home
primary=false
context.url=http://$(hostname -I|awk '{print $1}'):8081/artifactory
membership.port=10042
EOF

echo "PRIMARY_BASE_URL : $PRIMARY_BASE_URL"

echo "Checking availability first : $PRIMARY_BASE_URL"

response=$(curl -uadmin:password -X POST $PRIMARY_BASE_URL/api/plugins/execute/getLicense?params=$node)
responseStatus=$?
if [ $responseStatus -ne 0 ]; then
	echo "Couldn't retrieve the license from the primary, got response from server $response "
elif [ ! -z "$response" ]; then
	echo "$response" > /etc/opt/jfrog/artifactory/artifactory.lic
else
	echo "License not found from primary"
fi

/opt/jfrog/artifactory/bin/artifactory.sh