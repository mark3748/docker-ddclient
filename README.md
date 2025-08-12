# docker-ddclient

Modern ddclient Docker image based on Alpine Linux 3.20 with ddclient v4.0.0

## Features

- **Latest ddclient v4.0.0** with all recent bug fixes and improvements
- **Multi-stage Docker build** for smaller, more secure images
- **Non-root execution** for enhanced security
- **Proper error handling and logging** with structured output
- **Graceful shutdown** with signal handling
- **Built-in health checks** for container monitoring
- **Configuration validation** on startup

---

## Quick-start

Run the container using the following command:

```bash
docker run -d --restart unless-stopped --name ddclient -v /path/to/config:/config mark3748/ddclient
```

This will utilize the `ddclient.conf` file in `/path/to/config` or create the default configuration in that location. If you need to make changes to the config, edit `ddclient.conf` and restart the container.

---

## Breaking Changes from Previous Version

This image has been updated to ddclient v4.0.0 which includes several breaking changes:

- **SSL is enabled by default** - No need to explicitly set `ssl=yes`
- **Configuration file location** - ddclient now expects config at `/etc/ddclient/ddclient.conf` (handled automatically by the container)
- **Improved protocol support** - Several DNS providers have updated implementations

---

## Configuration

For detailed configuration of `ddclient.conf`, see the official [ddclient documentation](https://ddclient.net/) and [GitHub repository](https://github.com/ddclient/ddclient).

### Example for Cloudflare (v4.0.0 syntax)

```ini
# Global settings
daemon=300
use=web

# Cloudflare configuration
protocol=cloudflare
server=api.cloudflare.com/client/v4
zone=domain.tld
login=your-login-email
password=your-api-token-or-global-api-key
domain.tld,my.domain.tld
```

**Note:** For better security, use Cloudflare API tokens instead of Global API Keys.

---

## Docker Compose

```yaml
version: '3.8'
services:
  ddclient:
    image: mark3748/ddclient:latest
    container_name: ddclient
    volumes: 
      - /path/to/config:/config
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/usr/bin/ddclient", "-query"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
```

---

## Security

This image runs as a non-root user (`ddclient:ddclient`, UID/GID 1000) for enhanced security. All necessary directories are pre-configured with appropriate permissions.

## Health Monitoring

The container includes a built-in health check that verifies ddclient can query your current IP address. You can monitor this with:

```bash
docker inspect --format='{{.State.Health.Status}}' ddclient
```

## Logging

The container provides structured logging with timestamps and log levels:

```
2025-01-19 10:30:00 [ddclient-docker] INFO: Starting ddclient.sh
2025-01-19 10:30:01 [ddclient-docker] INFO: Configuration file validated: /etc/ddclient/ddclient.conf
2025-01-19 10:30:02 [ddclient-docker] INFO: Starting ddclient daemon loop (interval: 300s)
```

## Troubleshooting

- **Configuration errors**: Check logs for validation failures on startup
- **Permission issues**: Ensure your config directory is readable by UID 1000
- **Network issues**: Verify your DNS provider settings and API credentials
