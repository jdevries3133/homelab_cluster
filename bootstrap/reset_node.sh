#!/bin/bash

set -eux

# !!! this script assumes that the node has already been drained !!!
# This will attempt to completely wipe kubernetes from the node

kubeadm reset --force
apt-get purge -y --allow-change-held-packages kubeadm kubectl kubelet kubernetes-cni kube*
apt-get autoremove -y
rm -rf \
    ~/.kube \
    /opt/cni/bin \
    /etc/containerd \
    /etc/containerd/config.toml \
    /etc/systemd/system/containerd.service

reboot now
