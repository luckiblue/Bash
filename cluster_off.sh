#!/bin/bash

echo -e "Shutting down cluster...\n"
sleep 5


echo -e "Checking status of rbd devices..."

for pool in $(ceph osd lspools | awk '{print $2}')
do
	for image in $(rbd -p $pool ls)
	do
	rbd_status=$(rbd status $pool/$image);
	if [[ $rbd_status != *"none"* ]]; then
		echo -e "There are some rbd images in use. Unmount and unmap them from client side, then restart shutdown script.\nSee 'rbd status' command for more."
		exit 0;
	fi
	done;
done;

echo -e "Setting flags for clean cluster shutdown...\n"

ceph osd set noout
NOOUT=$?
if [ $NOOUT -ne 0 ]; then
 echo -e "Error running \e[31mceph osd set noout\e[0m."
 exit 0;
fi

ceph osd set nobackfill
NOBACKFILL=$?
if [ $NOBACKFILL -ne 0 ]; then
 echo -e "Error running \e[31mceph osd set nobackfill\e[0m."
 exit 0;
fi


ceph osd set norecover
NORECOVER=$?
if [ $NORECOVER -ne 0 ]; then
 echo -e "Error runnning \e[31mceph osd set norecover\e[0m."
 exit 0;
fi


ceph osd set norebalance
NOREBALANCE=$?
if [ $NOREBALANCE -ne 0 ]; then
 echo -e "Error running \e[31mceph osd set norebalance\e[0m."
 exit 0;
fi


ceph osd set nodown
NODOWN=$?
if [ $NODOWN -ne 0 ]; then
 echo -e "Error running \e[31mceph osd set nodown\e[0m."
 exit 0;
fi


ceph osd set pause
PAUSE=$?
if [ $PAUSE -ne 0 ]; then
 echo -e "Error running \e[31mceph osd set pause\e[0m."
 exit 0;
fi

echo -e "Shutting down cluster nodes in 5 sec...\n"
sleep 5

echo -e "Node ceph-client is going down.\n"
ssh ceph-client 'sudo shutdown -h now'
sleep 2
echo -e "Node ceph-mgr is going down.\n"
ssh ceph-mgr 'sudo shutdown -h now'
sleep 2
echo -e "Node ceph-osd2 is going down.\n"
ssh ceph-osd2 'sudo shutdown -h now'
sleep 2
echo -e "Node ceph-osd1 is going down.\n"
ssh ceph-osd1 'sudo shutdown -h now'
sleep 2
echo -e "Node ceph-mon is going down.\n"
ssh ceph-mon 'sudo shutdown -h now'
echo -e "Please remember about shutting down admin node. Node ceph-admin needs to be shut down manually.\n"
