#!/bin/bash
sudo apt-get update
sudo apt install ansible -y
cp k8s.yaml /tmp/k8s.yaml
sudo ansible-playbook /tmp/k8s.yaml
