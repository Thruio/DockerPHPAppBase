FROM phusion/baseimage:latest
MAINTAINER Matthew Baggett <matthew@baggett.me>

CMD ["/sbin/my_init"]

# Install base packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -yq install wget python-software-properties && \
    wget -O - https://download.newrelic.com/548C16BF.gpg | apt-key add - && \
    sh -c 'echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list' && \
    apt-get update && \
    apt-get -yq install \
        sudo \
        nano \
        aptitude \
        unzip \
        git \
        curl \
        apache2 \
        libapache2-mod-php7.0 \
        php7.0 \
        php-all-dev \
        php7.0-mysql \
        php7.0-curl \
        php-apcu \
        php7.0-gd \
        php7.0-intl \
        php7.0-cli \
        php7.0-mbstring \
        php7.0-mcrypt \
        php7.0-sqlite \
        php7.0-opcache \
        php7.0-json \
        newrelic-php5 \
        mysql-client \
        ca-certificates && \
    apt-get -yq upgrade && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/*.deb

# Install PHP7 xdebug from source
RUN cd /tmp && \
    wget -O xdebug.tgz http://xdebug.org/files/xdebug-2.4.1.tgz && \
    tar -xvzf xdebug.tgz && \
    cd xdebug-2.4.1 && \
    phpize && \
    ./configure && \
    make && \
    cp modules/xdebug.so /usr/lib/php/20151012

# Configure PHP
RUN sed -i "s/upload_max_filesize.*/upload_max_filesize = 1024M/g" /etc/php/7.0/apache2/php.ini && \
    sed -i "s/post_max_size.*/post_max_size = 1024M/g" /etc/php/7.0/apache2/php.ini && \
    sed -i "s/max_execution_time.*/max_execution_time = 0/g" /etc/php/7.0/apache2/php.ini && \
    sed -i "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php/7.0/apache2/php.ini && \
    sed -i "s/error_reporting.*/error_reporting = E_ALL \& \~E_DEPRECATED \& \~E_STRICT \& \~E_CORE_WARNING/g" /etc/php/7.0/apache2/php.ini && \
    cp /etc/php/7.0/apache2/php.ini /etc/php/7.0/cli/php.ini && \
    echo "\n\nzend_extension = /usr/lib/php/20151012/xdebug.so\n" >> /etc/php/7.0/cli/php.ini

# Add NodeJS updated PPA repos & install NodeJS 6 + NPM + Gulp
RUN curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
RUN apt-get update && \
    apt-get -yq install \
        nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN npm install -g \
        gulp \
        grunt \
        grunt-autoprefixer \
        grunt-cli \
        grunt-contrib-concat \
        grunt-contrib-cssmin \
        grunt-contrib-jshint \
        grunt-contrib-less \
        grunt-contrib-sass \
        grunt-contrib-uglify \
        grunt-contrib-watch \
        grunt-sass

# Install composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Install Newrelic
RUN newrelic-install install
RUN rm /etc/php/7.0/mods-available/newrelic.ini
ADD docker/newrelic.ini /etc/php/7.0/apache2/conf.d/newrelic.ini

# Configure /app folder with sample app
RUN mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html
WORKDIR /app

# Set up Apache
ADD docker/ApacheConfig.conf /etc/apache2/sites-enabled/000-default.conf
ADD docker/apache2.conf /etc/apache2/apache2.conf
RUN a2enmod rewrite

# Add ports.
EXPOSE 80

# Add startup scripts
RUN mkdir /etc/service/apache2
#ADD docker/run.grunt.sh /etc/service/grunt/run
ADD docker/run.apache.sh /etc/service/apache2/run
RUN chmod +x /etc/service/*/run

