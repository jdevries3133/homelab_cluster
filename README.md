# Homelab Cluster

bootstrap a cluster running across three nodes. Before applying any of the
manifests here, the following plugins should be enabled:

- dashboard
- dns
- helm3
- ingress
- openebs
- storage
- prometheus

Then, follow
[this guide](https://www.madalin.me/wpk8s/2021/050/microk8s-letsencrypt-cert-manager-https.html)
for setting up SSL certificates.

This creates a cluster ready to deploy web apps, where the apps can define
their own routing, and application deployment can be done with terraform.

## Monitoring

`microk8s enable prometheus` does 99% of the work. Just apply the prometheus_ingress manifest
at the root of this repository to bring traffic in. Open up the manifest and change the
host as necessary.

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

## Disaster Recovery

To run a snapshot that cuts across the whole cluster broadly, use this command:

```bash
velero backup create $BACKUP_NAME
```

If velero was installed with the parameter `--default-volumes-to-restic`, this
will properly backup the whole cluster, including persistent volumes.

Restoring is just as easy. From the most recent backup, just run

```bash
velero restore create $RESTORE_NAME --from-backup $LATEST_BACKUP
```

This will iterate through every object in the cluster and restore anything
that is not present in the current cluster. In testing, I, for example, deleted
a whole namepace and then ran this command. It was able to roll the system
back to the state it was in at the last backup, including restoring data in
persistent volumes from the S3 bucket.

## Scheduling Backups

Scheduling regular backups with cron syntax is very easy. The guide can be
[found here](https://velero.io/docs/v1.8/backup-reference/#schedule-a-backup)
