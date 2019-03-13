#!/bin/bash

expect << END
spawn java -jar {{ ftmcli_install_dir }}/ftmcli-v2.4.2/ftmcli.jar list {{ container }}
expect -re "Enter your password:"
send "{{ opc_password }}\r"
set timeout -1
expect eof
END