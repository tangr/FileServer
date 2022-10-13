# nginx lua 文件上传下载服务器

## Getting start

0. create directory `/data/fileserver/{conf,uploads}`

```
mkdir -p /data/fileserver/{conf,uploads}
chown -R 65534:65534 /data/fileserver/uploads
```

1. create `nginx.conf`

```
cp nginx.conf /data/fileserver/conf/nginx.conf
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
