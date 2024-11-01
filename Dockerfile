FROM alpine:3.20.3

# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  redis \
  curl \
  imagemagick \
  nginx \
  php83 \
  php83-ctype \
  php83-curl \
  php83-dom \
  php83-fileinfo \
  php83-fpm \
  php83-gd \
  php83-intl \
  php83-mbstring \
  php83-mysqli \
  php83-opcache \
  php83-openssl \
  php83-phar \
  php83-session \
  php83-tokenizer \
  php83-xml \
  php83-xmlreader \
  php83-xmlwriter \
  php83-pecl-imagick \
  php83-pcntl \
  php83-redis \
  php83-zip \
  php83-pdo_mysql \
  php83-bcmath \
  php83-sockets \
  php83-intl \
  php83-cli \
  supervisor \
  php83-simplexml \
  wget \
  unzip \
  bash && \
  rm -rf /var/lib/apt/lists/*

# Configure Redis
RUN echo "requirepass ${REDIS_PASSWORD}" >> /etc/redis.conf && \
    echo "bind 127.0.0.1" >> /etc/redis.conf && \
    echo "user ${REDIS_USERNAME} on >${REDIS_PASSWORD} ~* +@all" >> /etc/redis.conf

# Configure nginx - http
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/nginx/nginx-cms.conf /etc/nginx/conf.d/default.conf

# Configure PHP-FPM
ENV PHP_INI_DIR /etc/php83
COPY config/php/fpm-pool.conf ${PHP_INI_DIR}/php-fpm.d/www.conf
COPY config/php/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

# Install Composer
RUN wget https://getcomposer.org/installer -O composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    rm composer-setup.php

# Configure supervisord
COPY config/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Download and extract Willow CMS
ARG WILLOW_VERSION=1.0.2

RUN curl -L "https://github.com/matthewdeaves/willow/archive/refs/tags/v${WILLOW_VERSION}.zip" -o willow.zip && \
    unzip willow.zip && \
    mv willow-${WILLOW_VERSION}/* . && \
    rm -rf willow-${WILLOW_VERSION} willow.zip

# Copy app_local.php
COPY config/app/app_local.php config/app_local.php

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Install wait-for-it
ADD https://github.com/vishnubob/wait-for-it/raw/master/wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN chmod +x /usr/local/bin/wait-for-it.sh

# Copy entrypoint script
COPY config/shell/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh

# Make sure files/folders needed by the processes are accessible when they run under the nobody user
RUN chown -R nobody:nobody /var/www/html /run /var/lib/nginx /var/log/nginx && \
mkdir -p /var/lib/willow && \
chown -R nobody:nobody /var/lib/willow && \
chmod -R 755 /var/lib/willow

# Ensure nobody user can access the wait-for-it script
RUN chown nobody:nobody /usr/local/bin/wait-for-it.sh

# Switch to use a non-root user from here on
USER nobody

# Expose the port nginx is reachable on
EXPOSE 80

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/setup.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping || exit 1
