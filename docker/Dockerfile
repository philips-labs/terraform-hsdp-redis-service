FROM golang:1.20.4-alpine as builder
WORKDIR /go/src/github.com/oliver006/redis_exporter/
RUN apk --no-cache add ca-certificates git
RUN git clone https://github.com/oliver006/redis_exporter.git .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$GOARCH go build -o /redis_exporter .

FROM golang:1.20.4-alpine as builder2
WORKDIR /build
COPY sd/ .
RUN go mod download -x
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$GOARCH go build -o /sd


## Build final image
FROM alpine:3.18.0
LABEL maintainer="andy.lo-a-foe@philips.com"
RUN apk add --no-cache ca-certificates supervisor jq curl && rm -rf /tmp/* /var/cache/apk/*

RUN mkdir -p /sidecars/bin /sidecars/supervisor/conf.d sidecars/etc

COPY --from=builder /redis_exporter /sidecars/bin
COPY --from=builder2     /sd     /sidecars/bin

COPY supervisord_configs/ /sidecars/supervisor/conf.d

EXPOSE 9121

COPY supervisord.conf /etc/
CMD ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]