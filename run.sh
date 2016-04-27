#!/bin/bash

#Start Postgres
/etc/init.d/postgresql start
#Start Elastic Search
$1/elasticsearch-1.7.1/bin/elasticsearch -d
#Start Redis
/etc/init.d/redis-server start
# eGov product code base
git clone -b master --single-branch https://github.com/egovernments/eGov.git ${HOME_PATH}/eGov-repo
#Build And Deploy
mvn clean -f $1/eGov-repo/egov/pom.xml
git --git-dir=$1/eGov-repo/.git pull --rebase
echo "db.url=jdbc:postgresql://localhost:5432/postgres" > $1/eGov-repo/egov/egov-config/src/test/resources/config/egov-erp-root.properties \
	&& echo "db.username=postgres" >> $1/eGov-repo/egov/egov-config/src/test/resources/config/egov-erp-root.properties \
	&& echo "db.password=postgres" >> $1/eGov-repo/egov/egov-config/src/test/resources/config/egov-erp-root.properties
mvn clean install -f $1/eGov-repo/egov/pom.xml -U -s $1/eGov-repo/egov/settings.xml -Ddb.url=jdbc:postgresql://localhost:5432/postgres -Ddb.password=postgres -Ddb.user=postgres -Ddb.driver=org.postgresql.Driver -Dmaven.test.failure.ignore=false -Dmaven.javadoc.skip=true
#copy EAR to wildfly
if [ $? -eq 0 ]
then
	cp -rpf $1/eGov-repo/egov/egov-ear/target/*.ear $2/standalone/deployments/egov-erp.ear
	# Strat the deployment
	$2/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0
fi
