# My Homelab Cluster

These are the scripts and configuration for my simple homelab Kubernetes
cluster. The cluster uses several technologies:

| Technology        | Purpose                                                  |
| ----------------- | -------------------------------------------------------- |
| containerd / runc | container runtime                                        |
| calico            | networking between containers                            |
| velero & restic   | backup and restore of cluster state & persistent volumes |
| certmanager       | automated issuance of LetsEncrypt certificates           |

## Prep Work

Before doing anything, there are a few steps to perform; especially if you're
adapting this work for a homelab setup that is not mine.

First, my node hostnames are hard-coded in these scripts; YMMV. Grep for
`big-boi`, `nick`, `tweedledee`, and `dweedledum`, which are the host names of
my machines, and replace them with your own!

Also, I do not have DNS setup in my home network. If you have DNS, that's
probably ideal and you can skip this. Instead, I go into my router
configuration and give my nodes static IPs, and then I put the host names into
the `/etc/hosts` file on each of the 4 nodes. For example, the `/etc/hosts`
file for `big-boi`:

```
127.0.0.1 big-boi
192.168.1.3 nick
192.168.1.4 tweedledee
192.168.1.9 dweedledum
```

## Bootstrapping the Nodes

> ⚠️ All scripts here must be run as root with `sudo`! ⚠️

First `./bootstrap/cp_scripts.bash` can be used to copy the bootstrap scripts to
each of your nodes. Note that you may need to tweak the ssh command to work in
the way that you normally ssh onto your machines. For example, I specify my
username in my `~/.ssh/config` file, so I can simply pass the hostname as a
single argument to `ssh` or `scp`, and it will work; YMMV.

There are two "setup" scripts:

- `./bootstrap/setup_node.bash` (all nodes)
- `./bootstrap/init_control_plane_node.bash` (control-plane node only)

The first script must be ran on every node. It installs the container runtime
and container networking interface (CNI).

### Bootstrapping the Control-Plane

First, you will need to bootstrap your control-plane node. I run a single
control-plane node which is perfectly adequate for homelab use-cases.

> ⚠️ Change the `PUBLIC_IP_ADDRESS` in the `setup_node.bash` script to your own
> public IP! ⚠️

To do this, run the `./bootstrap/init_control_plane_node.bash`

Keep your eyes peeled -- the output of this script will include important
details for next steps:

```text
# Command to run to add another control-plane node
kubeadm join big-boi:6443 --token xxxxx \
    --discovery-token-ca-cert-hash sha256:597d3c1ef8f7ca4238b877245e0e9b021e1d3fa6cb4b027d04b9565d4420835c \
    --control-plane 

# Command to run to add a worker node
kubeadm join big-boi:6443 --token xxxxx \
        --discovery-token-ca-cert-hash sha256:597d3c1ef8f7ca4238b877245e0e9b021e1d3fa6cb4b027d04b9565d4420835c 
```

Of course, if you miss this information, you can always use kubeadm to
re-generate these join commands later.

### Adding Workers or Control-Plane Nodes

Now that your first node is up and running, adding additional nodes is as
simple as:

1. Running the `setup_node.bash` script on the new node
2. Copying and pasting the `kubeadm` command from before with the connection
   token

`kubeadm` should then indicate that it was able to join the cluster.

## Using `kubectl`

The administrator `kubconfig` file is at `/etc/kubernetes/admin.conf` on the
node where you initialized the cluster. I just copy and paste this file onto my
own machine, and change the host to my public IP so that I can use kubectl to
talk to my cluster from anywhere. Obviously, this allows you to connect to the
cluster as the admin user, and it's best to use the principle of least
privilege always. Consider creating depermissioned users for collaborators or
CI/CD as needed.

## The Rest of the Owl

The terraform config in `cluster.tf` will populate the cluster with everything
you'd want as a cluster administrator, including:

- `nginx` ingress, making any worker node a suitable HTTP / HTTPS entrypoint
- `openebs` storage
- logging and monitoring stacks (prometheus/grafana & elastic search / kibana)
- `certmanager` for automatic SSL certificate issuance

### Setting Up Persistent Storage

I have a large 1tb SSD on a single node which is used to satisfy all
Persistent Volume Claims (PVC) in the cluster.

Terraform will prompt you for the path to this device as well as the hostname
of the node that has this storage when you run `terraform apply`.
