#!/bin/bash
for host in $(awk /ceph*/'{print $2}' /etc/hosts); do
    ping -c 1 $host > /dev/null
	if [ $? == 0 ]; then
	    echo -e "\033[32m"$host"\t[SUCCEESS]\033[0m"
	else echo -e "\033[31m"$host"\t[FAILED]\033[0m"
	fi
done
