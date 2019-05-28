# k8s安装

`k8s` 分为很多服务模块，以前部署的时候要一个一个安装。不过现在已经简化很多了，这次我们就通过 `kubeadm` 来部署 `k8s` 。

## 第一步

更新系统，添加源，代码如下：

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
```

## 第二步

安装 `kubeadm` 和 `docker-ce` 。`kubeadm` 会以容器的形式部署 `k8s` 。但是有些组件如果通过容器部署，使用起来会很麻烦。于是当你在  `ubunut` 上安装 `kubeadm` 时会附带安装上这些不能通过容器部署的组件，比如 `kubectl` 等。而其他的组件则会通过容器的形式安装。代码如下：

```bash
apt install -y docker-ce kubeadm
```

## 第三步（可选）

添加镜像加速地址，我一般使用的是阿里云镜像服务中的镜像加速地址。代码如下：

```bash
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://xxxxxx.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker
```

## 第四步

手动下载两个依赖镜像。 `k8s` 需要的镜像并没有保存在 `dockerhub` 上，而是保存在 `google` 的服务器上。好在使用 `kubeadm` 部署 `k8s` 时可以指定其他的镜像仓库，而 `dockerhub` 上有另一个镜像仓库，里面是 `k8s` 组件的镜像。这个镜像仓库叫做 `mirrorgooglecontainers` 。有两个依赖镜像没有被放到这个镜像仓库中：`coredns/coredns` 和 `coreos/flannel` 。我们先把这两个镜像下载下来。命令如下：

```bash
docker pull coredns/coredns:1.2.6
docker tag coredns/coredns:1.2.6 mirrorgooglecontainers/coredns:1.2.6

wget https://github.com/coreos/flannel/releases/download/v0.11.0/flanneld-v0.11.0-amd64.docker
docker load < flanneld-v0.11.0-amd64.docker
```

第一个镜像是 `k8s` 内部使用的DNS和服务发现服务镜像，第二个镜像是网络插件 `flannel` 的镜像。第一个镜像需要改名与 `mirrorgooglecontainers` 一致， `k8s` 在安装开始的时候就会需要它，第二个镜像不用改名之后会用到。

## 第五步

开始部署 `k8s` ，命令如下：

```bash
kubeadm init --image-repository=mirrorgooglecontainers --pod-network-cidr=10.244.0.0/16
```

这里指定了镜像仓库和 `cidr` ，指定 `cidr` 的原因是因为网络插件 `flannel` 默认就是使用的这个 `cidr` ，不指定的话网络插件 `k8s` 依然跑步起来。接下来就是等待了，如果部署的过程中报错，附录里面有典型报错的解决办法。

## 第六步

配置 `k8s` 。当 `k8s` 顺利部署上以后，会提示你执行三条命令，这样 `kubectl` 就能根据配置连接到当前部署的这个 `k8s` 集群中。代码如下：

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

## 第七步

应用网络插件，我们这里使用的是比较通用的 `flannel` 网络插件。网络插件的具体信息请自行 `google` 。代码如下：

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

## 第八步

验证安装是否成功。上面的命令执行完以后，稍微等一下，然后执行命令：

```bash
kubectl get pods --namespace=kube-system
```

插件所有 `pod` 是否都是 `running` 状态。如果不是 `running` 状态就需要查看 `pod 描述`或者 `pod 日志` 来排查错误，这两条命令分别是：

```bash
# 查看pod描述，主要看最下面的events
kubectl -n kube-system describe pod xxxxxxx #pod名称

# 查看pod日志
kubectl -n kube-system logs xxxxxxx # pod名称
```

至此，`k8s` 部署完成。之后的 `join` 请自行 `google` 。

## 附录

### 所有代码

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
  "registry-mirrors": ["https://xxxxxxxxx.mirror.aliyuncs.com"]
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

#这个跳过
#kubeadm join --token.....

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#应用网络插件
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

kubectl get pods --namespace=kube-system

# 下面的命令可选
#设置master也可以部署应用
kubectl taint nodes --all node-role.kubernetes.io/master-
#运行nginx
kubectl run my-app --image=nginx --port=80

kubectl get deployments

#暴露端口
kubectl expose deployment my-app --type=NodePort

kubectl get services
```

### 安装错误

#### 1. 安装时报下载镜像失败

这里需要注意报的是下载那个镜像失败，如果是 `coredns/coredns` 这个镜像，那你应该能发现报错中的镜像版本跟我们下载的镜像版本不同，这说明新版本的 `k8s` 需要依赖新版本的 `coredns/coredns` 镜像，按照上面的命令重新下载和重命名新版本镜像即可。其他的情况就只能是网络问题了。

#### 2. 安装时报swap错

`k8s` 一般不推荐宿主机使用 `swap`，关闭 `swap` 即可。也可忽略，方法见第四条。

#### 3. 配置没有达到要求

`k8s` 会检查系统硬件配置，以保证自身运行顺畅，也可忽略，方法见第四条。

#### 4. 忽略报错继续执行

在 `init` 时加上参数 `--ignore-preflight-errors` 后面跟错误的名称。在重新执行 `init` 时，请先执行

```bash
kubeadm reset
```

以此消除上一次安装可能产生的影响。
