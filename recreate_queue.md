# February Recreate

Whelp, removing `big-boi` from the cluster borked it, so we're back to square
zero. This is kind of OK because;

1. I want to do ship of Theseus, and this is a first failure to that end
2. I distributed the cluster-admin credentials all over the place for my old
   cluster

#2 had me thinking I _probably should_ re-create my cluster before using it for
anything serious, anyway. This time, I'll create users and use
ClusterRoleBindings to give them access. If ever needed, at least I can revoke
the rolebinding from users if the cert leaks [as suggested
here](https://stackoverflow.com/a/70026941). Ideal would be not to use permanent
cryptographic keys for authentication into the cluster, but oh well, this is a
limitation of k8s and I'd need to add an auth plugin if I want short-lived
access.

# Progress

- tweedledee was wiped
