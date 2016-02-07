# sudo docker build -t nixx/icms .
# sudo docker run --name icms -d -p 8082:80 -v /Users/dillon/Documents/nixx/CMS:/var/www nixx/icms

FROM centos:6
MAINTAINER Dillon Aykac <dillon@nixx.co>
LABEL Description="PHP, NGINX, XDEBUG, for developing ICMS" Vendor="NiXX" Version="1.0"
RUN yum -y install epel*
RUN yum -y install http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm && \
    yum -y install http://rpms.famillecollet.com/enterprise/remi-release-6.rpm && \
    yum -y --enablerepo=remi,remi-php56 update && \
    yum -y --enablerepo=remi,remi-php56 upgrade
RUN yum -y install nginx && \
    yum -y --enablerepo=remi,remi-php56 install php \
    php-fpm php-gd php-ldap \
    php-sqlite php-pgsql php-pear php-mysql \
    php-mcrypt php-xcache php-xml php-xmlrpc \
    php-devel cc gcc-c++ autoconf automake php-soap

# Installing supervisor
RUN yum install -y python-setuptools
RUN easy_install supervisor

# Adding the configuration file of the nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY php-fpm.conf /etc/php-fpm.conf
# tweak php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php.ini && \
    sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php.ini && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php.ini && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php-fpm.d/www.conf && \
    sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php-fpm.d/www.conf && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php-fpm.d/www.conf && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php-fpm.d/www.conf && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php-fpm.d/www.conf && \
    #sed -i -e "s/user = apache/user = nginx/g" /etc/php-fpm.d/www.conf && \
    #sed -i -e "s/group = apache/group = nginx/g" /etc/php-fpm.d/www.conf && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php-fpm.d/www.conf

# Adding the configuration file of the Supervisor
COPY supervisord.conf /etc/

RUN echo "<?php phpinfo(); ?>" > /var/www/index.php
RUN chmod -R 777 /var/www

RUN pecl install -o -f xdebug \
    && echo "zend_extension=$(find /usr/lib64/php/modules/ -name xdebug.so)" > /etc/php.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /etc/php.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /etc/php.d/xdebug.ini

# Setup Volume
VOLUME ["/var/www"]
RUN usermod -u 1000 apache

# Expose Ports
EXPOSE 80

# Executing supervisord
CMD ["supervisord", "-n"]
