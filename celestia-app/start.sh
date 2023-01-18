#!/bin/bash

set -o errexit -o nounset

echo "App Version: " `${BIN_PATH} version 2>&1`
sleep 1

# Check if the chain data did not exist before
if ! [ -f "${APP_HOME_DIR}/config/genesis.json" ]; then

  # Build genesis file incl account for passed address
  coins="1000000000000000${DENOM}"
  ${BIN_PATH} init ${CHAINID} --chain-id ${CHAINID} --home ${APP_HOME_DIR}

  echo "Creating keys and configuring the validator..."

  ${BIN_PATH} keys add ${VALIDATOR_KEY} --keyring-backend="${KEYRING_BACKEND}" --home ${APP_HOME_DIR}
  # this won't work because the some proto types are decalared twice and the logs output to stdout (dependency hell involving iavl)
  ${BIN_PATH} add-genesis-account $(${BIN_PATH} keys show ${VALIDATOR_KEY} -a --keyring-backend="${KEYRING_BACKEND}" --home ${APP_HOME_DIR}) $coins --home ${APP_HOME_DIR}
  ${BIN_PATH} gentx ${VALIDATOR_KEY} 5000000000${DENOM} \
    --keyring-backend="${KEYRING_BACKEND}" \
    --chain-id ${CHAINID} \
    --home ${APP_HOME_DIR} \
    --orchestrator-address $(${BIN_PATH} keys show ${VALIDATOR_KEY} -a --keyring-backend="${KEYRING_BACKEND}" --home ${APP_HOME_DIR}) \
    --evm-address 0x966e6f22781EF6a6A82BBB4DB3df8E225DfD9488 # private key: da6ed55cb2894ac2c9c10209c09de8e8b9d109b910338d5bf3d747a7e1fc9eb9
    # --ethereum-address 0x966e6f22781EF6a6A82BBB4DB3df8E225DfD9488 # private key: da6ed55cb2894ac2c9c10209c09de8e8b9d109b910338d5bf3d747a7e1fc9eb9

  ${BIN_PATH} collect-gentxs --home ${APP_HOME_DIR}

  # Set proper defaults and change ports
  sed -i "s#\"tcp://127.0.0.1:26657\"#\"tcp://${CORE_IP}:26657\"#g" ${APP_HOME_DIR}/config/config.toml
  sed -i 's/timeout_commit = "25s"/timeout_commit = "1s"/g' ${APP_HOME_DIR}/config/config.toml
  sed -i 's/timeout_propose = "3s"/timeout_propose = "1s"/g' ${APP_HOME_DIR}/config/config.toml
  sed -i 's/index_all_keys = false/index_all_keys = true/g' ${APP_HOME_DIR}/config/config.toml
  sed -i 's/mode = "full"/mode = "validator"/g' ${APP_HOME_DIR}/config/config.toml

  # Change the grpc port
  sed -i "s#\"0.0.0.0:9090\"#\"${CORE_IP}:${CORE_GRPC_PORT}\"#g" ${APP_HOME_DIR}/config/app.toml

fi

# Handle key import from node
./keys.sh &

# Start the celestia-app
${BIN_PATH} start --home ${APP_HOME_DIR}
