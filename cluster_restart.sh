#!/bin/bash

echo -e "Shutting down cluster...\n"
sleep 5
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

echo -e "Restarting cluster nodes in 5 sec...\n"
sleep 5

echo -e "Node ceph-client is going down.\n"
ssh ceph-client 'sudo reboot'
sleep 2
echo -e "Node ceph-mgr is going down.\n"
ssh ceph-mgr 'sudo reboot'
sleep 2
echo -e "Node ceph-osd2 is going down.\n"
ssh ceph-osd2 'sudo reboot'
sleep 2
echo -e "Node ceph-osd1 is going down.\n"
ssh ceph-osd1 'sudo reboot'
sleep 2
echo -e "Node ceph-mon is going down.\n"
ssh ceph-mon 'sudo reboot'
echo -e "Node ceph-admin needs to be rebooted manually.\n"

