#!/bin/sh

wget http://downloads.egovernments.org/wildfly-9.0.0.Final.zip
sudo unzip wildfly-9.0.0.Final.zip -d /opt
sudo ln -s /opt/wildfly-9.0.0.Final /opt/wildfly
rm wildfly-9.0.0.Final.zip
