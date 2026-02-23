FROM alpine:3.21

RUN apk update && apk add --no-cache \   
    nginx \
    php82 \
    php82-fpm \
    php82-opcache \
    php82-mysqli \
    php82-pdo \
    php82-pdo_mysql \
    php82-phar \
    php82-mbstring \
    php82-xml \
    php82-curl \
    php82-zip \
    php82-session \
    php82-tokenizer \
    php82-ctype

RUN sed -i \
  -e 's|^user = .*|user = nginx|' \
  -e 's|^group = .*|group = nginx|' \
  -e 's|^listen = .*|listen = 127.0.0.1:9000|' \
  /etc/php82/php-fpm.d/www.conf

EXPOSE 80

USER nginx
CMD ["sh", "-lc", "php-fpm82 -F & nginx -g 'daemon off;'"]
