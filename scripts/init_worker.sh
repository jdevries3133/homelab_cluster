#!/bin/bash

set -eux

# This script initializes a worker node, such that it becomes part of the
# cluster. After running it, the new worker node should promptly appear in a
# ready state in `kubectl get nodes`

kubeadm init
    --control-plane-endpoint=big-boi \
    --pod-network-cidr=10.0.0.0/24 \
    --service-cidr=10.0.1.0/24 \
    --apiserver-cert-extra-sans=$CLUSTER_PUBLIC_IP

KUBECONFIG=/etc/kubernetes/admin.conf \
    kubectl create \
    -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml

# This custom-resources.yaml file needs to be present. I downloaded it from
# https://docs.tigera.io/calico/3.25/getting-started/kubernetes/self-managed-onprem/onpremises,
# and customized the CIDR block. Need to make sure that guy ends up in
# whatever repo comes of this process
KUBECONFIG=/etc/kubernetes/admin.conf \
    kubectl create -f custom-resources.yaml


echo "You need to this now as your own user:
    mkdir -p /home/jack/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/jack/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config

Or, copy the kubeconfig to your local machine to proceed that way.
"


