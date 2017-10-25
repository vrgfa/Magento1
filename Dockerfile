FROM php:5.5-apache

MAINTAINER Rafael Corrêa Gomes <rafaelcgstz@gmail.com>

ENV XDEBUG_PORT 9000

RUN requirements="redis-server php5-dev php5-cli php-pear libpng12-dev libmcrypt-dev libmcrypt4 libcurl3-dev libfreetype6 libjpeg62-turbo libpng12-dev libfreetype6-dev libjpeg62-turbo-dev" \
    && apt-get update && apt-get install -y $requirements && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install pdo \
    pdo_mysql \
    gd \
    mcrypt \
    mbstring \
    soap \
    && requirementsToRemove="libpng12-dev libmcrypt-dev libcurl3-dev libpng12-dev libfreetype6-dev libjpeg62-turbo-dev" \
    && apt-get purge --auto-remove -y $requirementsToRemove

RUN chmod 777 -R /var/www \
		&& chown -R www-data:1000 /var/www \
  	&& usermod -u 1000 www-data \
  	&& chsh -s /bin/bash www-data\
  	&& a2enmod rewrite \
		&& a2enmod headers \
    && sed -i -e 's/\/var\/www\/html/\/var\/www\/htdocs/' /etc/apache2/apache2.conf

RUN apt-get update && apt-get install -y  apt-utils php5-gd php5-mysql mysql-client-5.5 libxml2-dev git opcache wget zip vim \
    openssh-server openssh-client

# Install Redis
RUN pecl install redis \
  && echo "extension=redis.so" > /etc/php5/mods-available/redis.ini \
  && php5enmod redis

# Install oAuth
RUN apt-get update \
	&& apt-get install gcc make autoconf libc-dev pkg-config -y \
	&& apt-get install php-pear -y \
	&& pecl install oauth-1.2.3 \
	&& echo "extension=oauth.so" > /usr/local/etc/php/conf.d/docker-php-ext-oauth.ini


# Install XDebug

RUN yes | pecl install xdebug && \
	 echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.iniOLD

# Install Magerun

RUN wget https://files.magerun.net/n98-magerun.phar \
    && chmod +x ./n98-magerun.phar \
    && mv ./n98-magerun.phar /usr/local/bin/

# SSH
# RUN apt-get update && apt-get install -y openssh-server openssh-client
# RUN mkdir /var/run/sshd
# RUN echo 'root:root' | chpasswd
# RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN usermod -u 1000 www-data

RUN /etc/init.d/apache2 restart

# Install Composer

RUN	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# To SSH
# RUN /usr/sbin/sshd
# Configuring system

ADD .docker/config/php.ini /usr/local/etc/php/php.ini
ADD .docker/config/magento.conf /etc/apache2/sites-available/magento.conf
ADD .docker/config/custom-xdebug.ini /usr/local/etc/php/conf.d/custom-xdebug.ini
COPY .docker/bin/* /usr/local/bin/
COPY .docker/users/* /var/www/
RUN chmod +x /usr/local/bin/*
RUN ln -s /etc/apache2/sites-available/magento.conf /etc/apache2/sites-enabled/magento.conf

VOLUME ["/var/www/html"]
WORKDIR /var/www/html
COPY ./src /var/www/html

CMD ["apache2-foreground", "-DFOREGROUND"]
