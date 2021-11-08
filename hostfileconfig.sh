#!/bin/bash
localip=$(az vm show -d -g jenkin-rg -n vm-build --query privateIps -o tsv)
echo "[localhost]" > /etc/ansible/hosts
echo "$localip ansible_connection=local" >> /etc/ansible/hosts
docip=$(az vm show -d -g jenkin-rg -n docvm --query privateIps -o tsv)
echo "[remotehosts]" >> /etc/ansible/hosts
echo "$docip ansible_connection=ssh" >> /etc/ansible/hosts
