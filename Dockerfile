FROM php:7.4-fpm
LABEL maintainer="galvani78@gmail.com"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN echo "export LANGUAGE=en_US.UTF-8 && export LANG=en_US.UTF-8 && export LC_ALL=en_US.UTF-8">>~/.bash_profile
RUN apt-get install -y unzip git gnupg
RUN locale-gen en_US.UTF-8

RUN yes | apt-get install systemd

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 11CD8CFCEEB5E8F4

RUN apt-get update && \
    apt-get install -y \
	libmcrypt-dev  \
	libicu-dev libpng-dev zlib1g-dev libedit-dev \
	libxml2-dev libxslt1-dev \
	zlib1g-dev libzip-dev\
	libc-client-dev libkrb5-dev \
	curl libcurl4-openssl-dev wget vim git

RUN apt-get install -y libonig-dev

RUN pecl channel-update pecl.php.net
RUN pecl install igbinary
RUN pecl bundle redis && cd redis && phpize && ./configure --enable-redis-igbinary && make && make install
RUN docker-php-ext-install bcmath sockets
RUN docker-php-ext-enable igbinary redis
RUN dokcer-php-ext-install apcu opcache
RUN dokcer-php-ext-install mongo 
RUN docker-php-source delete && rm -r /tmp/* /var/cache/*

RUN echo '\
opcache.interned_strings_buffer=16\n\
opcache.load_comments=Off\n\
opcache.max_accelerated_files=16000\n\
opcache.save_comments=Off\n\
' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN apt-get install libpq-dev libpq5

RUN docker-php-ext-install pdo bcmath curl gd intl json mbstring readline soap xml xmlrpc xsl zip
RUN docker-php-ext-install mysqli pdo_pgsql

RUN mkdir -p /var/run/php

RUN apt-get install -y wget lsb-release
RUN apt-get -y install cron

RUN rm -rf /var/lib/apt/lists/*

#INSTALL XDEBUG
RUN pecl install xdebug && docker-php-ext-enable xdebug
#XDEBUG
RUN echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.idekey=\"PHPSTORM\"" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote.mode=req" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote.handler=dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini


COPY conf /etc/cron.d/cron
RUN chmod 0755 /etc/cron.d/cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

RUN chmod -R 0777 /var/www/html/var/cache /var/www/html/var/log

COPY conf/php.ini /usr/local/etc/php/php.ini

RUN curl -Lsf 'https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz' | tar -C '/usr/local' -xvzf -
ENV PATH /usr/local/go/bin:$PATH
RUN go get github.com/mailhog/mhsendmail
RUN cp /root/go/bin/mhsendmail /usr/bin/mhsendmail
RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr mailhog:1025' >> /usr/local/etc/php/php.ini

RUN apt-get update && apt-get install -y openssh-server openssh-sftp-server
RUN mkdir ~/.ssh
COPY conf/ssh/authorized_keys /root/.ssh/
RUN chmod 700 ~/.ssh
RUN chmod 600 ~/.ssh/authorized_keys
RUN sed -i 's/^#\?PermitRootLogin .*$/PermitRootLogin without-password/' /etc/ssh/sshd_config
RUN sed -i 's/^#\?PubkeyAuthentication .*$/PubkeyAuthentication yes/' /etc/ssh/sshd_config



COPY launcher.sh /tmp/
RUN chmod +x /tmp/launcher.sh

STOPSIGNAL SIGQUIT

EXPOSE 9000
CMD ["php-fpm"]
