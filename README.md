# Homelab Cluster

Directions for setting up my cluster, which runs across three nodes.

## microk8s

First, install microk8s and enable the following plugins:

- dashboard
- dns
- helm3
- ingress
- openebs
- storage
- prometheus

## SSL Certificates & CertManager

Follow
[this guide](https://www.madalin.me/wpk8s/2021/050/microk8s-letsencrypt-cert-manager-https.html)
for setting up SSL certificates. The manifest at `./clusterissuer.yml` creates
a Cluster Issuer as described in the guide.

Something that is a little weird is that I followed the guide and named this
issuer `letsencrypt-prod`, whereas most people just name it `letsencrypt`.
You always need to be aware of this distinction since anything that uses this
issuer will need to reference it by name.

## Monitoring

`microk8s enable prometheus` does 99% of the work. Just apply the
`prometheus_ingress` manifest at the root of this repository to bring traffic
in.

## Backup

Setup was kind of a manual pain in the butt, but these are the steps:

1. Follow [this guide.](https://github.com/vmware-tanzu/velero-plugin-for-aws#setup)
   no need to do the while kubetoiam thing it suggests
2. Remember to add install flags `--use-restic` and `--default-volumes-to-restic`
   when installing velero
3. Patch the velero setup as described in [this GitHub issue,](https://github.com/vmware-tanzu/velero/issues/2858)
   which is necessary becaues microk8s has its pods stored in a different place
   than default upstream kubelet.

At this point, you can use the Velero CLI to schedule regular backups. Also,
the app in `./simple_openebs_backup` will ensure that everythiing works
properly. It provisions both a replicated and local storage volume, mounts
it to a pod, and runs a very simple python script that just writes jokes
into log files inside of each volume. You can use this as a holistic test
of the Velero / Restic backups by doing the following:

1. Deploy the app, observe that it started up, mounted each volume, and is
   writing jokes to the log files.
2. Create a backup.
3. Delete the namespace, change the log files, or simulate some other disaster.
4. Restore from the backup

## Disaster Recovery

To run a snapshot that cuts across the whole cluster broadly, use this command:

```bash
velero backup create $BACKUP_NAME
```

However, it is better to create a scheduled backup like this:

```bash
velero schedule create cluster-backup --schedule="* 0 * * *"
```

The CLI is pretty self-documenting, and there are a lot of options like which
namespaces to backup, when backups should expire (self-delete), etc.

If velero was installed with the parameter `--default-volumes-to-restic`, this
will properly backup the whole cluster, including persistent volumes.

Restoring is very easy. From the most recent backup, just run

```bash
velero restore create $RESTORE_NAME --from-backup $LATEST_BACKUP
```

This will iterate through every object in the cluster and restore anything
that is not present in the current cluster. In testing, I, for example, deleted
a whole namepace and then ran this command. It was able to roll the system
back to the state it was in at the last backup, including restoring data in
persistent volumes from the S3 bucket. However, it didn't seem to touch
namespaces that were backuped but otherwise unaffected.
