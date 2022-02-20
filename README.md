# Homelab Cluster

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

## Backup

This subdirectory has configuration information for backup of volumes via
velero / restic things.

Setup was kind of a manual pain in the butt, but these are the steps:

1. Follow [this guide.](https://github.com/vmware-tanzu/velero-plugin-for-aws#setup)
   no need to do the while kubetoiam thing it suggests
2. Remember to add install flags `--use-restic` and `--default-volumes-to-restic`
   when installing velero
3. Patch the velero setup as described in [this GitHub issue,](https://github.com/vmware-tanzu/velero/issues/2858)
   which is necessary becaues microk8s has its pods stored in a different place
   than default upstream kubelet.
