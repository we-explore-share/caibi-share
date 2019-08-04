# k8s新安装方法
之前使用的dockerhub上的一个镜像仓库，最近看到aliyun也有镜像仓库了，而且似乎很全不用再单独下镜像这次贴出命令。
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
apt install -y docker-ce kubeadm kubelet kubectl

#镜像加速器
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://xxxxxxxxx.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker

#部署
kubeadm init --image-repository=registry.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16

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
