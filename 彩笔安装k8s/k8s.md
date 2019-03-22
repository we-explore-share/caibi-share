##  docker

### docker是什么

docker是容器技术的一种实现。容器技术其实很早就被提出了。

### docker有什么用

主要的作用有下面两点

* 保证环境一致
* 部署/迁移方便

`这里要举栗子`

### docker常用名词

镜像：包含整个文件系统的压缩包

容器：镜像跑起来就是容器

### docker怎么用

* 拿nginx来举个栗子

* 一般使用docker部署项目是直接将代码放到镜像里面，传输镜像，部署代码即部署容器。

### docker与虚拟机

* 以前经常给别人解释就说：你可以把docker理解成虚拟机。现在不这样说了，虽然做的工作是相同的，但是原理完全不同。
* 容器在宿主机上以一个进程的形式呈现，docker技术的原理其实就是在启动进程的时候，通过一些参数对进程能看到的，能用到的各种东西做了限制。所以开销比虚拟机少很多，这是称docker为轻量级虚拟化技术的直接原因。
* 缺点就是安全性没有虚拟机高。

## k8s

### k8s是什么

可以理解成服务器集群的操作系统

### k8s用法

写配置文件？？

### k8s安装

k8s分为很多服务模块，以前安装的时候要一个一个安装。不过现在已经简化很多了。这次我们就通过kubeadm来部署k8s。代码如下:

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

#部署
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

