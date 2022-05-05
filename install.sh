#!/bin/bash
sudo apt-get update
sudo apt install ansible -y
sudo ansible-playbook /tmp/k8s.yaml
