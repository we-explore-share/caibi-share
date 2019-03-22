##  docker

### docker 是什么

docker 是容器技术的一种实现。容器技术其实很早就被提出了。

### docker 有什么用

主要的作用有下面两点

* 保证环境一致
* 部署/迁移方便

`这里要举栗子`

### docker 常用名词

镜像：包含整个文件系统的压缩包

容器：镜像跑起来就是容器

### docker 怎么用

* 拿 nginx 来举个栗子
  * docker pull
  * docker images
  * docker rmi
  * docker run
  * docker ps
  * docker exec
  * docker stop
  * docker start
  * docker rm

* 一般使用 docker 部署项目是直接将代码放到镜像里面，传输镜像，部署代码即部署容器。
  * dockerfile
### 从镜像仓库下载镜像慢怎么办
各种大厂都有自己的镜像加速，我一般用阿里云的。

### docker 与虚拟机

* 以前经常给别人解释就说：你可以把 docker 理解成虚拟机。现在不这样说了，虽然做的工作是相同的，但是原理完全不同。
* 容器在宿主机上以一个进程的形式呈现， docker 技术的原理其实就是在启动进程的时候，通过一些参数对进程能看到的，能用到的各种东西做了限制。所以开销比虚拟机少很多，这是称 docker 为轻量级虚拟化技术的直接原因。
* 缺点就是安全性没有虚拟机高。

### docker-compose?
docker-compose是轻量级编排工具，如果觉得kubernetes重的话，可以了解了解。
这个交给`禹声`之后来分享吧

### 还有没有其他编排工具？
有目前常见的按照量级从轻到重是：
* docker-compose
* docker swarm
* k8s
为什么没有说过 swarm 呢？因为目前的形式来看 swarm 往下既没有 docker-compose 轻量，往上又没有 k8s 功能强大，目前是处在一个比较尴尬的位置吧。不过阿里云的容器服务目前支持 swarm 和 k8s 两种编排工具。其他厂就不清楚了。

## k8s

### k8s 是什么

可以理解成服务器集群的操作系统

### k8s 用法

写配置文件？？本来你可以直接使用命令行工具 kubectl 来控制k8s的，不过这样做并不推荐。写成配置文件，不容易出错。并且将配置文件放到版本控制工具当中，你的整个集群就有了版本控制。

### k8s 安装

k8s 分为很多服务模块，以前部署的时候要一个一个安装。不过现在已经简化很多了，这次我们就通过 kubeadm 来部署 k8s 。

kubeadm 专门被用来部署 k8s ，好像是哪里的小学生写的？

kubeadm 会以容器的形式部署 k8s 。但是有些组件如果通过容器部署，使用起来会很麻烦。于是当你在 ubunut 上安装 kubeadm 时会附带安装上这些不能通过容器部署的组件，比如 kubectl 等。而其他的组件则会通过容器的形式安装。

k8s 需要的镜像并没有保存在 dockerhub 上，而是保存在 google 的服务器上，于是我们得想办法拿到这些镜像。用搜索引擎搜了一下解决方案，发现 dockerhub 上有一个镜像仓库，里面是 k8s 组件的镜像的镜像。（应该明白什么意思吧？）这个镜像仓库叫做 `mirrorgooglecontainers` 。

kubeadm init 命令用来部署 k8s ，这条命令可以配置获取镜像的地址，我们就正好把地址改为 `mirrorgooglecontainers`。

k8s安装好后需要自行安装网络插件才能正常跑起来，有很多网络插件可用，这里就用用的比较多的 flannel 吧。我也不知道各个网络插件的具体特性。我们按照 flannel 的文档来安装，其实就是让 kubectl 应用一个配置文件。由于 flannel 插件的默认网段是 10.244.0.0/16，所以在部署 k8s 时我们会直接通过 `--pod-network-cidr` 选项来配置 k8s 工作的网段。

最后就是运行第一个nginx应用。

代码如下:

```bash
apt update
apt install -y apt-transport-https ca-certificates curl software-properties-common
#docker源
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"

#kubeadm源
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

apt update
apt install -y docker-ce kubeadm

#镜像加速器
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://s1tgid5l.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker

#1.先下载两个特别的镜像
docker pull coredns/coredns:1.2.6
docker tag coredns/coredns:1.2.6 mirrorgooglecontainers/coredns:1.2.6

wget https://github.com/coreos/flannel/releases/download/v0.11.0/flanneld-v0.11.0-amd64.docker
docker load < flanneld-v0.11.0-amd64.docker

#部署
kubeadm init --image-repository=mirrorgooglecontainers --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#应用网络插件
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

#设置master也可以部署应用
kubectl taint nodes --all node-role.kubernetes.io/master-
#运行nginx
kubectl run my-app --image=nginx --port=80

#暴露端口
kubectl expose deployment my-app --type=NodePort
```

