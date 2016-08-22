## Description

Provides a basic framework or quickly creating a hiawatha server with your website. It is setup to easily allow integration with another container for lets encrypt certificates by storing the certificate is **/certs/**. This can easily be imported from another container.

This container does **NOT** have php installed in any form. If you wish to use php in your site, install php5-fpm via apk.

## Usage

  1. Create your own site.conf file:
        VirtualHost {
            Hostname = www.my-domain.com
	    WebsiteRoot = /var/www/domain/public
	    AccessLogfile = /var/www/domain/log/access.log
	    ErrorLogfile = /var/www/domain/log/error.log
	    TimeForCGI = 5
	    UseDirectory = static, files
	    RequireTLS = yes
	}
  2. Create your Dockerfile:
	FROM taosnet/hiawatha:10.3
	COPY site.conf /etc/hiawatha/site.conf
	COPY site /var/www/domain/public
  3. Build the container:
	docker build -t taosnet/my-domain .
  4. Create the SSL certificate container:
	 docker run -ti -p 80:80 -v /certs --name mydomain-cert \
	     m3adow/letsencrypt-simp_le -f account_key.json  \
	     -f chain.pem -f cert.pem -f key.pem --email a@example.org \
	     -d www-mydomain.com
  5. Run the container:
	docker run --volumes-from=mydomain-cert \
	     -p 80:80 -p 443:443 \
	     --name mydomain \
	     taosnet/my-domain
