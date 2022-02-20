The goal is to setup backup and restore on local volumes and replicated volumes
created by Opensbs by using a tool called Velero.

I have no idea how any of this works, but here is an application that mounts
one of each type of file, and just writes a message to a log file in that
volume every second.

This will allow me to get a feel for the backup and restore process of openebs
volumes via Velero, and hopefully create a disaster recovery plan that is
sufficient to make me comfortable deploying stateful workloads to my cluster.
