#!/bin/bash
HOST=mediamtx
API_PORT=9997
#HOST=mediamtx.cszevaco.com
#API_PORT=30997
echo "TEST new label current_yolo_version"
echo "LIMIT_CPU: $LIMIT_CPU"
echo "REQUEST_CPU: $REQUEST_CPU"

helm version
pwd
ls -la

function refresh {
    STREAM_LIST_NOYOLO=$(curl -s $HOST:$API_PORT/v2/paths/list | jq .items[].name -r  | grep -v '\-yolo$')
    echo "STREAM_LIST=${STREAM_LIST}"
    DEPLOYMENT_LIST=$(oc get deployments -n edge --no-headers -o name -l type=yolo | awk -F 'deployment.apps/' '{print $2}')
    echo "DEPLOYMENT_LIST=${DEPLOYMENT_LIST}"
}

function add_missing {
    for i in ${STREAM_LIST_NOYOLO}; do
	exist=0
	for j in ${DEPLOYMENT_LIST}; do
	    if [ "$i-yolo" == "$j" ]; then
		exist=1
		break
	    fi
	done
	if [ "$exist" == "0" ]; then
	    echo "/!\ creating $i deployment"
	    #helm install --set name=$i $i /inference-0.1.0.tgz
	    helm install --set name=$i --set limit_cpu=$LIMIT_CPU --set request_cpu=$REQUEST_CPU  $i /inference
	fi
    done
}

function prune_orphane {
    for j in ${DEPLOYMENT_LIST}; do
	exist=0
	for i in ${STREAM_LIST_NOYOLO}; do
	    if [ "$i-yolo" == "$j" ]; then
		exist=1
		break
	    fi
	done
	if [ "$exist" == "0" ]; then
	    echo "/!\ prunning $j deployment"
	    SHORT=$(echo $j | awk -F '-yolo' '{print $1}')
	    echo $SHORT
	    helm uninstall $SHORT
	fi
    done
}

while true; do refresh; add_missing; sleep 0.3; prune_orphane; sleep 0.3; done
