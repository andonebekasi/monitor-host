#!/bin/bash

# Password sudo untuk user ansible (andi)
export ANSIBLE_BECOME_PASS='isi-kalau-ada'

# Jalankan playbook
ansible-playbook -i /home/andi/tempt3/hosts /home/andi/tempt3/run_monitoring.yml
