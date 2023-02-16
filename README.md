# Caddy 2 "1 min" setup

[![Docker Image CI](https://github.com/Times-Z/caddy-preconfigured/actions/workflows/docker-image.yml/badge.svg)](https://github.com/Times-Z/caddy-preconfigured/actions/workflows/docker-image.yml)

This repository is docker container of [caddy](https://caddyserver.com/) including :
- Ovh dns provider module
- Azure dns provider module
- Cloudflare dns provider module
- php-fpm or reverse proxy preconfiguration

This is the fastest way to provide https protocol in your application ! 🚀✨

## Configuration
This docker image is configuratble by env vars

Availaible vars :

- Global vars :

    - `DOMAIN` :

        Default value is `localhost`

        This is your domain name such as `foo.bar.domain`

    - `CADDY_MODE` : 

        Default value is `reverse-proxy`

        This is the default snippet used for configuration

        Possible value : `reverse-proxy`, `php-fpm`

    - `TLS_PROVIDER` :

        Default value is `tls-ovh`

        The is your tls provider

        Possible value : `tls-ovh`, `tls-azure`, `tls-cloudflare`

- Caddy reverse-proxy specific :
    - `BACKEND_ENDPOINT` :

        Default value is `nginx:80`

        This is your endpoint to which requests are forwarded such as `http://foo.bar:8000` or `wordpress:80`

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


## Examples

This is an example to provide TLS for qbittorrent web application using reverse-proxy configuration

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