#!/bin/bash

# set -o errexit -o nounset

${BIN_PATH} version
sleep 1

NODE_EXPORTED_KEY_FILE_PATH="${APP_HOME_DIR}/${NODE_KEY}${NODE_EXPORTED_KEY_FILE_POSTFIX}"

echo "Waiting for the first block..."
while true; do

    GENESIS_HASH=$(curl http://${CORE_IP}:${CORE_RPC_PORT}/block?height=1 | jq .result.block_id.hash | xargs)
    if [[ "${GENESIS_HASH}" != "" ]] && [[ "${GENESIS_HASH}" != "null" ]]; then
        export CELESTIA_CUSTOM=${CHAINID}:${GENESIS_HASH}
        echo " done"
        break
    fi
    printf "."
    sleep 1
done

ADDR=$(${BIN_CELKEY_PATH} show ${NODE_KEY} --node.type ${NODE_TYPE} --p2p.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}" -a)
ERR=$?
if [[ "${ADDR}" == "" ]] || [[ ${ERR} != 0 ]]; then

    # ${BIN_CELKEY_PATH} delete ${NODE_KEY} --node.type ${NODE_TYPE} --p2p.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}" --yes
    ${BIN_CELKEY_PATH} add ${NODE_KEY} --node.type ${NODE_TYPE} --p2p.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}"
    ${BIN_CELKEY_PATH} list --node.type ${NODE_TYPE} --p2p.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}"

    EXPORTED_KEY=$(echo "12345678" | ${BIN_CELKEY_PATH} export ${NODE_KEY}  --p2p.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}" --node.type ${NODE_TYPE} 2>&1)
    echo "${EXPORTED_KEY}" > ${NODE_EXPORTED_KEY_FILE_PATH}

    # Wait for the key to be imported by the core/app and get funded
    echo "Waiting for the core/app to handle the exported key..."
    while true; do

        if ! [[ -f ${NODE_EXPORTED_KEY_FILE_PATH} ]]; then
            echo " done"
            break
        fi
        printf "."
        sleep 1
    done

    ${BIN_PATH} ${NODE_TYPE} init --core.ip ${CORE_IP} --core.rpc.port ${CORE_RPC_PORT} --keyring.accname ${NODE_KEY} --p2p.network ${CHAINID}
fi

${BIN_PATH} ${NODE_TYPE} start --core.ip ${CORE_IP} --core.grpc.port ${CORE_GRPC_PORT} \
--gateway --gateway.addr ${NODE_REST_HOST} --gateway.port ${NODE_REST_PORT} --p2p.network ${CHAINID} \
--metrics.tls=false --metrics --metrics.endpoint ${METRICS_ENDPOINT} --keyring.accname ${NODE_KEY}

# ./celestia light start --gateway --gateway.addr celestia-light --gateway.port 26659 --p2p.network arabica --metrics.tls=false --metrics --metrics.endpoint otel-collector:4318 


GENESIS_HASH=$(curl http://localhost:26657/block?height=1 | jq .result.block_id.hash | xargs)
export CELESTIA_CUSTOM=private:${GENESIS_HASH}
./build/celestia bridge init --p2p.network private --metrics.tls=false --metrics --metrics.endpoint localhost:4318 --core.ip localhost --core.grpc.port 9092
./build/celestia bridge start --p2p.network private --metrics.tls=false --metrics --metrics.endpoint localhost:4318 --core.ip localhost --core.grpc.port 9092

./build/celestia bridge init --p2p.network arabica --metrics.tls=false --metrics --metrics.endpoint localhost:4318 --core.ip https://kaarina.celestia-devops.dev --core.grpc.port 9090
./build/celestia bridge start --p2p.network arabica --metrics.tls=false --metrics --metrics.endpoint localhost:4318 --core.ip https://kaarina.celestia-devops.dev --core.grpc.port 9090

./build/celestia light init --p2p.network arabica --metrics.tls=false --metrics --metrics.endpoint localhost:4318 --core.ip https://grpc.limani.celestia-devops.dev --core.grpc.port 9090
./build/celestia light start --p2p.network arabica --metrics.tls=false --metrics --metrics.endpoint localhost:4318 --core.ip https://grpc.limani.celestia-devops.dev --core.grpc.port 9090