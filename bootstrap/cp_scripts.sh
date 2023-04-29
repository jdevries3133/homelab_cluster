#!/bin/bash

set -eux

# Copy these scripts from here to my machines 

for node in big-boi nick dweedledum
do
    scp bootstrap/* $node:/home/jack
    ssh $node chmod +x *.sh
done
