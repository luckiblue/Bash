#!/bin/bash

echo -e "Checking status of rbd devices..."

for pool in $(ceph osd lspools | awk '{print $2}')
do
	for image in $(rbd -p $pool ls)
	do
	rbd_status=$(rbd status $pool/$image)
	rbd_watcher="`echo -e $rbd_status | awk -F "=|:" '{print $3}'`"
	if [[ $rbd_status != *"none"* ]]; then
		echo -e "Image \e[31m"$image"\e[0m in pool \e[31m"$pool"\e[0m is used by host with IP addr "$rbd_watcher
	else
		echo -e "Image \e[32m"$image"\e[0m in pool \e[32m"$pool"\e[0m is unmapped."
	fi
	done;
done;
