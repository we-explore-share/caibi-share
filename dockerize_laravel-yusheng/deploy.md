安装git，拉取项目

```
apt-get update && apt-get install git
```

安装docker/docker-compose(官方文档也有)

```
curl -fsSL get.docker.com -o get-docker.sh && \
sudo sh get-docker.sh --mirror Aliyun && \
sudo curl -L https://github.com/docker/compose/releases/download/1.17.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
sudo chmod +x /usr/local/bin/docker-compose
```

启动nginx_proxy

```
docekr-compose -f nginx_proxy.yml up -d
```

启动项目docker

```
docker-compose up -d
```

执行Laravel启动脚本

```
run entrypoint.sh
```

