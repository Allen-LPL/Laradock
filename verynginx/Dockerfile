FROM alpine:3.6

ENV OPENRESTY_VERSION 1.15.8.2
ENV OPENRESTY_PREFIX /opt/verynginx/openresty
ENV NGINX_PREFIX /opt/verynginx/openresty/nginx
ENV VAR_PREFIX /var/nginx

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN apk update && apk add ca-certificates && \
    apk add tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

RUN apk update \
 && apk add --virtual build-deps \
    make gcc musl-dev \
    pcre-dev openssl-dev zlib-dev ncurses-dev readline-dev \
    curl perl \
 && mkdir -p /root/ngx_openresty \
 && cd /root/ngx_openresty \
 && curl -sSL http://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz | tar -xvz \
 && cd openresty-* \
 && readonly NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && ./configure \
    --prefix=$OPENRESTY_PREFIX \
    --http-client-body-temp-path=$VAR_PREFIX/client_body_temp \
    --http-proxy-temp-path=$VAR_PREFIX/proxy_temp \
    --http-log-path=$VAR_PREFIX/access.log \
    --error-log-path=$VAR_PREFIX/error.log \
    --pid-path=$VAR_PREFIX/nginx.pid \
    --lock-path=$VAR_PREFIX/nginx.lock \
    --user=www-data \
    --group=www-data \
    --with-luajit \
    --with-pcre-jit \
    --with-http_ssl_module \
    --with-http_v2_module \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-http_uwsgi_module \
    --with-http_stub_status_module \
    -j${NPROC} \
 && make -j${NPROC} \
 && make install \
 && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/nginx \
 && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/openresty \
 && ln -sf $OPENRESTY_PREFIX/bin/resty /usr/local/bin/resty \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* $OPENRESTY_PREFIX/luajit/bin/lua \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* /usr/local/bin/lua \
 && apk del build-deps \
 && apk add \
    libpcrecpp libpcre16 libpcre32 openssl libssl1.0 pcre libgcc libstdc++ git \
 && rm -rf /var/cache/apk/* \
 && rm -rf /root/ngx_openresty

RUN addgroup -g 1000 www-data && adduser -D  -G www-data -s /bin/false -u 1000 www-data


RUN git clone http://Allen:ttz.com2019@gitcode.ttz.com:8989/TiaoTiaoZhu/verynginx.git VeryNginx \
    && rm -f $NGINX_PREFIX/conf/nginx.conf \
    && cp ./VeryNginx/nginx.conf $NGINX_PREFIX/conf/nginx.conf \
    && cp -r ./VeryNginx/verynginx /opt/verynginx \
    && chown -R www-data:www-data /opt/verynginx \
    && chmod -R 777 /opt/verynginx/verynginx/configs \
    && rm -rf ./verynginx 

# Copy nginx configuration files
COPY ./nginx.conf /opt/verynginx/openresty/nginx/conf/nginx.conf
COPY ./conf.d/default.conf /etc/nginx/conf.d/default.conf

ARG PHP_UPSTREAM_CONTAINER=php-fpm
ARG PHP_UPSTREAM_PORT=9000
# Set upstream conf and remove the default conf
    RUN echo "upstream php-upstream { server ${PHP_UPSTREAM_CONTAINER}:${PHP_UPSTREAM_PORT}; }" > /etc/nginx/conf.d/upstream.conf \
        && rm /etc/nginx/conf.d/default.conf

WORKDIR $NGINX_PREFIX/

EXPOSE 80 443

CMD ["/opt/verynginx/openresty/nginx/sbin/nginx", "-g", "daemon off; error_log /dev/stderr info;"]
