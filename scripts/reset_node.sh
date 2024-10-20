#!/bin/bash

set -x

# !!! this script assumes that the node has already been drained !!!
# This will attempt to completely wipe kubernetes from the node

kubeadm reset --force
apt-get purge -y --allow-change-held-packages kubeadm kubectl kubelet kubernetes-cni kube*
apt-get autoremove -y
rm -rf \
    ~/.kube \
    /opt/cni/bin \
    /etc/cni/net.d \
    /etc/kubernetes \
    /mnt/openebs-ssd/* \

reboot now
