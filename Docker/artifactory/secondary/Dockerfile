# Dockerfile for a primary node
FROM jfrog-docker-reg2.bintray.io/jfrog/artifactory-pro:4.7.7
MAINTAINER alexist@jfrog.com

ENV ARTIFACTORY_HOME /var/opt/jfrog/artifactory
ENV ART_TOMCAT_HOME /opt/jfrog/artifactory

# copy the run script
COPY run.sh /run.sh

# set up mysql in artifactory
RUN curl -L -o $ARTIFACTORY_HOME/tomcat/lib/mysql-connector-java-5.1.38.jar https://bintray.com/artifact/download/bintray/jcenter/mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar && \
	cp $ARTIFACTORY_HOME/misc/db/mysql.properties $ARTIFACTORY_HOME/etc/storage.properties

# Still needed ?
COPY server.xml /opt/jfrog/artifactory/tomcat/conf/server.xml

# Change permission to all this directories
RUN chown -R artifactory: $ARTIFACTORY_HOME && \
	chown -R artifactory: $ART_TOMCAT_HOME

USER artifactory

# This should be mapped to a shared NFS mounted on the host
EXPOSE 8081 10042

CMD /run.sh