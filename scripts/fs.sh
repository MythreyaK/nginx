# Make /etc/passwd and /etc/groups
echo "nginx:x:7000:7000:nginx user,,,:/nonexistent:/bin/false\n" > /tmp/fs/etc/passwd
echo "nginx:x:7000:\n" > /tmp/fs/etc/group

# Copy everything that this binary is using
rsync -qpogkRL $(ldd /tmp/fs/usr/sbin/nginx | awk 'NF == 4 {print $3}; NF == 2 {print $1}' ) /tmp/fs > /dev/null
