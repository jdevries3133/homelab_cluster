#!/bin/bash

set -euxo pipefail

# Copy these scripts from here to my machines

for node in $(cat node_list.txt)
do
    scp scripts/* $node:
    ssh $node chmod +x *.bash
done
