#!/bin/sh

#The debian package does not start up the service by default. 
#The reason for this is to prevent the instance to accidentally join a cluster, 
#without being configured appropriately

curl -OL https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.1.zip
unzip elasticsearch-* && rm -f elasticsearch-*.zip
mv elasticsearch-1.7.1/ elasticsearch/

