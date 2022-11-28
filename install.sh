#!/bin/bash
set -e
ansible-playbook -i hosts.ini ./init.yml
ansible-playbook -i hosts.ini ./kube-dependencies.yml
ansible-playbook -i hosts.ini ./control-planes.yml
ansible-playbook -i hosts.ini ./workers.yml
ansible-playbook -i hosts.ini ./install-tools.yml

