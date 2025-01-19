# OpenEBS Replication

I'm preparing to add replicated storage to my cluster. Previously, I've only
used host-path persistent volumes. OpenEBS can automate the provisioning of
local persistent volumes from a storage-class. It is nice that I have automated
provisioning of local persistent storage, but this is not ideal for a few
reasons;

- no redundancy; a single drive failure can result in loss of a database
- taking nodes offline is a PITA; I need to manually backup and restore PV
  contents if I want to take a node offline for upgrades
- taking nodes offline causes downtime

The main driving force behind this change is a desire to make cluster upgrades
easier. When so much manual work is required to take nodes offline, it both
blocks me from being able to sustainably add new stateful workloads to my
cluster, and also makes it hard for me to keep up with K8s upgrades.

## Prerequisites

### NVMe-tcp Kernel Module

The "NVMe-tcp" kernel module can be loaded with;

```
sudo modprobe nvmet_tcp
```

This has been completed on all nodes.


### HugePages

I enabled HugePages on all nodes according to [OpenEBS
docs](https://openebs.io/docs/user-guides/replicated-storage-user-guide/replicated-pv-mayastor/rs-installation#verifyenable-huge-page-support).

### Installing Storage into `big-boi`, `tweedledee`

`tweedledee` and `big-boi` need SSDs if they're going to join the replicated
storage party.

I just backed up `etcd` from `big-boi`, and put the backups on my home folder of
`big-boi`, my laptop, and google drive. This means that it should be safe to do
a reboot test on `big-boi`. I should be able to boot it down, workloads should
be OK (though uncontrollable through the cluster API), and then I should be able
to boot `big-boi` back up, and things should still be OK. If that blackout
test is successful, I'll be able to install storage in `big-boi` when it's
booted down, and reboot it as needed.

Installing storage in `tweedledee` is much easier, since it's not even part of
the cluster now.

### Disk Pool

Now, I need to find some block devices to offer to OpenEBS. The disk pool
requirements are [documented
here](https://openebs.io/docs/user-guides/replicated-storage-user-guide/replicated-pv-mayastor/rs-installation#diskpool-requirements);

> - Disks must be unpartitioned, unformatted, and used exclusively by the
>   DiskPool.
> - The minimum capacity of the disks should be 10 GB.

Here is the current state of the cluster:

```
=== big-boi
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0  55.7M  1 loop /snap/core18/2829
loop1                       7:1    0  55.4M  1 loop /snap/core18/2846
loop2                       7:2    0  89.4M  1 loop /snap/lxd/31333
loop3                       7:3    0    64M  1 loop /snap/core20/2379
loop4                       7:4    0  44.3M  1 loop /snap/snapd/23258
loop5                       7:5    0    87M  1 loop /snap/lxd/29351
loop6                       7:6    0  44.4M  1 loop /snap/snapd/23545
loop8                       7:8    0  63.7M  1 loop /snap/core20/2434
sda                         8:0    0 223.6G  0 disk /var/lib/kubelet/pods/f14a1954-588c-43e5-8249-ea59f66fa431/volume-subpaths/pg-sample-config/postgresql/3
                                                    /var/lib/kubelet/pods/1c20df21-1a7b-4c1c-803a-13e6e3261a30/volume-subpaths/pg-sample-config/postgresql/3
                                                    /var/lib/kubelet/pods/7aa34a6a-8d7a-476b-9f9d-0134f046fd20/volume-subpaths/pg-sample-config/postgresql/3
                                                    /var/lib/kubelet/pods/ebe0b0fb-43fa-490a-a0cd-ae1245def405/volume-subpaths/config/openebs-ndm/0
                                                    /var
sdb                         8:16   0 119.2G  0 disk 
├─sdb1                      8:17   0     1G  0 part /boot/efi
├─sdb2                      8:18   0     2G  0 part /boot
└─sdb3                      8:19   0 116.2G  0 part 
  └─ubuntu--vg-ubuntu--lv 253:0    0  58.1G  0 lvm  /var/lib/kubelet/pods/f14a1954-588c-43e5-8249-ea59f66fa431/volumes/kubernetes.io~local-volume/pvc-e6184850-7926-4804-8935-cf3b75ed3810
                                                    /var/lib/kubelet/pods/1c20df21-1a7b-4c1c-803a-13e6e3261a30/volumes/kubernetes.io~local-volume/pvc-b03d46d3-6d29-4104-b650-91d5bdb65afa
                                                    /var/lib/kubelet/pods/7aa34a6a-8d7a-476b-9f9d-0134f046fd20/volumes/kubernetes.io~local-volume/pvc-79fb3eca-0a6c-44d9-a810-82f3b720672e
                                                    /
=== nick
NAME                         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda                            8:0    0 447.1G  0 disk 
├─sda1                         8:1    0     1G  0 part /boot/efi
├─sda2                         8:2    0     2G  0 part /boot
└─sda3                         8:3    0 444.1G  0 part 
  └─ubuntu--vg--1-ubuntu--lv 252:0    0   100G  0 lvm  /var/lib/kubelet/pods/e94d300a-a4bd-4a12-a437-6f4ce68b6896/volume-subpaths/config/openebs-ndm/0
                                                       /
sdb                            8:16   0 931.5G  0 disk 
└─sdb1                         8:17   0 931.5G  0 part /mnt/openebs-ssd
=== tweedledee
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0 447.1G  0 disk 
├─sda1   8:1    0     1M  0 part 
├─sda2   8:2    0    30G  0 part /var/lib/kubelet/pods/148dbd8e-b898-4d9d-b9cd-b61dd9236317/volume-subpaths/config/openebs-ndm/0
│                                /
└─sda3   8:3    0 417.1G  0 part /mnt/openebs-ssd
=== dweedledee
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0  55.4M  1 loop /snap/core18/2846
loop1                       7:1    0  89.4M  1 loop /snap/lxd/31333
loop2                       7:2    0  55.7M  1 loop /snap/core18/2829
loop3                       7:3    0    64M  1 loop /snap/core20/2379
loop4                       7:4    0  44.3M  1 loop /snap/snapd/23258
loop5                       7:5    0  44.4M  1 loop /snap/snapd/23545
loop7                       7:7    0    87M  1 loop /snap/lxd/29351
loop8                       7:8    0  63.7M  1 loop /snap/core20/2434
sda                         8:0    0 119.2G  0 disk 
├─sda1                      8:1    0     1M  0 part 
├─sda2                      8:2    0     2G  0 part /boot
└─sda3                      8:3    0 117.2G  0 part 
  └─ubuntu--vg-ubuntu--lv 253:0    0  58.6G  0 lvm  /var/lib/kubelet/pods/7346f2ac-5398-4cb6-b897-03fa52386449/volume-subpaths/config/openebs-ndm/0
                                                    /
sdb                         8:16   0 447.1G  0 disk 
└─sdb1                      8:17   0 447.1G  0 part /mnt/openebs-ssd
```

I think that shrinking all current persistence into a single place is a good
place to start. I want to free up;

1. dweedledee `/dev/sdb`
2. nick `/dev/sdb`
3. nick drive ++

It probably makes sense to add a drive to `nick`, because I think it has
capacity.

Obviously, this makes `nick` more of a hotspot as a source of failure, but
that's OK.

Longer term, I can probably scale the cluster down such that `nick`,
`dweedledee`, and one other node (for `etcd` quorum only) are present in the
cluster. At that point, it frees one node to do upgrades / changes, which can
include adding OpenEBS disks, and then I ultimately end up in a state where ship
of theseus can begin.

Additionally, I think we'll move all host-path volumes onto the OS file-system
of `big-boi`, which frees up `/dev/sdb` on `nick` and `dweedledee` (currently
used for `/mnt/openebs-ssd`.

So, the next steps are;

1. take my extra drive, and insert it into `nick`.
2. move all host-mount DBs to `big-boi` or `tweedledee` `/mnt/openebs-ssd`
3. wipe `/dev/sdb` on `nick`, `dweedledee`
4. create myastor replicated cluster
   (https://openebs.io/docs/user-guides/replicated-storage-user-guide/replicated-pv-mayastor/rs-installation#diskpool-requirements)
