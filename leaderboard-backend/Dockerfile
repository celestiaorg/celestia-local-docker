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

RUN git clone https://github.com/celestiaorg/leaderboard-backend.git \
    && cd leaderboard-backend \
    && go build -mod=readonly -buildvcs=false -o /build/app .

#----------------------------#

FROM alpine:latest AS production

RUN apk add curl

WORKDIR /app/
COPY --from=development /build .


ENTRYPOINT ["./app"]