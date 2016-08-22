FROM alpine:edge
MAINTAINER Chris Batis <clbatis@taosnet.com>

RUN apk update && \
	apk add musl libxslt zlib libxml2 mbedtls && \
	apk add hiawatha --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted && \
	rm -rf /var/cache/apk/* && \
	addgroup -S www-data && \
	adduser -S -G www-data -g "Web Server" -h "/domains" web-srv && \
	mkdir -p /var/www/domain/public /var/www/domain/log /certs

COPY hiawatha /etc/hiawatha/
COPY hiawatha.pem /certs
COPY run.sh /run.sh

EXPOSE 80 443

ENTRYPOINT ["/run.sh"]
