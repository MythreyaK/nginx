#!/bin/bash

# Make the necessary dirs
mkdir -p /tmp/fs/var/run
mkdir -p /tmp/fs/usr/lib/nginx
mkdir -p /tmp/fs/var/log/nginx
mkdir -p /tmp/fs/var/cache/nginx/{scgi,proxy,uwsgi,client,fastcgi}

# Copy every library that this binary is using
mv    /usr/local/lib/libgd.so                    /usr/lib/x86_64-linux-gnu/
rsync -qakRl /lib/*/libnss_[c,d]*                /tmp/fs/
rsync -qakRl /lib/x86_64-linux-gnu/ld*           /tmp/fs/
rsync -qakRl /lib/x86_64-linux-gnu/libnsl*       /tmp/fs/
rsync -qakRl /lib/x86_64-linux-gnu/libresolv*    /tmp/fs/
rsync -qakRL $(ldd /usr/sbin/nginx | awk 'NF == 4 {print $3}; NF == 2 {print $1}' ) /tmp/fs/ &> /dev/null
rsync -qakRl $(ldd /usr/sbin/nginx | awk 'NF == 4 {print $3}; NF == 2 {print $1}' ) /tmp/fs/ &> /dev/null

rsync -qakRL /etc/nginx/       /tmp/fs/
rsync -qakRL /usr/sbin/nginx/  /tmp/fs/

# Make /etc/passwd and /etc/groups
echo "nginx:x:7000:7000:nginx user,,,:/nonexistent:/bin/false" > /tmp/fs/etc/passwd
echo "nginx:x:7000:" > /tmp/fs/etc/group

# Redirect logs to docker log collector
ln -sf /dev/stderr /tmp/fs/var/log/nginx/error.log
ln -sf /dev/stdout /tmp/fs/var/log/nginx/access.log

# Libs like linux-vdso.so.1 cannot be copied
# as they are virtual and exist only in the
# kernel, so rsync throws error. Manually exit
# with 0 to let docker RUN continue
exit 0
