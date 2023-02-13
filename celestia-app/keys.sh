#!/bin/bash
# This script imports the node key and fund it

while true; do

    echo "Checking if node generates & exports its key..."
    while true; do

        NODE_EXPORTED_KEY_FILE_PATH=""
        for FILEPATH in ${APP_HOME_DIR}/*${NODE_EXPORTED_KEY_FILE_POSTFIX}; do 
            if [ -f ${FILEPATH} ]; then
                NODE_EXPORTED_KEY_FILE_PATH=${FILEPATH}
                echo " done"
                break
            fi
        done

        if [[ "${NODE_EXPORTED_KEY_FILE_PATH}" != "" ]]; then
            echo "found an exported key:" ${NODE_EXPORTED_KEY_FILE_PATH}
            break
        fi
        sleep 1
    done

    # Extract the node key out of the file path
    NODE_KEY="${NODE_EXPORTED_KEY_FILE_PATH/$APP_HOME_DIR/}"
    NODE_KEY="${NODE_KEY/\//}"
    NODE_KEY="${NODE_KEY/$NODE_EXPORTED_KEY_FILE_POSTFIX/}"

    OUT=$(${BIN_PATH} keys show ${NODE_KEY} --home ${APP_HOME_DIR} --keyring-backend="${KEYRING_BACKEND}" 2> /dev/null)
    if [[ "$OUT" != "" ]]; then
        echo "Removing the existing key"
        echo "12345678" | ${BIN_PATH} keys delete ${NODE_KEY} --home ${APP_HOME_DIR} --keyring-backend="${KEYRING_BACKEND}" --yes
    fi

    echo "Waiting for the core/app..."
    while true; do

        ${BIN_PATH} status --node http://${CORE_IP}:${CORE_RPC_PORT} &>/dev/null
        if (( $? == 0 )); then
            echo " done"
            break
        fi
        printf "."
        sleep 1

    done

    echo "12345678" | ${BIN_PATH} keys import ${NODE_KEY} "${NODE_EXPORTED_KEY_FILE_PATH}" --home ${APP_HOME_DIR} --keyring-backend="${KEYRING_BACKEND}"

    ${BIN_PATH} tx bank send \
    $(${BIN_PATH} keys show ${VALIDATOR_KEY} -a --keyring-backend="${KEYRING_BACKEND}" --home ${APP_HOME_DIR}) \
    $(${BIN_PATH} keys show ${NODE_KEY} -a --keyring-backend="${KEYRING_BACKEND}" --home ${APP_HOME_DIR}) \
    ${FUND_AMOUNT} --chain-id ${CHAINID} --home ${APP_HOME_DIR} --keyring-backend "${KEYRING_BACKEND}" --yes \
    --broadcast-mode block --node http://${CORE_IP}:${CORE_RPC_PORT} --fees "500utia"

    ${BIN_PATH} query bank balances $(${BIN_PATH} keys show ${NODE_KEY} -a --home ${APP_HOME_DIR} --keyring-backend="${KEYRING_BACKEND}") --home ${APP_HOME_DIR} --node http://${CORE_IP}:${CORE_RPC_PORT}

    # We use this file as a mutex so let's release the lock for node to start
    rm -rf "${NODE_EXPORTED_KEY_FILE_PATH}"
    sleep 1
done
