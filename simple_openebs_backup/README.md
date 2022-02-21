This application creates a test fixture against which OpenEBS backup & restore
can be tested. In my case, I'm doing backup and restore with Velero and Restic.
The setup, backup, and recovery procedures are documented in the
[top-level README](../README.md)

This application creates a test fixture which you can use to manually validate
that things are working as expected. Specifically, it deploys an application
which mounts two volumes, an openebs-jiva volume at `/replicated`, and a
local volume at `/local`. Each second, a random joke is written into a file
named `jokes.log` inside each of those mount points. The IaC will mount
replicated and host volumes, respectively onto those mount points.

To validate that the backup/restore procedures work, follow these steps:

1. Deploy this app. Observe that PV/PVC's are working, and jokes are being
   written into both volumes.
2. Create a backup.
3. Delete the namespace, validate that PV/PVCs were deleted from the cluster,
   or delete them manually.
4. Restore from the backup
5. The timestamps and content in `jokes.log` files will validate that the
   backup operation worked succesfully, besides the fact that the whole app in
   the deleted namespace should now be back to normal.
