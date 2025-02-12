# Caddy 2 "1 min" setup

[![Build and Publish](https://github.com/Times-Z/caddy-preconfigured/actions/workflows/docker-image.yml/badge.svg)](https://github.com/Times-Z/caddy-preconfigured/actions/workflows/docker-image.yml)

This repository is docker container of [caddy](https://caddyserver.com/) including :
- Ovh dns provider module
- Azure dns provider module
- Cloudflare dns provider module
- php-fpm or reverse proxy preconfiguration

This is the fastest way to provide https protocol in your application ! 🚀✨

## [Configuration](#configuration)
This docker image is configuratble by env vars

Availaible vars :

- Global vars :

    - `DOMAIN` :

        Default value is `localhost`

        This is your domain name such as `foo.bar.domain`

    - `DOMAIN_PORT` :

        Default value is `443`

        Listening port for your domain configuration

    - `CADDY_MODE` : 

        Default value is `reverse-proxy`

        This is the default snippet used for configuration

        Possible value : `reverse-proxy`, `php-fpm`, `html` or `false` (to disable)

    - `CADDY_DOMAIN_EXTRA_CONFIG` :

        Default value is `nul`

        Give caddy custom extra config for domain scope

        Example :

        ```sh
          header x-domain-from "{env.DOMAIN}"
        ```

        Note: Use the syntaxe {env.XXX} instead of {$XXX} to use environnement variable for this block

        You can use snippet that is defined in CaddyFile (view [Snippet section](#defined-snippet))

    - `CADDY_GLOBAL_EXTRA_CONFIG` :

        Default value is `null`

        Give caddy custom extra global configuration such as

        ```sh
        localhost:80 {
          respond "Hello, world!"
        }
        ```

        Note: Use the syntaxe {env.XXX} instead of {$XXX} to use environnement variable for this block

        Tips: to provide multiline value for a env var in a docker-compose.yml use "`|`" like
        ```yml
          CADDY_DOMAIN_EXTRA_CONFIG: |
            localhost:80 {
              respond "Hello, world!"
            }
        ```

        Dot not use the `>` because he not add \n at the end of each line it cause some issues in many case

        You can use snippet that is defined in CaddyFile (view [Snippet section](#defined-snippet))

    - `TLS_PROVIDER` :

        Default value is `tls-ovh`

        The is your tls provider

        Possible value : `tls-ovh`, `tls-azure`, `tls-cloudflare` or `false` (to disable)

    - `WHITELIST_IPS` :

      Default value is `0.0.0.0/0` (all ip and ip scope is allowed)

      Provide a list of ip or ip range to whitelist

      Give 403 return response for all request that is not in scope

      You can provide ip like `127.0.0.1` or scope like `127.0.0.0/24`

      You need to sperate each by space such as example `127.0.0.1 10.0.0.0/24`

- Caddy reverse-proxy specific :
    - `BACKEND_ENDPOINT` :

        Default value is `nginx:80`

        This is your endpoint to which requests are forwarded such as `http://foo.bar:8000` or `wordpress:80`

- Caddy reverse-proxy specific :
    - `WEBROOT` :

        Default value is `/var/www/html`

        Set the default web root for the web server

- Caddy php-fpm specific :
    - `WEBROOT` :

        Default value is `/var/www/html`

        Set the default web root for the web server

    - `PHP_FASTCGI` : 

        Default value is `php:9000`

        This is your php fastcgi backend adress such as `unix//run/php/php8.2-fpm.sock` if running socket or `my-phpfpm-container:9000`

- TLS provider specific :
    - OVH :
        - `OVH_ENDPOINT` : default `ovh-eu`
        - `OVH_APPLICATION_KEY`
        - `OVH_APPLICATION_SECRET`
        - `OVH_CONSUMER_KEY`
    - Azure :
        - `AZURE_TENANT_ID`
        - `AZURE_CLIENT_ID`
        - `AZURE_CLIENT_SECRET`
        - `AZURE_SUBSCRIPTION_ID`
        - `AZURE_RESOURCE_GROUP_NAME`
    - Cloudflare :
        - `CLOUDFLARE_API_TOKEN`
    - DuckDNS :
        - `DUCK_DNS_TOKEN`


## [Examples](#Examples)

This is an example to provide TLS for qbittorrent web application using reverse-proxy configuration with ip range or specific ip white list

```yml
version: "3.8"

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
version: "3.8"

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
