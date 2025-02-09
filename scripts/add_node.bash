#!/bin/bash

# Add this node to the cluster.
#
### PREREQUISITE
#
# Installing OS software via ./setup_node.bash should happen first.

set -eux

echo "This script is not finished; it's a loose set of commands that need to happen. Review the source of this script!"
exit 1

# This kubeadm join command was taken from the real command used for `nick`.
#
# We want to establish the node as a control-plane node, and then remove the
# NoSchedule taint, so that each node acts as a control-plane and worker
# node simultaneously.
kubeadm join \
    cluster.jackdevries.com:6443 \
    --token ${JOIN_TOKEN} \
    --discovery-token-ca-cert-hash ${DISCOVERY_TOKEN_CA_CERT_HASH} \
    --control-plane \
    --certificate-key ${CERTIFICATE_KEY}

# If we're running as root, we can use the admin.conf for later kubectl
# commands.
export KUBECONFIG=/etc/kubernetes/admin.conf

TODO: we need to remove the NoSchedule taint from new node.
We can use kubectl for this

# We need to tack this label onto each new node if we want it to be able to
# act as a mayastor storage node.
# https://openebs.io/docs/user-guides/replicated-storage-user-guide/replicated-pv-mayastor/rs-installation#label-io-node-candidates
kubectl label node ${NEW_NODE} openebs.io/engine=mayastor

