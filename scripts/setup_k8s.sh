#!/bin/bash

set -eux

# This script presumes that the machine's /etc/hosts file has been configured,
# since my homelab network does not have DNS.
#
# This script installs kubelet and calico (CNI plugin) on the current node.
# After this script, it should be possible to run `kubeadm init`, such that
# this node can become a control-plane node or a worker node.


CLUSTER_PUBLIC_IP=71.251.203.182

# Note: run me as root!

### Setup K8S CLIs

#          apt-get update
#          apt-get install -y apt-transport-https ca-certificates curl
#          curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
#          echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
#          apt-get update
#          apt-get install -y kubelet kubeadm kubectl
#          apt-mark hold kubelet kubeadm kubectl
#
#
### Setup containerd

# From https://www.techrepublic.com/article/install-containerd-ubuntu/

apt-get install -y wget

wget https://github.com/containerd/containerd/releases/download/v1.6.18/containerd-1.6.18-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-1.6.18-linux-amd64.tar.gz

wget https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
mkdir -p /opt/cni/bin

tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.2.0.tgz
mkdir /etc/containerd

containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable --now containerd

echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
modprobe br_netfilter
sysctl -p /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward
