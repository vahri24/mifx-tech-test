FROM alpine:3.21

RUN apk update && apk add --no-cache \   
    nginx \
    nginx-mod-http-headers-more \
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

#Creating necessary directories and setting permissions for nginx user    
RUN mkdir -p /var/www/html /var/log/php82 /var/log/nginx \
 && chown -R nginx:nginx /var/www/html /var/log/php82 /var/log/nginx

# PHP hardening: disable exec() and similar functions
RUN printf '%s\n' \
   'disable_functions = exec,passthru,shell_exec,system,proc_open,popen' \
   'expose_php = Off' \
   > /etc/php82/conf.d/99-hardening.ini

RUN printf '%s\n' \
   'error_log = /proc/self/fd/2' \
   'log_errors = On' \
   > /etc/php82/conf.d/99-logging.ini

RUN sed -i \
  -e 's|^user = .*|user = nginx|' \
  -e 's|^group = .*|group = nginx|' \
  -e 's|^listen = .*|listen = 127.0.0.1:9000|' \
  /etc/php82/php-fpm.d/www.conf

COPY ./conf/ /etc/nginx/http.d
COPY ./html/ /var/www/html/

EXPOSE 80

USER nginx
CMD ["sh", "-lc", "php-fpm82 -F & nginx -g 'daemon off;'"]
