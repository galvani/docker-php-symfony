FROM php:7.1-fpm
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
RUN apt-get install -y unzip gnupg
RUN locale-gen en_US.UTF-8

RUN yes | apt-get install systemd

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 11CD8CFCEEB5E8F4

RUN apt-get install --no-install-recommends -y libmcrypt-dev  \
	libicu-dev \
	libpng-dev \
	zlib1g-dev \
	libedit-dev \
	libxml2-dev \
	libxslt1-dev \
	zlib1g-dev libzip-dev\
	libc-client-dev \
	libkrb5-dev \
	curl \
	libcurl4-openssl-dev  \
	libonig-dev \
	wget \
	lsb-release \
	cron \
	libpq5 \
	libjpeg-dev \
	libjpeg62-turbo-dev \
	libwebp-dev \
	libgmp-dev \
	libldap2-dev \
	netcat sqlite3 \
	libsqlite3-dev \
	iproute2 \
	net-tools \
	wget \
	vim \
	git \
	libz-dev \
    libpq-dev \
    libpng-dev \
    libfreetype6-dev \
    libssl-dev \
    libmcrypt-dev \
    libonig-dev \
    nodejs \
    npm

RUN docker-php-ext-configure gd --prefix=/usr --with-freetype --with-webp=  --with-jpeg \
    && docker-php-ext-install gd exif && php -r 'var_dump(gd_info());'

RUN pecl channel-update pecl.php.net
RUN pecl install igbinary
RUN pecl bundle redis && cd redis && phpize && ./configure --enable-redis-igbinary && make && make install
RUN docker-php-ext-install bcmath sockets mysqli gettext
RUN docker-php-ext-enable igbinary redis
RUN docker-php-source delete && rm -r /tmp/* /var/cache/*

RUN echo '\
opcache.interned_strings_buffer=16\n\
opcache.load_comments=Off\n\
opcache.max_accelerated_files=16000\n\
opcache.save_comments=Off\n\
' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN docker-php-ext-install pdo bcmath curl intl json mbstring readline soap xml xmlrpc xsl zip
RUN docker-php-ext-install mysqli pdo_mysql

RUN mkdir -p /var/run/php

RUN rm -rf /var/lib/apt/lists/*

#INSTALL XDEBUG
RUN pecl install xdebug && docker-php-ext-enable xdebug

RUN echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.idekey=\"PHPSTORM\"" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_port=9001" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote.mode=req" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote.handler=dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo xdebug.remote_host=`/sbin/ip route|awk '/default/ { print $3 }'` >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# INSTALL CRON FILES
COPY conf /etc/cron.d/cron
RUN chmod 0755 /etc/cron.d/cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

COPY conf/php.ini /usr/local/etc/php/php.ini

# Setup email forwarding via postfix to mailhog
RUN curl -Lsf 'https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz' | tar -C '/usr/local' -xvzf -
ENV PATH /usr/local/go/bin:$PATH
RUN go get github.com/mailhog/mhsendmail
RUN cp /root/go/bin/mhsendmail /usr/bin/mhsendmail
RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr mailhog:1025' >> /usr/local/etc/php/php.ini

STOPSIGNAL SIGQUIT

EXPOSE 9000
CMD ["php-fpm"]

