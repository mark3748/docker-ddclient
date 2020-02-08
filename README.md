# docker-ddclient

ddclient Docker image based on Alpine and latest github fork of ddclient
---
## Quick-start
simply run the container using the following command:
`docker run -d --restart unless-stopped --name ddclient -v /path/to/config:/config mark3748/ddclient`

this will utilize the `ddclient.conf` file in `/path/to/config` or create the default in that location. If you need to make changes to the config, edit `ddclient.conf` and start or restart the container.
---
## docker-compose

```version: '3'
services:
  ddclient:
    image: mark3748/ddclient:v3.9.1
    container_name: ddclient
    volumes: 
      - /path/to/config:/config
    restart: unless-stopped```
