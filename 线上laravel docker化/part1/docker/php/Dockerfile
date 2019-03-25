FROM       php:7.0.15-fpm-alpine

RUN adduser -s /bin/ash -D docker
WORKDIR /var/www
RUN rm -rf /var/www/html

#安装php扩展
RUN echo "http://mirrors.aliyun.com/alpine/v3.6/main" > /etc/apk/repositories; \
    echo "http://mirrors.aliyun.com/alpine/v3.6/community" >> /etc/apk/repositories \
    && apk update \
    && apk --no-cache add \
        $PHPIZE_DEPS \
        libxslt-dev \
        icu-dev \
        libjpeg-turbo \
        libpng-dev \
        libpng \
        libjpeg-turbo-dev \
        freetype-dev \
        freetype \
    && docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && pecl install \
        apcu \
    && docker-php-ext-configure mbstring \
    && docker-php-ext-configure exif \
    && docker-php-ext-install \
        zip \
        opcache \
        pdo \
        pdo_mysql \
        xsl \
        intl \
        gd \
        mbstring \
        exif \
    && docker-php-ext-enable \
        apcu \
        mbstring \
        exif \
    && apk del --no-cache \
        freetype-dev \
        libpng-dev \
        libjpeg-turbo-dev

#安装扩展
RUN apk add --no-cache \
        nano \
        git \
        apache-ant \
        openssl

#安装 Composer
ENV COMPOSER_HOME /home/docker/.composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --version=1.8.4 --install-dir=/bin \
    && php -r "unlink('composer-setup.php');" \
    && ln -s /bin/composer.phar /bin/composer \
    && mkdir /home/docker/.composer/cache \
    && chown -R docker:docker /home/docker/.composer \
    && chmod -R g+w /home/docker/.composer
USER docker
#配置composer镜像，和安装hirak/prestissimo
RUN composer config -g repo.packagist composer https://packagist.laravel-china.org \
    && composer global require hirak/prestissimo \
    && chmod -R g+w /home/docker/.composer
USER root

COPY www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php.ini /usr/local/etc/php/
