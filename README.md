# nginx lua 文件上传下载服务器

## Getting start

0. create directory `/data/fileserver/{conf,uploads}`

```
mkdir -p /data/fileserver/{conf,uploads}
chown -R 65534:65534 /data/fileserver/uploads
```

1. create `nginx.conf`

```
cat > /data/fileserver/conf/nginx.conf <<EOF
pid logs/nginx_fileserver.pid;
events {
    worker_connections 1024;
}

http {
    lua_load_resty_core off;
    lua_package_path    '/usr/local/lib/lua/5.1/?.lua;;';

    sendfile             on;
    tcp_nopush           on;
    gzip                 on;
    gzip_static          on;
    gzip_http_version    1.1;
    gzip_comp_level      2;
    gzip_min_length      1024;
    gzip_vary            on;
    gzip_types           text/plain text/javascript application/x-javascript text/css text/xml application/xml application/xml+rss;
    client_max_body_size 8192m;

    server {
        listen      80;
        server_name _;

        # download
        location /download {
            charset               utf-8;
            alias                 /data/uploads;
            fancyindex            on;
            fancyindex_exact_size on;
            fancyindex_localtime  on;

            if (\$request_filename ~* ^.*?\.(txt|log|pdf|doc|docx|csv|xls|xlsx|ppt|pptx|rar|zip|tar.gz|tar.xz|bz2|iso)$) {
                add_header  Content-Type "application/octet-stream;charset=utf-8";
                add_header  Content-Disposition "attachment; filename*=utf-8'zh_cn'\$arg_n";
            }
        }

        # upload
        location ~ ^/upload(/.*)?$ {

            # auth
            auth_basic           "Restricted site";
            auth_basic_user_file .htpasswd;

            set                 \$store_path /data/uploads\$1/;
            content_by_lua_file conf/lua/upload.lua;
        }

        # delete
        location ~ ^/delete/(.*)$ {

            # auth
            auth_basic           "Restricted site";
            auth_basic_user_file .htpasswd;

            set \$file_path      /data/uploads/\$1;
            content_by_lua_file conf/lua/delete.lua;
        }

        # root
        location / {
            return 403;
        }
    }
}
EOF
```

2. create `.htpasswd`

```
echo -n 'foo:' >> /data/fileserver/conf/.htpasswd
openssl passwd -apr1 >> /data/fileserver/conf/.htpasswd
```

3. run docker container

```
docker run -d -p 8001:80 --restart=always -v /data/fileserver/uploads:/data/uploads -v /data/fileserver/conf/nginx.conf:/usr/local/nginx/conf/nginx.conf -v /data/fileserver/conf/.htpasswd:/usr/local/nginx/conf/.htpasswd atompi/nginx-fileserver:v1.16.1
```

or use [docker-compose.yml](./docker-compose.yml)

```
docker-compose up -d
```

## Usage

0. download

open http://127.0.0.1:8001/download in browser and click file's URL. You can also use wget:

```
wget --user user --password password http://127.0.0.1:8001/download/1.txt
```

1. upload

```
curl -H "Authorization: Basic Zm9vOnBhc3N3b3Jk" -F filea=@a.txt -F fileb=@b.txt http://127.0.0.1:8001/upload    # Zm9vOnBhc3N3b3Jk=$(echo -ne "foo:password" | base64)
# or
curl --user foo:password -F filea=@a.txt -F fileb=@b.txt http://127.0.0.1:8001/upload
```

2. delete

```
curl --user foo:password http://127.0.0.1:8001/delete/1.txt
```
