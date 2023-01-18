FROM alpine:latest AS production

RUN apk add curl bash jq

WORKDIR /app/
COPY ./start.sh ./

ENTRYPOINT ["/app/start.sh"]