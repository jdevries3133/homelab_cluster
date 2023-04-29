#!/bin/bash

set -eux

# !!! this script assumes that the node has already been drained !!!
# This will attempt to completely wipe kubernetes from the node

kubeadm reset
apt-get purge kubeadm kubectl kubelet kubernetes-cni kube*   
apt-get autoremove  
rm -rf ~/.kube

reboot now
