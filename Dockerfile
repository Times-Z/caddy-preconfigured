ARG CADDY_VERSION=2.11.1

FROM golang:alpine3.23 as caddy-builder
ARG CADDY_VERSION

RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest \
    && xcaddy build "v${CADDY_VERSION}" \
        --with github.com/caddy-dns/ovh \
        --with github.com/caddy-dns/azure \
        --with github.com/caddy-dns/cloudflare \
        --with github.com/caddy-dns/duckdns \
        --output /build/caddy

FROM caddy:${CADDY_VERSION}-alpine
ARG USER=www-data
ARG USER_ID=1001

LABEL maintainer="timesz<crashzeus@protonmail.com>"

COPY --from=caddy-builder /build/caddy /usr/bin/caddy
COPY ./Caddyfile /etc/caddy

RUN apk add curl~=8 --no-cache \
    && mkdir -p /var/www/html \
    && adduser -u ${USER_ID} -D -S -G ${USER} ${USER} \
    && chown -R ${USER}:${USER} /etc/caddy /var/www/html /config /data

HEALTHCHECK --interval=1m --timeout=10s --retries=3 CMD [ "curl", "-f", "http://localhost:2019/reverse_proxy/upstreams" ]

CMD [ "caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile" ]
