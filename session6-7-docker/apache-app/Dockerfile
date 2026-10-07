# Apache HTTP Server serving a static Hello World page
FROM httpd:2.4

# Apache's default document root inside this image
COPY index.html /usr/local/apache2/htdocs/index.html

EXPOSE 80

# The base image already runs: httpd-foreground
