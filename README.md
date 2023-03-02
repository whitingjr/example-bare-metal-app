# Example App on Bare Metal

Scripts to install, configure and run the first responder demo on bare metal. 

## Setup

To get everything up and running use

```shell
./install-eap.sh
./start-all.sh
```

The installation script installs, patches and configures JBoss EAP. The result is a JBoss EAP 7.4.3 standalone server with XP4 and the deployed first responder demo.

In order to run the script, you'll need

- JBoss EAP 7.4 zip
- JBoss EAP 7.4.3 patch
- JBoss EAP XP4 manager
- JBoss EAP XP4 patch
- Java, Maven & Git

The start script starts PostgreSQL, Zookeeper and Kafka using Docker Compose and JBoss EAP locally. 

## Cleanup

To stop and clean up, stop JBoss EAP manually and then call 

```shell
./stop-all.sh
./uninstall-eap.sh
```

The uninstallation script simply removes the JBoss EAP folder.  
