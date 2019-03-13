#!/bin/bash

expect << END
spawn java -jar {{ ftmcli_install_dir }}/ftmcli-v2.4.2/ftmcli.jar upload -N {{ backup_name }}.tar.gz {{ container }} {{ rman_backup_dir }}/{{ backup_name }}.tar.gz
expect -re "Enter your password:"
send "{{ opc_password }}\r"
set timeout -1
expect eof
END