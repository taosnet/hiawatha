# Description

Provides a basic framework or quickly creating a hiawatha server with your website. It is setup to easily allow integration with another container for lets encrypt certificates by storing the certificate is **/certs/**. This can easily be imported from another container. For this, it is setup to detect the files **/certs/key.pem**, **/certs/cert.pem**, and **/certs/chain.pem**. This integrates well with the image **m3adow/letsencrypt-simp_le**.

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
docker run --name mysite.com-ssl -ti -p 80:80 -v /certs m3adow/letsencrypt-simp_le \
    -f account_key.json -f chain.pem -f cert.pem -f key.pem --email email@mysite.com -d mysite.com
```

Run the site:

```
docker run --name mysite.com -dti -p 443:443 -e HTTP_DOMAIN=mysite.com --volumes-from mysite.com-ssl taosnet/hiawatha
```

To renew the certificates:

```
docker start mysite.com-ssl && docker restart mysite.com
```

### Redirecting http to https

Create the certificate as above.

Run the site utilizing the HTTP_REQUIRE_TLS environmental variable to enable the redirect:

```
docker run --name mysite.com -dti -p 443:443 -p 80:80 -e HTTP_DOMAIN=mysite.com -e HTTP_REQUIRE_TLS=yes --volumes-from mysite.com-ssl taosnet/hiawatha
```

Because the site uses port 80, you need to bring the site down temporarily while you renew the certificates:

```
docker stop mysite.com && docker start mysite.com-ssl
docker start mysite.com
```

# Environmental Variables

  * **HTTP_DOMAIN** is the domain name for the site.
  * **HTTP_REQUIRE_TLS** specifies whether or not the site requires TLS. Can be **yes** or **no**. Defaults to **no**.
