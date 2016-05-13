#!/bin/bash

ha_home=/var/opt/jfrog/cluster

: ${ART_LOGIN:=admin}
: ${ART_PASSWORD:=password}

node=$(date +%s$RANDOM)

cat >/etc/opt/jfrog/artifactory/ha-node.properties <<EOF
node.id="$node"
cluster.home=$ha_home
primary=false
context.url=http://$(hostname -I|awk '{print $1}'):8081/artifactory
membership.port=10042
EOF

function waitForPrimaryNode {
	log "WAITING FOR PRIMARY NODE : $PRIMARY_BASE_URL"
	until $(curl -u$ART_LOGIN:$ART_PASSWORD --output /dev/null --silent --fail "$PRIMARY_BASE_URL/api/system/ping")
	do
		echo "."
		sleep 2
	done
	log "PRIMARY NODE IS UP !"
}

function log {
	echo "[SECONDARY $node] $1"
}

function getLicenseFromPrimary {
	local response=$(curl -u$ART_LOGIN:$ART_PASSWORD -S --fail -X POST $PRIMARY_BASE_URL/api/plugins/execute/getLicense?params=$node)
	local responseStatus=$?
	if [ $responseStatus -ne 0 ]; then
		log "Couldn't retrieve the license from the primary, got response from server $response "
		echo $responseStatus
	elif [ ! -z "$response" ]; then
		echo -n "$response" > /etc/opt/jfrog/artifactory/artifactory.lic
		echo "0"
	else
		log "License not found from primary"
		echo $responseStatus
	fi	
}

function getLicenseFromPrimaryOrDieTrying {
	local numberOfRetries=5
	local retry=0
	local sleepingTime=15
	while [ "$retry" -lt "$numberOfRetries" ]; do
		local lic=$(getLicenseFromPrimary)
		echo "return code from getLic : $lic"
		if [ "$lic" == "0" ]; then
			return 0
		fi
		retry=$((retry+1))
		log "Retry $retry getting license from primary in $sleepingTime seconds"
		sleep $sleepingTime
	done
	log "Have tried $numberOfRetries to get a license from primary without success, now exiting"
	exit 1
}

waitForPrimaryNode
getLicenseFromPrimaryOrDieTrying

/opt/jfrog/artifactory/bin/artifactory.sh

