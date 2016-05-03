# Dockerfile for a primary node
FROM jfrog-docker-reg2.bintray.io/jfrog/artifactory-pro:4.7.5
MAINTAINER alexist@jfrog.com

ENV ARTIFACTORY_HOME /var/opt/jfrog/artifactory
ENV CLUSTER_HOME /var/opt/jfrog/cluster
ENV ART_TOMCAT_HOME /opt/jfrog/artifactory
# create the $CLUSTER_HOME directory structure and copy the files
RUN mkdir -p $CLUSTER_HOME/{ha-etc/{UI,plugins},ha-data/{filestore,tmp},ha-backup}

# copy the run script
COPY run.sh /run.sh

# set up mysql in artifactory
RUN curl -L -o $ARTIFACTORY_HOME/tomcat/lib/mysql-connector-java-5.1.38.jar https://bintray.com/artifact/download/bintray/jcenter/mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar
RUN cp $ARTIFACTORY_HOME/misc/db/mysql.properties $ARTIFACTORY_HOME/etc/storage.properties
RUN cp -R $ARTIFACTORY_HOME/etc/* $CLUSTER_HOME/ha-etc/.

# Installing the bucket plugin
RUN mkdir -p $ARTIFACTORY_HOME/etc/plugins
#RUN curl -o $CLUSTER_HOME/ha-etc/plugins/licensesBucket.groovy https://raw.githubusercontent.com/alextu/artifactory-user-plugins/licensesBucket/ha/licensesBucket/licensesBucket.groovy
COPY licensesBucket.groovy $CLUSTER_HOME/ha-etc/plugins/licensesBucket.groovy

# Still needed ?
COPY server.xml /opt/jfrog/artifactory/tomcat/conf/server.xml

# Change permission to all this directories
RUN chown -R artifactory: $CLUSTER_HOME
RUN chown -R artifactory: $ARTIFACTORY_HOME
RUN chown -R artifactory: $ART_TOMCAT_HOME

USER artifactory

# This should be mapped to a shared NFS mounted on the host
VOLUME $CLUSTER_HOME
EXPOSE 8081 10042

CMD /run.sh