# Example App on Bare Metal

Scripts to install, configure and run the first responder demo on bare metal. 

## Install

The `install.sh` script 

- installs Apache Kafka
- downloads the PostgreSQL JDBC driver
- builds the first responder demo (backend and simulator)
- installs, patches and configures JBoss EAP

In order to run the script, you'll need

- JBoss EAP 7.4 zip
- JBoss EAP 7.4.3 patch
- JBoss EAP XP4 manager
- JBoss EAP XP4 patch
- Java, Maven & Git

## Uninstall

To undo the installation use the `uninstall.sh` script:

- removes JBoss EAP
- removes Apache Kafka
- removed PostgreSQL JDBC driver
- removes first responder demo

## Start

There are start scripts to start all necessary services. All services, but Postgres are started locally. Postgres is started in a container.   

## Simulator 

Finally you can use `./start-simulator.sh` to start the [simulator](https://github.com/wildfly-extras/first-responder-demo/tree/main/simulator) locally. The simulator listens to http://localhost:8888 by default and exposes a [REST API](https://github.com/wildfly-extras/first-responder-demo/blob/main/simulator/src/main/java/org/cajun/navy/util/GeneratorResource.java) to generate incidents and responders. 
