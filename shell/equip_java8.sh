#!/bin/sh
sudo echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt-get update -y
sudo apt-get install oracle-java8-installer oracle-java8-set-default oracle-java8-unlimited-jce-policy -y

