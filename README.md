# Caddy 2 "1 min" setup

[![Build and Publish](https://github.com/Times-Z/caddy-preconfigured/actions/workflows/docker-image.yml/badge.svg)](https://github.com/Times-Z/caddy-preconfigured/actions/workflows/docker-image.yml)

This repository is docker container of [caddy](https://caddyserver.com/) including :
- Ovh dns provider module
- Azure dns provider module
- Cloudflare dns provider module
- php-fpm or reverse proxy preconfiguration

This is the fastest way to provide https protocol in your application ! 🚀✨

## [Configuration](#configuration)
This docker image is configurable by env vars.

### Available Variables

#### Global Variables

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `DOMAIN` | `localhost` | Your domain name such as `foo.bar.domain` |
| `DOMAIN_PORT` | `443` | Listening port for your domain configuration |
| `CADDY_MODE` | `reverse-proxy` | Default snippet used for configuration. Possible values: `reverse-proxy`, `php-fpm`, `html` or `false` (to disable) |
| `CADDY_DOMAIN_EXTRA_CONFIG` | `null` | Custom extra config for domain scope. Use the syntax `{env.XXX}` instead of `{$XXX}` for environment variables. You can use snippets defined in Caddyfile (see [Snippet section](#defined-snippet)). Example: `header x-domain-from "{env.DOMAIN}"` |
| `CADDY_GLOBAL_EXTRA_CONFIG` | `null` | Custom extra global configuration. Use the syntax `{env.XXX}` instead of `{$XXX}` for environment variables. You can use snippets defined in Caddyfile (see [Snippet section](#defined-snippet)). **Tip:** To provide multiline values in docker-compose.yml, use `\|` (not `>` as it doesn't add `\n` at line ends). Example: <br>`CADDY_GLOBAL_EXTRA_CONFIG: \|`<br>&nbsp;&nbsp;`localhost:80 {`<br>&nbsp;&nbsp;&nbsp;&nbsp;`respond "Hello, world!"`<br>&nbsp;&nbsp;`}` |
| `TLS_PROVIDER` | `tls-ovh` | Your TLS provider. Possible values: `tls-ovh`, `tls-azure`, `tls-cloudflare` or `false` (to disable) |
| `WHITELIST_IPS` | `0.0.0.0/0` | List of IP addresses or IP ranges to whitelist (space-separated). Returns 403 for requests not in scope. Examples: `127.0.0.1` (single IP) or `127.0.0.0/24` (IP range). Multiple values: `127.0.0.1 10.0.0.0/24` |

#### Reverse Proxy Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `BACKEND_ENDPOINT` | `nginx:80` | Endpoint to which requests are forwarded, such as `http://foo.bar:8000` or `wordpress:80` |

#### HTML Server Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `WEBROOT` | `/var/www/html` | Default web root for the web server |

#### PHP-FPM Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `WEBROOT` | `/var/www/html` | Default web root for the web server |
| `PHP_FASTCGI` | `php:9000` | PHP FastCGI backend address, such as `unix//run/php/php8.2-fpm.sock` (for socket) or `my-phpfpm-container:9000` (for container) |

#### TLS Provider Variables

##### OVH

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `OVH_ENDPOINT` | `ovh-eu` | OVH API endpoint |
| `OVH_APPLICATION_KEY` | - | OVH application key (required) |
| `OVH_APPLICATION_SECRET` | - | OVH application secret (required) |
| `OVH_CONSUMER_KEY` | - | OVH consumer key (required) |

##### Azure

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `AZURE_TENANT_ID` | - | Azure tenant ID (required) |
| `AZURE_CLIENT_ID` | - | Azure client ID (required) |
| `AZURE_CLIENT_SECRET` | - | Azure client secret (required) |
| `AZURE_SUBSCRIPTION_ID` | - | Azure subscription ID (required) |
| `AZURE_RESOURCE_GROUP_NAME` | - | Azure resource group name (required) |

##### Cloudflare

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `CLOUDFLARE_API_TOKEN` | - | Cloudflare API token (required) |

##### DuckDNS

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `DUCK_DNS_TOKEN` | - | DuckDNS token (required) |


## [Examples](#Examples)

This is an example to provide TLS for qbittorrent web application using reverse-proxy configuration with ip range or specific ip white list

```yml
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      TZ: Europe/Paris
      WEBUI_PORT: 8080
    networks:
      - proxy

  caddy:
    image: ghcr.io/times-z/caddy-preconfigured/caddy:latest
    container_name: caddy
    ports:
      - 80:80
      - 443:443
    environment:
      DOMAIN: "qbittorrent.timesz.fr"
      OVH_APPLICATION_KEY: "my ovh application key"
      OVH_APPLICATION_SECRET: "my ovh application secret"
      OVH_CONSUMER_KEY: "my ovh consumer key"
      BACKEND_ENDPOINT: "qbittorrent:8080"
      WHITELIST_IPS: 192.168.1.0/24 172.18.0.0/24 10.0.1.21
    volumes:
      - caddy_data:/data
    networks:
      - proxy

networks:
  proxy:
    name: proxy

volumes:
  caddy_data:
```

This is an other example to provide a http server with https for my php-fpm container
```yml
services:
  application:
    image: php:8.1.16-fpm
    container_name: php-fpm
    environment:
      TZ: Europe/Paris
    volumes:
      - application_root:/var/www/html:rw
    networks:
      - caddy
  caddy:
    image: ghcr.io/times-z/caddy-preconfigured/caddy:latest
    container_name: caddy
    ports:
      - 80:80
      - 443:443
    environment:
      DOMAIN: "application.timesz.fr"
      CADDY_MODE: "php-fpm"
      OVH_APPLICATION_KEY: "my ovh application key"
      OVH_APPLICATION_SECRET: "my ovh application secret"
      OVH_CONSUMER_KEY: "my ovh consumer key"
      PHP_FASTCGI: "application:9000"
    volumes:
      - caddy_data:/data:rw
      - application_root:/var/www/html:ro
    networks:
      - caddy

networks:
  caddy:
    name: caddy

volumes:
  caddy_data:
  application_root:
```

## [Defined snippets](#defined-snippet)

- `tls-ovh` : use [caddy-dns/ovh](https://github.com/caddy-dns/ovh) plugin to provide TLS
- `tls-cloudflare` : use [caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare) plugin to provide TLS
- `tls-azure` : use [caddy-dns/azure](https://github.com/caddy-dns/azure) plugin to provide TLS
- `reverse-proxy` : use [reverse_proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy) directive to provide a simple reverse proxy to a backend wich defined with `BACKEND_ENDPOINT` environnement variable (see [configuration](#configuration))
- `php-fpm` : provide a default configuration for php (see [configuration](#configuration))
- `html` : simple html/css/js server
- `whitelist-ip` : use directive not remote_ip to block all request that is not whitelisted client. First param is trusted IPs
