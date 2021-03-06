# escape=\

FROM ubuntu:latest as build-tools

RUN apt update \
    > /dev/null \
    && apt upgrade -y \
    > /dev/null \
    && apt install -y --no-install-recommends \
    file \
    perl \
    cmake \
    rsync \
    geoip-bin \
    libgeoip1 \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    libwebp-dev \
    libperl-dev \
    libgeoip-dev \
    build-essential \
    > /dev/null
# Build


FROM build-tools as build

# Set build time vars
ARG SERVER_NAME=server
ARG SERVER_BUILD_VER=1.0.0

ARG NGINX_CONFIG="\
    --user=nginx \
    --group=nginx \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --conf-path=/etc/nginx/nginx.conf \
    --modules-path=/usr/lib/nginx/modules \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --http-scgi-temp-path=/var/cache/nginx/scgi \
    --http-proxy-temp-path=/var/cache/nginx/proxy \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi \
    --http-client-body-temp-path=/var/cache/nginx/client \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi \
    --with-pcre-jit \
    --with-pcre=../pcre-8.43 \
    --with-zlib=../zlib-1.2.11 \
    --with-openssl=../openssl-1.1.1c \
    --with-debug \
    --with-compat \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_geoip_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-threads \
    --with-ld-opt='-fPIC -fPIE -pie -Wl,-pie -Wl,-z,relro -Wl,-z,now' \
    --with-cc-opt='-g -O2 -fPIC -fPIE -Wl,-pie -Wdate-time -fstack-protector-strong -fasynchronous-unwind-tables -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2'"

ARG NGINX_VER=1.16.1
ARG SHA256_NGINX=f11c2a6dd1d3515736f0324857957db2de98be862461b5a542a3ac6188dbe32b

ARG PCRE_VER=8.43
ARG SHA256_PCRE=0b8e7465dc5e98c757cc3650a20a7843ee4c3edf50aaf60bb33fd879690d2c73

ARG ZLIB_VER=1.2.11
ARG SHA256_ZLIB=c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1

ARG OPENSSL_VER=1.1.1c
ARG SHA256_OPENSSL=f6fb3079ad15076154eda9413fed42877d668e7069d9b87396d0804fdb3f4c90

ARG LIBGD_VER=2.2.5
ARG SHA256_LIBGD=a66111c9b4a04e818e9e2a37d7ae8d4aae0939a100a36b0ffb52c706a09074b5

ADD https://nginx.org/download/nginx-${NGINX_VER}.tar.gz            /tmp/nginx.tar.gz
ADD https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VER}.tar.gz           /tmp/pcre.tar.gz
ADD https://www.zlib.net/zlib-${ZLIB_VER}.tar.gz                    /tmp/zlib.tar.gz
ADD https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz    /tmp/openssl.tar.gz
ADD https://github.com/libgd/libgd/releases/download/gd-${LIBGD_VER}/libgd-${LIBGD_VER}.tar.gz    /tmp/libgd.tar.gz

RUN cd /tmp \
    && mkdir -p /tmp/fs \
    # Verify checksums
    && sha_check=$(( \
        $(expr $(sha256sum nginx.tar.gz     | awk '{print $1}') == "$SHA256_NGINX")  && \
        $(expr $(sha256sum pcre.tar.gz      | awk '{print $1}') == "$SHA256_PCRE")   && \
        $(expr $(sha256sum zlib.tar.gz      | awk '{print $1}') == "$SHA256_ZLIB")   && \
        $(expr $(sha256sum libgd.tar.gz     | awk '{print $1}') == "$SHA256_LIBGD")  && \
        $(expr $(sha256sum openssl.tar.gz   | awk '{print $1}') == "$SHA256_OPENSSL")   \
    )) \
    && if [ $sha_check != 1 ]; \
        then \
        printf "SHA CheckSum Faliure! \nStopping build process\n"; \
        exit 1; \
    fi \
    && printf "\n\nChecksums Verified!\n" \
    && printf "Extracting...\n" \
    && tar -xf nginx.tar.gz \
    && tar -xf zlib.tar.gz \
    && tar -xf openssl.tar.gz \
    && tar -xf pcre.tar.gz \
    && tar -xf libgd.tar.gz \
    # Build libgd
    && cd /tmp/libgd-${LIBGD_VER} \
    && mkdir build \
    && cd build \
    && cmake -DENABLE_PNG=1 -DENABLE_JPEG=1 -DENABLE_TIFF=1 -DENABLE_WEBP=1 .. \
    && make > mk.log \
    && make install > mki.log \
    # Start NGINX build
    && cd /tmp/nginx-${NGINX_VER} \
    # Replace server tokens
    && printf "Replacing Server tokens to: $SERVER_NAME/${SERVER_BUILD_VER}\n" \
    && sed -i "s/\"Server: nginx\" CRLF/\"Server: $SERVER_NAME\" CRLF/g" "src/http/ngx_http_header_filter_module.c" \
    && sed -i "s/\"Server: \" NGINX_VER CRLF/\"Server: $SERVER_NAME\/$SERVER_BUILD_VER\" CRLF/g" "src/http/ngx_http_header_filter_module.c" \
    && sed -i "s/NGINX_VER_BUILD/\"$SERVER_NAME\/$SERVER_BUILD_VER\"/g" "src/http/v2/ngx_http_v2_filter_module.c" \
    && sed -i "s/NGINX_VER/\"$SERVER_NAME\/$SERVER_BUILD_VER\"/g" "src/http/v2/ngx_http_v2_filter_module.c" \
    && printf "Configuring build...\n" \
    # Redirect and run as just ./configure $NGINX_CONFIGURE
    # doesn't seem to be working
    && printf "Started Build\n" \
    && echo "./configure $NGINX_CONFIG" > run.sh \
    && chmod +x run.sh \
    && printf "Building Nginx ${NGINX_VER}\n" \
    && ./run.sh > run.log \
    && make > make.log \
    && make install > makeinst.log \
    && printf "Build Complete.\n" \
    && printf "Copying filesystem...\n"

COPY scripts/fs.sh /tmp
RUN chmod +x /tmp/fs.sh \
    && /tmp/fs.sh
# Build complete


FROM scratch

COPY --from=build /tmp/fs /

EXPOSE 80 443
ENTRYPOINT [ "/usr/sbin/nginx" ]
CMD [ "-g", "daemon off;" ]
