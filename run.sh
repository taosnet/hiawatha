#!/bin/sh

cd /certs
if [ -e key.pem ]; then
	cp key.pem hiawatha.pem
	echo >>hiawatha.pem
	cat cert.pem >>hiawatha.pem
	echo >>hiawatha.pem
	cat chain.pem >>hiawatha.pem
fi
/usr/sbin/hiawatha -d -c /etc/hiawatha
