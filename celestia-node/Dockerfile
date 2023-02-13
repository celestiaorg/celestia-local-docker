FROM golang:alpine AS development
ARG arch=x86_64

# ENV CGO_ENABLED=0

RUN set -eux; \
    apk add --no-cache \
    git \
    openssh \
    bash \
    ca-certificates \
    build-base \
    && mkdir -p /build/ 

ARG NODE_GIT_TAG

# RUN git clone https://github.com/celestiaorg/celestia-node.git \
#     && cd celestia-node \
#     && git checkout tags/${NODE_GIT_TAG} \
#     && make build \
#     && make cel-key \
#     && cp build/celestia /build/ \
#     && cp cel-key /build/

RUN git clone https://github.com/derrandz/celestia-node.git \
    && cd celestia-node \
    && git checkout 034f58cb757f43bcefa57076092dd489531e4185 \
    && make build \
    && make cel-key \
    && cp build/celestia /build/ \
    && cp cel-key /build/

#----------------------------#

FROM alpine:latest AS production

RUN apk add curl bash jq

WORKDIR /app/
COPY --from=development /build .
COPY ./start.sh ./

ENV BIN_PATH="/app/celestia"
ENV BIN_CELKEY_PATH="/app/cel-key"

ENTRYPOINT ["/app/start.sh"]