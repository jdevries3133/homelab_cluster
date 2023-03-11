# Homelab Cluster

Directions for setting up my cluster, which runs across three nodes.


## microk8s

### Installation

Install microk8s version 1.23:

```bash
sudo snap install microk8s --channel=1.23/stable --classic
```

### Public IP Setup

After installation, you need to make one small configuration file change if you
want to be able to connect to the cluster from anywhere. Look at
`/var/snap/microk8s/current/certs/csr.conf.template`. You will see an `[
alt_names ]` section in this toml file, which will contain a list of IPs for
which microk8s will generate a self-signed SSL certificate. It looks like this:

```
[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = 127.0.0.1
IP.2 = 10.152.183.1
#MOREIPS
```

If you want the generated self-signed certificate to include your public IP,
add it!

```
IP.8 = xx.xx.xx.xx
```

Then run `microk8s reset` to ensure it picks up the change.

### Plugins

Then, enable the following plugins:

- `dns`
- `helm3`
- `ingress`
- `prometheus`
- `openebs`
- `fluentd`

After bootstrapping the cluster, remember to get context config with
`sudo microk8s config`, and copy that new config to wherever it is needed
(GitHub action runners, personal machine, etc.).

## Terraform (the rest of the owl)

The terraform module at the root of the project does some additional work to
set up the cluster:

- install certmanager by downloading manifests from the web
- create certmanager issuer via letsencrypt
- define ingresses for kibana and grafana
- define a service and ServiceMonitor for nginx metrics

## Velero

### Setup

Setup was kind of a manual pain in the butt (although I think a lot of this
could be automated with terraform later), but these are the steps:

1. Follow [this guide.](https://github.com/vmware-tanzu/velero-plugin-for-aws#setup)
   no need to do the while kubetoiam thing it suggests
2. Remember to add install flags `--use-restic` when installing velero

### Validate Install

At this point, you can use the Velero CLI to schedule regular backups. Also,
the app in `./simple_openebs_backup` will ensure that everything works
properly. It provisions both a replicated and local storage volume, mounts
it to a pod, and runs a very simple python script that just writes jokes
into log files inside of each volume. You can use this as a holistic test
of the Velero / Restic backups by doing the following:

1. Deploy the app, observe that it started up, mounted each volume, and is
   writing jokes to the log files.
2. Create a backup.
3. Delete the namespace, change the log files, or simulate some other disaster.
4. Restore from the backup

### Backup

To run a snapshot that cuts across the whole cluster broadly, use this command:

```bash
velero backup create $BACKUP_NAME --default-volumes-to-restic
```

However, it is better to create a scheduled backup like this:

```bash
velero schedule create cluster-backup --schedule="* 0 * * *" --default-volumes-to-restic
```

The CLI is pretty self-documenting, and there are a lot of options like which
namespaces to backup, when backups should expire (self-delete), etc.

If velero was installed with the parameter `--default-volumes-to-restic`, this
will properly backup the whole cluster, including persistent volumes. It is
important to remember to include this parameter, because otherwise volumes
without a special annotation won't be backed up. If the backup takes a short
amount of time, that's a smell test that this parameter was probably forgotten.

### Restore

Restoring is very easy. From the most recent backup, just run

```bash
velero restore create $RESTORE_NAME --from-backup $LATEST_BACKUP
```

This will iterate through every object in the cluster and restore anything
that is not present in the current cluster. In testing, I, for example, deleted
a whole namepace and then ran this command. It was able to roll the system
back to the state it was in at the last backup, including restoring data in
persistent volumes from the S3 bucket.
