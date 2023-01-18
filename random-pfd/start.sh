#!/bin/bash

# set -o errexit -o nounset

#------------------------#

function rand_nid {
  echo $RANDOM | md5sum | head -c 16; echo;
}

#------------------------#

function rand_msg {
  
  MSG_LEN=$(($RANDOM%10+1))

  for (( i=0; i<MSG_LEN; i++)); 
  do   
    echo $RANDOM | sha256sum | head -c 64
  done
  
}

#------------------------#

function submit_pfd {

  NID=$(rand_nid)
  DATA=$(rand_msg)
  TX=$(curl -s -X POST -d "{\"namespace_id\": \"${NID}\", \"data\": \"${DATA}\", \"gas_limit\": 90000, \"fee\": 2000}" ${NODE_REST_URL}/submit_pfd)

  HEIGHT=$(echo ${TX} | jq ".height")
  if (( $? != 0)); then
    echo ${TX}
    exit 1
  fi
  TXHASH=$(echo ${TX} | jq ".txhash" | tr -d \")

  echo -e "${HEIGHT} ${TXHASH}"

}

#------------------------#

echo "Waiting for the node to start..."
while true; do

    curl "${NODE_REST_URL}" &>/dev/null
    if (( $? == 0 )); then
        echo " done"
        break
    fi
    printf "."
    sleep 1

done


while true;
do

  PFD_TX_NUM=$(($RANDOM%20+1))
  echo -e "Submiting ${PFD_TX_NUM} PFDs...\n"

  for (( i=0; i<PFD_TX_NUM; i++)); 
  do   
    RES=$(submit_pfd)
    if (( $? != 0)); then
      echo ${RES}
      exit 2
    fi
    echo -e "\t${RES}"
  done

  SLEEP_TIME=$(($RANDOM%5+1))
  echo -e "\nWaiting ${SLEEP_TIME} seconds..."
  sleep ${SLEEP_TIME}

done


#------------------------#