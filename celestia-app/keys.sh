#!/bin/bash
# This script imports the node key and fund it

while true; do

    echo "Checking if node generates & exports its key..."
    while true; do

        if [[ -f "${APP_HOME_DIR}/${NODE_EXPORTED_KEY_FILE}" ]]; then
            echo " done"
            break
        fi
        sleep 1
    done

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

    echo "12345678" | ${BIN_PATH} keys import ${NODE_KEY} "${APP_HOME_DIR}/${NODE_EXPORTED_KEY_FILE}" --home ${APP_HOME_DIR} --keyring-backend="${KEYRING_BACKEND}"

    ${BIN_PATH} tx bank send \
    $(${BIN_PATH} keys show ${VALIDATOR_KEY} -a --keyring-backend="${KEYRING_BACKEND}" --home ${APP_HOME_DIR}) \
    $(${BIN_PATH} keys show ${NODE_KEY} -a --keyring-backend="${KEYRING_BACKEND}" --home ${APP_HOME_DIR}) \
    ${FUND_AMOUNT} --chain-id ${CHAINID} --home ${APP_HOME_DIR} --keyring-backend "${KEYRING_BACKEND}" --yes \
    --broadcast-mode block --node http://${CORE_IP}:${CORE_RPC_PORT} --fees "500utia"

    ${BIN_PATH} query bank balances $(${BIN_PATH} keys show ${NODE_KEY} -a --home ${APP_HOME_DIR} --keyring-backend="${KEYRING_BACKEND}") --home ${APP_HOME_DIR} --node http://${CORE_IP}:${CORE_RPC_PORT}

    # We use this file as a mutex so let's release the lock for node to start
    rm -rf "${APP_HOME_DIR}/${NODE_EXPORTED_KEY_FILE}"
    sleep 1
done
