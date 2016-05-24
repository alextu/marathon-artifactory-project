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
`docker run --name mysqlart -e MYSQL_ROOT_PASSWORD=jfrog -e MYSQL_DATABASE=root -d mysql`

- Run primary node
`docker run -ti --link mysqlart:mysqlart --name artifactoryhaprimary -e DATABASE_CONNECTION_STRING='jdbc:mysql://mysqlart/artdb?characterEncoding=UTF-8&elideSetAutoCommits=true' -e DATABASE_USER='root' -e DATABASE_PASSWORD='jfrog' -e ART_PRIMARY_LICENSE="$ART_PRIMARY_LICENSE" -e ART_LICENSES="$ART_SECONDARY_LICENSES" -p 8089:8081 artifactoryhaprimary:4.7.5`

- Run secondary node
`docker run -ti -v artclusterhome:/var/opt/jfrog/cluster --link mysqlart:mysqlart --link artifactoryhaprimary:artifactoryhaprimary -e PRIMARY_BASE_URL='http://artifactoryhaprimary:8081/artifactory' -p 8088:8081 artifactoryhasecondary:4.7.5`

- Run Nginx as LB
`docker run -d -p 80:80 --link artifactoryhaprimary:artifactoryhaprimary -e ART_PRIMARY_NODE_HOST_PORT='192.168.99.100:8089' -e ART_SERVER_NAME='192.168.99.100' -e ART_REVERSE_PROXY_METHOD='SUBDOMAIN' -e ART_LOGIN='admin' -e ART_PASSWORD='password' alexistjfrog-docker-registry.bintray.io/artifactoryhanginx:1.10.0 `

- Connect to mysql
`docker run -it --link mysqlart:mysqlart --net nginxproxy_default --rm mysql sh -c 'exec mysql -h"mysqlart" -P"3306" -uroot -p"jfrog"'
`

