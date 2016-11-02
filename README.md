# Description

Provides a basic framework or quickly creating a hiawatha server with your website. It is setup to easily allow integration with another container for lets encrypt certificates by storing the certificate is **/certs/**. The image **taosnet/cert-manager** can be used to ease the integration with Lets Encrypt.

You can use the envirnomental variables to modify properties about the site. See the section below.

This container does **NOT** have php installed in any form. If you wish to use php in your site, install php5-fpm via apk. 

# Usage

There are two ways to build a site using this image:

  1. Use a data volume for your web app.
  1. Extend the image with your own image.

## Using a data volume

To use a data volume for you web app:
```
docker run --name mysite.com -dti p 80:80 -e HTTP_DOMAIN=mysite.com -v /path/to/webapp:/var/www/mysite.com/public:Z taosnet/hiawatha
```

## Extending the Image

Create a Dockerfile:

```
FROM taosnet/hiawatha

ENV HTTP_DOMAIN mysite.com
COPY public /var/www/mysite.com/
```
Build the image:
```
docker build -t taosnet/mysite .
```

Run the site:

```
docker run --name mysite.com -dti -p 80:80 taosnet/mysite
```

## SSL with Lets Encrypt

Create the certificates:

```
docker run --rm -ti -p 80:80 -v mysite.com-ssl:/etc/letsencrypt quay.io/letsencrypt/letsencrypt  \
    certonly --standalone --preferred-challenge http -d mysite.com
```

Convert the certificate into a form recognizable by hiawatha:
```
docker run --name mysite.com-certs -v mysite.com-ssl:/etc/letsencrypt -v mysite.com-certs:/certs taosnet/cert-manager \
    mysite.com letsencrypt hiawatha
```

Run the site:

```
docker run --name mysite.com -dti -p 443:443 -e HTTP_DOMAIN=mysite.com --volumes-from mysite.com-certs taosnet/hiawatha
```

To renew the certificates:

```
docker create --name mysite.com-ssl -v mysite.com-ssl:/etc/letsencrypt -p 80:80 -ti quay.io/letsencrypt/letsencrypt \
    renew

docker start mysite.com-ssl && docker start mysite.com-certs && docker restart mysite.com
```

### Redirecting http to https

Create the certificate as above.

Run the site utilizing the HTTP_REQUIRE_TLS environmental variable to enable the redirect:

```
docker run --name mysite.com -dti -p 443:443 -p 80:80 -e HTTP_DOMAIN=mysite.com -e HTTP_REQUIRE_TLS=yes \
    --volumes-from mysite.com-certs taosnet/hiawatha
```

Because the site uses port 80, you need to bring the site down temporarily while you renew the certificates:

```
docker stop mysite.com && docker start mysite.com-ssl && docker start mysite.com-certs
docker start mysite.com
```

#### Proxying Lets Encrypt

If you wish to minimize the downtime to your site when renewing certificates, you can utilize the **HTTP_CERT_PROXY_HOST** variable. Because you cannot have more than one server listing on the same IP/port pair, you will need to specify the IPs used in your port translations.

The site creation becomes:
```
docker run --name mysite.com -d -p publicIP1:80:80 -p publicIP1:443:443 --volumes-from mysite.com-certs \
    -e HTTP_DOMAIN=mysite.com -e HTTP_REQUIRE_TLS=yes -e HTTP_CERT_PROXY_HOST=certServer taosnet/hiawatha
```
It is best if **certServer** references either a public DNS name, or a static IP that can be referenced by the site. The renewal process then becomes:
```
docker run --name mysite.com-ssl -v mysite.com-ssl:/etc/letsencrypt -p certSeverIP:80:80 -t quay.io/letsencrypt/letsencrypt renew \
&& docker start mysite.com-certs \
&& docker restart mysite.com
```

# Environmental Variables

  * **HTTP_DOMAIN** is the domain name for the site.
  * **HTTP_REQUIRE_TLS** specifies whether or not the site requires TLS. Can be **yes** or **no**. Defaults to **no**.
  * **HTTP_CERT_PROXY_HOST** specifies the IP or DNS name for the server to proxy Lets Encrypt requests to.
