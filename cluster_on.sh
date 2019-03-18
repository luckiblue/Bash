#!/bin/bash
echo -e "Powering on cluster...\n"
sleep 5
echo -e "Setting flags for clean cluster startup...\n"

ceph osd unset pause
PAUSE=$?
if [ $PAUSE -ne 0 ]; then
 echo -e "Error running \e[31mceph osd unset pause\e[0m."
 exit 0;
fi

ceph osd unset nodown
NODOWN=$?
if [ $NODOWN -ne 0 ]; then
 echo -e "Error running \e[31mceph osd unset nodown\e[0m."
 exit 0;
fi

ceph osd unset norebalance
NOREBALANCE=$?
if [ $NOREBALANCE -ne 0 ]; then
 echo -e "Error running \e[31mceph osd unset norebalance\e[0m."
 exit 0;
fi

ceph osd unset norecover
NORECOVER=$?
if [ $NORECOVER -ne 0 ]; then
 echo -e "Error runnning \e[31mceph osd unset norecover\e[0m."
 exit 0;
fi

ceph osd unset nobackfill
NOBACKFILL=$?
if [ $NOBACKFILL -ne 0 ]; then
 echo -e "Error running \e[31mceph osd unset nobackfill\e[0m."
 exit 0;
fi

ceph osd unset noout
NOOUT=$?
if [ $NOOUT -ne 0 ]; then
 echo -e "Error running \e[31mceph osd unset noout\e[0m."
 exit 0;
fi

CLUSTER_STATUS=`ceph health`
if [ "$CLUSTER_STATUS" == "HEALTH_OK" ]; then
 echo -e "Cluster started and HEALTH_OK."
else
 echo "$CLUSTER_STATUS"
fi
