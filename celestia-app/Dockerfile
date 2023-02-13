FROM golang:alpine AS development
ARG arch=x86_64

# ENV CGO_ENABLED=0

RUN set -eux; \
    apk add --no-cache \
    git \
    openssh \
    ca-certificates \
    build-base \
    && mkdir -p /build/ 

ARG APP_GIT_TAG

RUN git clone https://github.com/celestiaorg/celestia-app.git \
    && cd celestia-app \
    && git checkout tags/${APP_GIT_TAG} -b ${APP_GIT_TAG} \
    && make build \
    && cp build/celestia-appd /build/

#----------------------------#

FROM alpine:latest AS production

RUN apk add bash curl

WORKDIR /app/
COPY --from=development /build .
COPY ./start.sh ./keys.sh ./

ENV BIN_PATH="/app/celestia-appd"

ENTRYPOINT ["/app/start.sh"]