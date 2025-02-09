#!/bin/bash

set -eux

CNI_PLUGIN_VERSION='1.6.2'
CONTAINERD_VERSION='1.7.25'
KUBERNETES_VERSION='1.32'
RUNC_VERSION='1.2.4'

APT_REPOSITORY="deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /"

RELEASE_KEY="$(cat <<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.5 (GNU/Linux)

mQENBGMHoXcBCADukGOEQyleViOgtkMVa7hKifP6POCTh+98xNW4TfHK/nBJN2sm
u4XaiUmtB9UuGt9jl8VxQg4hOMRf40coIwHsNwtSrc2R9v5Kgpvcv537QVIigVHH
WMNvXeoZkkoDIUljvbCEDWaEhS9R5OMYKd4AaJ+f1c8OELhEcV2dAQLLyjtnEaF/
qmREN+3Y9+5VcRZvQHeyBxCG+hdUGE740ixgnY2gSqZ/J4YeQntQ6pMUEhT6pbaE
10q2HUierj/im0V+ZUdCh46Lk/Rdfa5ZKlqYOiA2iN1coDPIdyqKavcdfPqSraKF
Lan2KLcZcgTxP+0+HfzKefvGEnZa11civbe9ABEBAAG0PmlzdjprdWJlcm5ldGVz
IE9CUyBQcm9qZWN0IDxpc3Y6a3ViZXJuZXRlc0BidWlsZC5vcGVuc3VzZS5vcmc+
iQE+BBMBCAAoBQJnFF34AhsDBQkIK2yBBgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIX
gAAKCRAjRlTamilkNtOACACDK9dQ8CH2Ji9C3Q926nVMUiXdyJK1onCBrQSEBqdR
LJaT6hGx5pzxkQGgUDpS9p7LA0u920HKLwGb7yIAWtyE5TAj2CYprGgpq98sfsGC
+U5T9IrAdya/BaTAkkP6gNhfMjNaK3bOWsvuLRlluKMNch4ify+IwLqc1JLG40bj
2HnKBGYkC3m0VtQfUuPQMImSLta/NwRHJMPo8jfGyManqMMxp35/ecP2rXMfb/l1
WjFDY7h+6nqXay20ljMXkN23W8wFTdvC6lq45wwM5IBnKNR/TjNNYAIizZoHFWz1
c/ecMWWWCB2S7WbY4xI3JSCOD4XIff3ie7pc68/kgPytiQIcBBMBAgAGBQJjB6F3
AAoJEM8Lkoze1k873TQP/0t2F/jltLRQMG7VCLw7+ps5JCW5FIqu/S2i9gSdNA0E
42u+LyxjG3YxmVoVRMsxeu4kErxr8bLcA4p71W/nKeqwF9VLuXKirsBC7z2syFiL
Ndl0ARnC3ENwuMVlSCwJO0MM5NiJuLOqOGYyD1XzSfnCzkXN0JGA/bfPRS5mPfoW
0OHIRZFhqE7ED6wyWpHIKT8rXkESFwszUwW/D7o1HagX7+duLt8WkrohGbxTJ215
YanOKSqyKd+6YGzDNUoGuMNPZJ5wTrThOkTzEFZ4HjmQ16w5xmcUISnCZd4nhsbS
qN/UyV9Vu3lnkautS15E4CcjP1RRzSkT0jka62vPtAzw+PiGryM1F7svuRaEnJD5
GXzj9RCUaR6vtFVvqqo4fvbA99k4XXj+dFAXW0TRZ/g2QMePW9cdWielcr+vHF4Z
2EnsAmdvF7r5e2JCOU3N8OUodebU6ws4VgRVG9gptQgfMR0vciBbNDG2Xuk1WDk1
qtscbfm5FVL36o7dkjA0x+TYCtqZIr4x3mmfAYFUqzxpfyXbSHqUJR2CoWxlyz72
XnJ7UEo/0UbgzGzscxLPDyJHMM5Dn/Ni9FVTVKlALHnFOYYSTluoYACF1DMt7NJ3
oyA0MELL0JQzEinixqxpZ1taOmVR/8pQVrqstqwqsp3RABaeZ80JbigUC29zJUVf
=Eplj
-----END PGP PUBLIC KEY BLOCK-----
EOF
)"

# This script presumes that the machine's /etc/hosts file has been configured,
# since my homelab network does not have DNS.
#
# This script must be run on every node, regardless of whether it is a
# control-plane node or a worker, because it simply includes the container
# runtime and networking plugins as well as kubeadm itself.
#
# This script installs kubelet and calico (CNI plugin) on the current node.
# After this script, it should be possible to run `kubeadm init`, such that
# this node can become a control-plane node or a worker node.

### Setup K8S CLIs

echo "$RELEASE_KEY" \
    | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "$APT_REPOSITORY" > /etc/apt/sources.list.d/kubernetes.list
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl

apt-get update -y
apt-mark unhold kubelet kubectl
apt-get update -y
apt-get install -y kubelet kubectl kubeadm
apt-mark hold kubelet kubectl

apt-get install -y wget

wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

wget https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

wget https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGIN_VERSION}/cni-plugins-linux-amd64-v${CNI_PLUGIN_VERSION}.tgz
mkdir -p /opt/cni/bin

tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v${CNI_PLUGIN_VERSION}.tgz
mkdir -p /etc/containerd

containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable --now containerd

echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
modprobe br_netfilter
sysctl -p /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

cp /etc/fstab fstab.bak
sed -i '/swap/d' /etc/fstab
swapoff -a
