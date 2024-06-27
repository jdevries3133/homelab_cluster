 Sometimes, my public IP changes, and I need to update the API server cert to
 have new SANs. Here is how I do that.

 Warning: this will only work with clusters that have a single control-plane
 node. I think that this borks high availability control planes, at least until
 all the control plane nodes get the new certs and kubelet is restarted on them.
 This is only an assumption, though, because I haven't tried it.

 First, backup the current certs before overwriting them, just in case.

 ```bash
sudo mv /etc/kubernetes/pki/apiserver.{crt,key} ~
```

Then, dump the current cluster config into a file. This contains the
`apiServer.certSANs` field, which you can revise to add new SANs.

```bash
kubectl \
  -n kube-system \
  get configmap \
  kubeadm-config \
  -o jsonpath='{.data.ClusterConfiguration}' \
  > clusterConfig.yaml
```

Once the new SANs have been added, we're ready to re-initialize the cluster.
Don't worry, this won't disrupt worker nodes.

```
sudo kubeadm init phase certs apiserver --config clusterConfig.yaml
```

That should write new API server certs to `/etc/kubernetes/pki`.
