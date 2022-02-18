# Homelab Cluster

These are the yaml configurations for my homelab cluster. microk8s is used to
bootstrap a cluster running across three nodes. Before applying any of the
manifests here, the following plugins should be enabled:

- dashboard
- dns
- helm3
- ingress
- openebs
- storage

Then, follow
[this guide](https://www.madalin.me/wpk8s/2021/050/microk8s-letsencrypt-cert-manager-https.html)
for setting up SSL certificates.

This creates a cluster ready to deploy web apps, where the apps can define
their own routing, and application deployment can be done with terraform.
