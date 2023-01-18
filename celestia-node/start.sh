#!/bin/bash

# set -o errexit -o nounset

${BIN_PATH} version
sleep 1

echo "Waiting for the core/app to start..."
while true; do

    curl "http://${CORE_IP}:${CORE_RPC_PORT}/status" &>/dev/null
    if (( $? == 0 )); then
        echo " done"
        break
    fi
    printf "."
    sleep 1

done

GENESIS_HASH=$(curl http://${CORE_IP}:${CORE_RPC_PORT}/block?height=1 | jq .result.block_id.hash | xargs)
export CELESTIA_CUSTOM=${CHAINID}:${GENESIS_HASH}

ADDR=$(${BIN_CELKEY_PATH} show ${NODE_KEY} --node.type ${NODE_TYPE} --p2p.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}" -a)
if [[ "${ADDR}" == "" ]]; then

    # ${BIN_CELKEY_PATH} delete ${NODE_KEY} --node.type ${NODE_TYPE} --p2p.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}" --yes
    ${BIN_CELKEY_PATH} add ${NODE_KEY} --node.type ${NODE_TYPE} --p2p.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}"
    ${BIN_CELKEY_PATH} list --node.type ${NODE_TYPE} --p2p.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}"

    EXPORTED_KEY=$(echo "12345678" | ${BIN_CELKEY_PATH} export ${NODE_KEY}  --p2p.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}" --node.type ${NODE_TYPE} 2>&1)
    echo "${EXPORTED_KEY}" > ${APP_HOME_DIR}/${NODE_EXPORTED_KEY_FILE}

    # Wait for the key to be imported by the core/app and get funded
    echo "Waiting for the core/app to handle the exported key..."
    while true; do

        if ! [[ -f ${APP_HOME_DIR}/${NODE_EXPORTED_KEY_FILE} ]]; then
            echo " done"
            break
        fi
        printf "."
        sleep 1
    done

    ${BIN_PATH} ${NODE_TYPE} init --core.ip ${CORE_IP} --core.rpc.port ${CORE_RPC_PORT} --keyring.accname ${NODE_KEY}
fi

${BIN_PATH} ${NODE_TYPE} start --core.ip ${CORE_IP} --core.grpc.port ${CORE_GRPC_PORT} \
--gateway --gateway.addr ${NODE_REST_HOST} --gateway.port ${NODE_REST_PORT} \
--metrics.tls=false --metrics --metrics.endpoint ${METRICS_ENDPOINT} --keyring.accname ${NODE_KEY}