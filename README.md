# marathon-artifactory-project

- First run marathon-lb :

`dcos package install marathon-lb`

- DCOS doesn't support yet service dependencies, so you'll have to run a mysql first :

`dcos marathon app add mysql.json`

- Run Artifactory and provide the parameters in the json files :
`dcos package install artifactory --options=haexample.json`

If you don't specify options, by default it will run one artifactory-pro instance and you'll have to past the license key in the UI.

# Test it with plain Docker

- create volume
`docker volume create --name artclusterhome`

- export licenses
`export ART_PRIMARY_LICENSE=$(cat ~/license/artifactory-H1.lic)`
`export ART_SECONDARY_LICENSES=$(cat ~/license/artifactory-H2.lic)`

- Run mysql
`docker run --name mysqlart -p 3306:3306 -e MYSQL_ROOT_PASSWORD=jfrog -e MYSQL_DATABASE=root -e MYSQL_DATABASE=artdb -d mysql`

- Run primary node
`docker run -ti --link mysqlart:mysqlart --name artifactoryhaprimary -e DATABASE_CONNECTION_STRING='jdbc:mysql://mysqlart:3306/artdb?characterEncoding=UTF-8&elideSetAutoCommits=true' -e DATABASE_USER='root' -e DATABASE_PASSWORD='jfrog' -e ART_PRIMARY_LICENSE="$ART_PRIMARY_LICENSE" -e ART_LICENSES="$ART_SECONDARY_LICENSES" -v artclusterhome:/var/opt/jfrog/cluster  -p 8089:8081 -p 10042:10042 jfrog-docker-reg2.bintray.io/jfrog/artifactory-ha-primary:4.7.7`

- Run secondary node
`docker run -ti -v artclusterhome:/var/opt/jfrog/cluster --link mysqlart:mysqlart --link artifactoryhaprimary:artifactoryhaprimary -e PRIMARY_BASE_URL='http://artifactoryhaprimary:8081/artifactory' -p 8088:8081 -p 10043:10042 jfrog-docker-reg2.bintray.io/jfrog/artifactory-ha-secondary:4.7.7`

- Connect to mysql
`docker run -it --link mysqlart:mysqlart --net nginxproxy_default --rm mysql sh -c 'exec mysql -h"mysqlart" -P"3306" -uroot -p"jfrog"'
`

