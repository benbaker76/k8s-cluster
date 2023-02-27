#!/bin/bash
set -e
ansible-playbook -i hosts.ini --ssh-common-args='-o StrictHostKeyChecking=no' ./kube-dependencies.yml
ansible-playbook -i hosts.ini --ssh-common-args='-o StrictHostKeyChecking=no' ./control-planes.yml
ansible-playbook -i hosts.ini --ssh-common-args='-o StrictHostKeyChecking=no' ./workers.yml
ansible-playbook -i hosts.ini --ssh-common-args='-o StrictHostKeyChecking=no' ./install-tools.yml
