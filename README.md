# Description

Provides a basic framework or quickly creating a hiawatha server with your website. It provides automatic integration with [Let's Encrypt Certificates](#ssl-with-lets-encrypt).

You can also setup a site to utilize hiawatha as an application level firewall for your web app. See the section on [Reverse Proxying](#reverse-proxy).

Also provides a basic set of utilities to allow you to easily modify the configuration of your site(s) using **docker exec**.

You can use the envirnomental variables to modify properties about the site. See the section below.

This container does **NOT** have php installed in any form. If you wish to use php in your site, install php5-fpm via apk. 

# Usage

There are two ways to build a site using this image:

  1. Use a data volume for your web app.
  1. Extend the image with your own image.

## Using a data volume

To use a data volume for you web app:
```
docker run --name mysite.com -d p 80:80 -e HTTP_DOMAIN=mysite.com \
    -v /path/to/webapp:/var/www/mysite.com/public:Z taosnet/hiawatha
```

## Extending the Image

Create a Dockerfile:

```
FROM taosnet/hiawatha

RUN /usr/bin/addSite mysite.com
COPY webapp /var/www/mysite.com/public
```
Build the image:
```
docker build -t taosnet/mysite .
```

Run the site:

```
docker run --name mysite.com -d -p 80:80 taosnet/mysite
```

## SSL with Lets Encrypt

If the files **privkey.pem**, **cert.pem**, and **privkey.pem** are in _/etc/hiawatha/tls_, then a hiawatha compatible certificate will be automatically built, and SSL will be enabled for the container.

### Example using certbot

Assuming that the container is already running from the command:

```
docker run --name mysite.com -d -p 80:80 -p 443:443 -e HTTP_DOMAIN=mysite.com \
    -v /path/to/webapp:/var/www/mysite.com/public:Z -v certs:/etc/hiawatha/tls taosnet/hiawatha
```

The tasks to enable https on this container are:

1. Obtain a certificate.
1. Copy the certificate, private key, chain to the proper location.
1. Restart the container to use the new certificate.

```
docker run --rm -v letsencrypt:/etc/letsencrypt -v /path/to/webapp:/webroot \
    certbot/certbot certonly --webroot -w /webroot -d mysite.com
docker run --rm -v letsencrypt:/etc/letsencrypt -v certs:/certs \
    busybox cp -L \
        /etc/letsencrypt/live/mysite.com/privkey.pem \
        /etc/letsencrypt/live/mysite.com/cert.pem \
        /etc/letsencrypt/live/mysite.com/chain.pem \
        /certs
docker restart mysite.com
```

It is important to note that sites that already existed before the creation of the certificate will not have RequireTLS set.

## Reverse Proxy

You can also setup hiawatha as a reverse proxy to another website. This lets you use the security features of hiawatha in conjuction with another web server. To do this, just use the **HTTP_PROXY_HOST** environmental variable. For example, if you have a Nodejs site as another container, you can link them like this:

```
docker run --name mynodeapp -v /path/to/app:/usr/src/app:Z node server.js
docker run --name mysite.com --link mynodeapp:site -e HTTP_DOMAIN=mysite.com -e HTTP_PROXY_HOST=site:8080 \
    taosnet/hiawatha
```

# Environmental Variables

  * **HTTP_DOMAIN** is the domain name for the site. If the container has a hiawatha certificate in _/etc/hiawatha/tls_, then the site will set RequireTLS.
  * **HTTP_PROXY_HOST** hostname or IP that the site with reverse proxy for. If the container has a hiawatha certificate in _/etc/hiawatha/tls_, then the site will set RequireTLS.

# Utilities

## /usr/bin/addSite [-p reverseProxyHost] domain

Can be used to add additional sites to the server. After changes, the container will need to be restarted for the changes to go into effect. Note that if the site already exists, this does nothing.

  * -p reverseProxyHost: Specifies that this site is a reverse proxy for another site. See the section on **Reverse Proxy** for details.
  * domain: The domain name for the site. Automatically provides support for www.domain requests as well.

Example:
```
docker exec -ti mysite.com /usr/bin/addSite -t -c letsencrypt-server images.mysite.com \
    && docker restart mysite.com
```

## /usr/bin/setupSSL

Enables SSL support for the container. Requires the container to be restarted for the change to go into effect.

Example:
```
docker exec mysite.com /usr/bin/setupSSL && docker restart mysite.com
```

A certificate file must exist prior to restarting the container. You should not need to call this utility directly, but it is listed for completeness.
