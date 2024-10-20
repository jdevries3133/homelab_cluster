#!/bin/bash

set -eux

CLUSTER_PUBLIC_IP="$(curl checkip.amazonaws.com)"

echo "Adding Subject Alternative Name (SAN) $CLUSTER_PUBLIC_IP to the API server certs"

### Initialize the node & join the cluster
#
# Note: you can run `kubeadm reset`, and then just run from here down to
# reset the node without reinstalling containerd, runc, and the CNI plugin

kubeadm init \
    --control-plane-endpoint=big-boi \
    --upload-certs \
    --pod-network-cidr=10.0.0.0/24 \
    --service-cidr=10.0.1.0/24 \
    --apiserver-cert-extra-sans=$CLUSTER_PUBLIC_IP

# Install calico operator & CRDs
KUBECONFIG=/etc/kubernetes/admin.conf \
    kubectl create \
    -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml

# This custom-resources.yaml file needs to be present. I downloaded it from
# https://docs.tigera.io/calico/3.25/getting-started/kubernetes/self-managed-onprem/onpremises,
# and customized the CIDR block.
KUBECONFIG=/etc/kubernetes/admin.conf \
    kubectl create -f custom-resources.yaml

echo "Bootstrap complete; copy the kubectl config at /etc/kubernetes/admin.conf"
