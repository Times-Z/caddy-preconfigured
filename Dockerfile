ARG CADDY_VERSION=2.6.4


FROM golang:alpine3.17 as caddy-builder
ARG CADDY_VERSION

RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest \
    && xcaddy build "v${CADDY_VERSION}" \
        --with github.com/caddy-dns/ovh \
        --output /build/caddy


FROM caddy:${CADDY_VERSION}-alpine

LABEL maintainer="timesz<crashzeus@protonmail.com>"

COPY --from=caddy-builder /build/caddy /usr/bin/caddy
COPY ./Caddyfile /etc/caddy

CMD [ "caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile" ]
