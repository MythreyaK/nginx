# escape=\

FROM ubuntu:latest as build-tools

RUN apt update \
    > /dev/null \
    && apt upgrade -y \
    > /dev/null \
    && apt install -y \
    g++ \
    gcc \
    make \
    file \
    perl \
    rsync \
	libgd3 \
	libgd-dev \
    geoip-bin \
    libgeoip1 \
    libperl-dev \
    libgeoip-dev \
    linux-headers-generic \
    > /dev/null
# Build


FROM build-tools as build

# Set build time vars
ARG SERVER_NAME=mythreya.dev
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
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--with-pcre-jit \
	--with-pcre=../pcre-8.43 \
	--with-zlib=../zlib-1.2.11 \
	--with-openssl=../openssl-1.1.1b \
	--with-debug \
    --with-compat \
	--with-file-aio \
	--with-http_addition_module \
	--with-http_auth_request_module \
	--with-http_dav_module \
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

ARG NGINX_VER=1.16.0
ARG SHA256_NGINX=4fd376bad78797e7f18094a00f0f1088259326436b537eb5af69b01be2ca1345

ARG PCRE_VER=8.43
ARG SHA256_PCRE=0b8e7465dc5e98c757cc3650a20a7843ee4c3edf50aaf60bb33fd879690d2c73

ARG ZLIB_VER=1.2.11
ARG SHA256_ZLIB=c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1

ARG OPENSSL_VER=1.1.1b
ARG SHA256_OPENSSL=5c557b023230413dfb0756f3137a13e6d726838ccd1430888ad15bfb2b43ea4b

ADD https://nginx.org/download/nginx-${NGINX_VER}.tar.gz            /tmp/nginx.tar.gz
ADD https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VER}.tar.gz           /tmp/pcre.tar.gz
ADD https://www.zlib.net/zlib-${ZLIB_VER}.tar.gz                    /tmp/zlib.tar.gz
ADD https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz    /tmp/openssl.tar.gz

RUN cd /tmp \
    && mkdir -p /tmp/fs \
    # Verify checksums
	&& sha_check=$(( \
	    $(expr $(sha256sum nginx.tar.gz     | awk '{print $1}') == "$SHA256_NGINX")  && \
	    $(expr $(sha256sum pcre.tar.gz      | awk '{print $1}') == "$SHA256_PCRE")   && \
	    $(expr $(sha256sum zlib.tar.gz      | awk '{print $1}') == "$SHA256_ZLIB")   && \
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
	&& cd nginx-${NGINX_VER} \
    # Replace server tokens
	&& printf "Replacing Server tokens to: $SERVER_NAME/${SERVER_BUILD_VER}\n" \
	&& sed -i "s/\"Server: nginx\" CRLF/\"Server: $SERVER_NAME\" CRLF/g" "src/http/ngx_http_header_filter_module.c" \
	&& sed -i "s/\"Server: \" NGINX_VER CRLF/\"Server: \" \"$SERVER_NAME\/$SERVER_BUILD_VER\" CRLF/g" "src/http/ngx_http_header_filter_module.c" \
	&& sed -i "s/\"Server: \" NGINX_VER_BUILD CRLF/\"Server: \" \"$SERVER_NAME\/$SERVER_BUILD_VER\" CRLF/g" "src/http/ngx_http_header_filter_module.c" \
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
RUN /tmp/fs.sh
# Build complete


FROM scratch

COPY --from=build /tmp/fs /

ENTRYPOINT [ "/usr/sbin/nginx" ]
CMD [ "-g", "daemon off;" ]
