FROM phusion/baseimage:latest
MAINTAINER Matthew Baggett <matthew@baggett.me>

CMD ["/sbin/my_init"]

# Install base packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -yq install wget && \
    wget -O - https://download.newrelic.com/548C16BF.gpg | apt-key add - && \
    sh -c 'echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list' && \
    apt-get update && \
    apt-get -yq upgrade && \
    apt-get -yq install \
        nano \
        aptitude \
        git \
        curl \
        apache2 \
        libapache2-mod-php5 \
        php5-mysql \
        php5-curl \
        php5-apcu \
        php5-gd \
        php5-intl \
        php5-cli \
        php5-mcrypt \
        php5-sqlite \
        php5-pspell \
        newrelic-php5 \
        mysql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN sed -i "s/upload_max_filesize.*/upload_max_filesize = 1024M/g" /etc/php5/apache2/php.ini && \
    sed -i "s/post_max_size.*/post_max_size = 1024M/g" /etc/php5/apache2/php.ini && \
    sed -i "s/max_execution_time.*/max_execution_time = 0/g" /etc/php5/apache2/php.ini && \
    sed -i "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php5/apache2/php.ini && \
    sed -i "s/error_reporting.*/error_reporting = E_ALL \& \~E_DEPRECATED \& \~E_STRICT \& \~E_CORE_WARNING/g" /etc/php5/apache2/php.ini && \
    cp /etc/php5/apache2/php.ini /etc/php5/cli/php.ini

# Install composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Install Newrelic
RUN newrelic-install install
RUN rm /etc/php5/mods-available/newrelic.ini
ADD docker/newrelic.ini /etc/php5/cli/conf.d/newrelic.ini
ADD docker/newrelic.ini /etc/php5/apache2/conf.d/newrelic.ini

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
ADD docker/run.apache.sh /etc/service/apache2/run
RUN chmod +x /etc/service/*/run

