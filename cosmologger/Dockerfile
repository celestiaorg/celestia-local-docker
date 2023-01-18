# FROM golang:alpine3.15 AS development
FROM golang:alpine AS development
ARG arch=x86_64

RUN set -eux; \
    apk add --no-cache \
    git \
    openssh \
    ca-certificates \
    build-base \
    && mkdir -p /build/ 

RUN git clone https://github.com/celestiaorg/cosmologger.git \
    && cd cosmologger \
    && go build -mod=readonly -buildvcs=false -o /build/app . \
    && cp conf.json /build/

#----------------------------#

FROM alpine:latest AS production

WORKDIR /app/
COPY --from=development /build .

ENTRYPOINT ["./app"]