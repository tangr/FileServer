FROM debian:buster-slim

LABEL maintainer="Atompi <atomissionpi@gmail.com>"

ENV NGINX_VERSION=1.16.1 \
    LUA_NGINX_MODULE_TAG=v0.10.15

COPY sources.list /etc/apt/sources.list

RUN addgroup --system --gid 101 nginx \
    && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx \
    && apt update \
    && apt install -y \
    build-essential \
    wget \
    git \
    libpcre3-dev \
    libssl-dev \
    zlib1g-dev \
    libssl1.1 \
    && cd /tmp \
    && wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
    && git clone https://gitee.com/atompi/luajit2 \
    && git clone https://gitee.com/atompi/lua-nginx-module -b $LUA_NGINX_MODULE_TAG \
    && git clone https://gitee.com/atompi/ngx-fancyindex \
    && git clone https://gitee.com/atompi/ngx_devel_kit \
    && tar -zxf nginx-$NGINX_VERSION.tar.gz \
    && cd /tmp/luajit2 \
    && make \
    && make install \
    && cd /tmp/nginx-$NGINX_VERSION \
    && export LUAJIT_LIB=/usr/local/lib \
    && export LUAJIT_INC=/usr/local/include/luajit-2.1 \
    && ./configure \
    --prefix=/usr/local/nginx \
    --with-ld-opt="-Wl,-rpath,/usr/local/lib" \
    --with-http_gzip_static_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-file-aio \
    --with-threads \
    --add-module=/tmp/lua-nginx-module \
    --add-module=/tmp/ngx-fancyindex \
    --add-module=/tmp/ngx_devel_kit \
    && make \
    && make install \
    && mkdir -p /usr/local/lib/lua/5.1/resty \
    && wget https://gitee.com/atompi/lua-resty-upload/raw/master/lib/resty/upload.lua -O /usr/local/lib/lua/5.1/resty/upload.lua \
    && apt remove -qq -y --purge \
    build-essential \
    git \
    wget \
    libpcre3-dev \
    libssl-dev \
    zlib1g-dev \
    && apt autoremove -y --purge \
    && apt autoclean \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
    && rm -rf /tmp/* \
    && ln -sf /dev/stdout /usr/local/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/nginx/logs/error.log \
    && ln -sf /usr/local/nginx/sbin/nginx /usr/bin/nginx \
    && mkdir /usr/local/nginx/conf/lua \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && mkdir -p /data/uploads \
    && chown -R 65534:65534 /data/uploads

COPY upload.lua /usr/local/nginx/conf/lua/upload.lua
COPY delete.lua /usr/local/nginx/conf/lua/delete.lua
COPY nginx.conf /usr/local/nginx/conf/nginx.conf

VOLUME /data/uploads

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
