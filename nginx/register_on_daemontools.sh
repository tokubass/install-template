#!/bin/sh

svcdir=/service/.nginx
mkdir -p "$svcdir"
mkdir -p "$svcdir"/log/main

cat <<'EOF' >"$svcdir"/run
#!/bin/sh

PATH=/usr/local/nginx/sbin:/usr/local/bin:/usr/bin:/bin
export PATH
CONF=/usr/local/nginx/conf/nginx.conf

exec env - PATH=$PATH nginx -c $CONF  -g "daemon off;" 2>&1
EOF

cat <<'EOF' >"$svcdir"/log/run
#!/bin/sh
exec setuidgid logadmin multilog t s1000000 n100 ./main
EOF

chmod +x "$svcdir"/run
chmod +x "$svcdir"/log/run
chown -R logadmin:logadmin "$svcdir"/log
chmod -R go+w "$svcdir"/log
