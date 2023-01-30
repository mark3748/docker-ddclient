# docker-ddclient

ddclient Docker image based on Alpine and latest github fork of ddclient

---

## Quick-start
simply run the container using the following command:

`docker run -d --restart unless-stopped --name ddclient -v /path/to/config:/config mark3748/ddclient`

This will utilize the `ddclient.conf` file in `/path/to/config` or create the default in that location. If you need to make changes to the config, edit `ddclient.conf` and start or restart the container.

---

## Configuration

For configuration of `ddclient.conf`, please see the [ddclient](https://github.com/ddclient/ddclient) github page or the [original ddclient](https://ddclient.net/) docs.

### Example for Cloudflare

```
##
## CloudFlare (www.cloudflare.com)
##
use=web
ssl=yes
protocol=cloudflare,
server=api.cloudflare.com/client/v4
login=your-login-email,     
password=APIKey
zone=domain.tld,
domain.tld,my.domain.tld
```

---

## docker-compose

```version: '3'
services:
  ddclient:
    image: mark3748/ddclient:latest
    container_name: ddclient
    volumes: 
      - /path/to/config:/config
    restart: unless-stopped```
