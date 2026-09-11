ARG CADDY_VERSION=2.11.4

FROM golang:alpine3.24@sha256:cf6fca6641884b8433441b2b0652976f975e1d0fdd26d177eaaf8596087f3125 AS caddy-builder
ARG CADDY_VERSION

# hadolint global ignore=DL3062
# Version is already pined to latest
RUN set -xe; \
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest \
    && xcaddy build "v${CADDY_VERSION}" \
        --with github.com/caddy-dns/ovh \
        --with github.com/caddy-dns/azure \
        --with github.com/caddy-dns/cloudflare \
        --with github.com/caddy-dns/duckdns \
        --with github.com/caddy-dns/njalla \
        --with github.com/mholt/caddy-dynamicdns \
        --with github.com/mholt/caddy-ratelimit \
        --output /build/caddy

FROM caddy:${CADDY_VERSION}-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648
ARG USER=www-data
ARG USER_ID=1001

LABEL maintainer="timesz<crashzeus@protonmail.com>"

COPY --from=caddy-builder /build/caddy /usr/bin/caddy
COPY ./Caddyfile /etc/caddy

RUN set -xe; \
    apk add curl~=8 zlib=1.3.2-r0 --no-cache \
    && mkdir -p /var/www/html \
    && adduser -u ${USER_ID} -D -S -G ${USER} ${USER} \
    && chown -R ${USER}:${USER} /etc/caddy /var/www/html /config /data

HEALTHCHECK --interval=1m --timeout=10s --retries=3 CMD [ "curl", "-f", "http://localhost:2019/reverse_proxy/upstreams" ]

CMD [ "caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile" ]
