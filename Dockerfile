FROM php:7.4-fpm-buster

LABEL maintainer="https://github.com/torrentpier/"

RUN curl -L https://getcomposer.org/installer -o composer-setup.php \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm -f composer-setup.php

RUN apt-get update && apt-get install -y \
        ca-certificates \
        dirmngr \
        gettext-base \
        git \
        gnupg \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        locales \
        supervisor \
        unzip \
        vim \
        zlib1g-dev \
    && pecl install redis xdebug \
    && docker-php-ext-enable redis xdebug \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install bcmath gd gettext intl mysqli opcache pdo_mysql zip \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys --no-tty 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
    && echo "deb http://nginx.org/packages/mainline/debian/ buster nginx" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        nginx \
        nginx-module-geoip \
        nginx-module-image-filter \
        nginx-module-njs \
        nginx-module-perl \
        nginx-module-xslt \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN echo "Europe/Moscow" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales

RUN sed -ri 's/^www-data:x:33:33:/www-data:x:1000:1000:/' /etc/passwd

RUN sed -ri '/^access.log/ s/^/; /' /usr/local/etc/php-fpm.d/docker.conf \
    && sed -ri "s/^pm = dynamic/pm = ondemand/" /usr/local/etc/php-fpm.d/www.conf

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

COPY /etc/nginx/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

COPY /etc/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["supervisord"]
