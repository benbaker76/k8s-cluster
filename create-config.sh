#!/bin/bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@192.168.122.191 mkdir /home/ubuntu/.kube
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@192.168.122.191 sudo cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@192.168.122.191 sudo chmod +r /home/ubuntu/.kube/config
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@192.168.122.191:/home/ubuntu/.kube/config ~/.kube
