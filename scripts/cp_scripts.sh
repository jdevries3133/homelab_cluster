#!/bin/bash

set -eux

# Copy these scripts from here to my machines

for node in big-boi dweedledum tweedledee nick
do
    scp scripts/* $node:
    ssh $node chmod +x *.sh
done
