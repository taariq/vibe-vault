### Install Cosmovisor CLI Tool

Source: https://docs.palomachain.com/guide/maintain/validator/cosmovisor

Installs the Cosmovisor command-line interface using Go. Ensure you have Go installed and configured. This command fetches the latest stable version.

```bash
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest
```

--------------------------------

### Project Setup with npm

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/getting-started

Commands to create a new project directory, initialize npm, install the Paloma.js package, and create an index.js file. It also includes modifying package.json to enable module support.

```bash
mkdir <my-Paloma-js-project>
cd <my-Paloma-js-project>
npm init -y
npm install @paloma/Paloma.js
touch index.js
```

```json
{
  // ...
  "type": "module"
  // ...
}
```

--------------------------------

### Prepare Upgrade Directory and Download New Binary

Source: https://docs.palomachain.com/guide/maintain/validator/cosmovisor

Creates a directory for a new `palomad` binary version and downloads it from a release URL. Replace `{upgrade_tag_name}` with the specific version tag.

```bash
mkdir -p ~/.paloma/cosmovisor/upgrades/{upgrade_tag_name}/bin
wget -O - https://github.com/palomachain/paloma/releases/download/{upgrade_tag_name}/paloma_Linux_x86_64.tar.gz  | \
tar -C $DAEMON_HOME/cosmovisor/upgrades/{upgrade_tag_name}/bin -xvzf - palomad
```

--------------------------------

### Copy Genesis Binary to Cosmovisor

Source: https://docs.palomachain.com/guide/maintain/validator/cosmovisor

Copies the initial `palomad` binary into the Cosmovisor genesis directory. This is the first version Cosmovisor will manage.

```bash
cp /usr/local/bin/palomad $DAEMON_HOME/cosmovisor/genesis/bin
```

--------------------------------

### Create Cosmovisor Directory Structure

Source: https://docs.palomachain.com/guide/maintain/validator/cosmovisor

Sets up the necessary directories for Cosmovisor to manage genesis and upgrade binaries. These directories organize different versions of the Paloma daemon (`palomad`).

```bash
mkdir -p ~/.paloma/cosmovisor
mkdir ~/.paloma/cosmovisor/genesis
mkdir ~/.paloma/cosmovisor/genesis/bin
mkdir ~/.paloma/cosmovisor/upgrades
```

--------------------------------

### Set Up Paloma SDK Dependencies with Poetry

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-py/getting-started

Installs Poetry and then installs all required project dependencies for the Paloma SDK. This step is necessary for development and testing.

```bash
pip install poetry
poetry install
```

--------------------------------

### Install Paloma.py SDK

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-py/getting-started

Installs the Paloma Python SDK using pip. It's recommended to do this within a virtual environment. Ensure you have Python v3.7+ installed.

```bash
pip install -U paloma_sdk
```

--------------------------------

### Example package.json Configuration

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

An example of the package.json file generated after initializing a Node.js project. It includes basic information like the project name, version, description, and main entry point.

```json
{
   "name": "hello-world",
   "version": "1.0.0",
   "description": "hello world smart contract",
   "main": "index.js",
   "scripts": {
      "test": "echo \"Error: no test specified\" && exit 1"
   },
   "author": "",
   "license": "ISC"
}
```

--------------------------------

### Initialize LCDClient - JavaScript

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/common-examples

Initializes the LCDClient for interacting with the Paloma blockchain. Requires fetching gas prices and specifying network details like URL and chainID. The `isClassic` parameter is optional and defaults to false.

```javascript
import fetch from "isomorphic-fetch";
import { MsgSend, MnemonicKey, Coins, LCDClient } from "@paloma/Paloma.js";

// Fetch gas prices and convert to `Coin` format.
const gasPrices = await (
  await fetch("", { redirect: 'follow' }) //todo: gas price api
).json();
const gasPricesCoins = new Coins(gasPrices);

const lcd = new LCDClient({
  URL: "https://lcd.testnet.palomaswap.comm",
  chainID: "<paloma chain id>", 
  gasPrices: gasPricesCoins,
  gasAdjustment: "1.5",
  gas: 10000000,
  isClassic: false, // optional parameter, false by default
});

```

--------------------------------

### Get Paloma source code

Source: https://docs.palomachain.com/guide/develop/palomad/install-palomad

Clones the Paloma repository from GitHub and checks out a specific tag. This is the first step to building Paloma from source. Replace `[tag]` with the desired release tag.

```shell
git clone https://github.com/palomachain/paloma.git
cd paloma
git checkout [tag]
```

--------------------------------

### Verify Vyper Installation

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-vyper

This command verifies that the Vyper compiler has been successfully installed. It displays the installed Vyper version, confirming that the installation process was completed without errors.

```bash
vyper --version
```

--------------------------------

### Verify New Binary Version

Source: https://docs.palomachain.com/guide/maintain/validator/cosmovisor

Navigates to the upgrade directory and checks the version of the newly installed `palomad` binary. This confirms the upgrade binary is correctly placed and executable.

```bash
cd ~/.paloma/cosmovisor/upgrades/{upgrade_tag_name}/bin
./palomad version
```

--------------------------------

### Install Fetch Library with npm

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/getting-started

Installs the 'isomorphic-fetch' package, which is used for making HTTP requests to dynamically fetch recommended gas prices for blockchain transactions.

```bash
npm install --save isomorphic-fetch
```

--------------------------------

### Send Native Tokens - JavaScript

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/common-examples

Demonstrates how to send native Paloma tokens from one wallet to another. This involves creating a `MnemonicKey`, initializing a `wallet` with the LCDClient, constructing a `MsgSend` object, and broadcasting the transaction.

```javascript
import { LCDClient, MnemonicKey, MsgSend } from "@paloma/Paloma.js";

// const lcd = new LCDClient(...);

const mk = new MnemonicKey({
  mnemonic:
    "satisfy adjust timber high purchase tuition stool faith fine install that you unaware feed domain license impose boss human eager hat rent enjoy dawn",
});

const wallet = lcd.wallet(mk);

// Transfer 1 GRAIN.
const send = new MsgSend(
  wallet.key.accAddress,
  "paloma1dcegyrekltswvyy0xy69ydgxn9x8x32zdtapd8",
  { ugrain: "1000000" }
);

const tx = await wallet.createAndSignTx({ msgs: [send] });
const result = await lcd.tx.broadcast(tx);

console.log(result);

```

--------------------------------

### Install Hardhat Development Environment

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

Installs the Hardhat development environment, which is used to compile, deploy, test, and debug Ethereum software. It's a crucial tool for local smart contract and dApp development before live deployment.

```bash
npm install --save-dev hardhat
```

--------------------------------

### Install Ethers.js and Hardhat-Ethers plugin

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

Installs the ethers.js library and the hardhat-ethers plugin. Ethers.js simplifies interaction with the Ethereum blockchain, while the plugin integrates it with Hardhat for contract deployment and management.

```bash
npm install --save-dev @nomiclabs/hardhat-ethers "ethers@^5.0.0"
```

--------------------------------

### Install Vyper Package

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-vyper

This command installs the Vyper compiler using Python's PIP package manager. It fetches and installs the latest stable version of Vyper, enabling you to compile Vyper smart contracts.

```bash
pip install vyper
```

--------------------------------

### Install palomad from binary (Mainnet)

Source: https://docs.palomachain.com/guide/develop/palomad/install-palomad

Installs the palomad binary from a pre-built release for Linux. It downloads the specified version (v2.4.13) for mainnet, extracts it to /usr/local/bin, and makes it executable. It also installs the necessary libwasmvm.

```shell
wget -O - https://github.com/palomachain/paloma/releases/download/v2.4.13/paloma_Linux_x86_64.tar.gz  | \
sudo tar -C /usr/local/bin -xvzf - palomad
sudo chmod +x /usr/local/bin/palomad

wget https://github.com/CosmWasm/wasmvm/releases/download/v2.1.3/libwasmvm.x86_64.so/libwasmvm.x86_64.so
```

--------------------------------

### Get Wallet Balance (Native Tokens) - JavaScript

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/common-examples

Retrieves the native token balance for a given Paloma address. It uses the initialized LCDClient to query the bank module. The result is an array of Coins, typically showing the primary native token.

```javascript
// Replace with address to check.
const address = "paloma1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
const [balance] = await lcd.bank.balance(address);
console.log(balance.toData());

```

--------------------------------

### Initialize Hardhat Project

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

Initializes a new Hardhat project within an existing directory. This command prompts the user to select project setup options, such as creating an empty configuration file.

```bash
npx hardhat
```

--------------------------------

### Install dotenv package

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

Installs the dotenv package, which allows you to load environment variables from a .env file into process.env. This is crucial for securely storing sensitive information like API keys and private keys.

```bash
npm install dotenv --save
```

--------------------------------

### Generate Wallet Address Link - JavaScript

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/common-examples

Generates a URL to view a wallet address on the Paloma block explorer. It accepts a Paloma address and formats it into an explorer link, facilitating easy access to address details.

```javascript
const getWalletLink = (address) =>
  `https://paloma.explorers.guru/account/${address}`;
const address = "paloma1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
console.log(getWalletLink(address));

```

--------------------------------

### Get Transaction Status - JavaScript

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/common-examples

Fetches detailed information about a specific transaction using its hash. This function queries the transaction module of the LCDClient and returns a `TxInfo` object containing details like height, gas used, and logs.

```javascript
// Replace with TX hash to lookup.
const hash = "CAB264B3D92FF3DFE209DADE791A866876DE5DD2A320C1200F9C5EC5F0E7B14B";
const txInfo = await lcd.tx.txInfo(hash);
console.log(txInfo);

```

--------------------------------

### Run Paloma.py Tests

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-py/getting-started

Executes the comprehensive test suite for the Paloma.py SDK. This command should be run after installing the project dependencies.

```bash
make test
```

--------------------------------

### Generate Transaction Link - JavaScript

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/common-examples

Creates a direct URL to view a transaction on the Paloma block explorer. It takes a transaction hash as input and constructs the explorer URL. This is useful for sharing transaction details.

```javascript
const getTransactionLink = (hash) =>
  `https://paloma.explorers.guru/transaction/tx/${hash}`;
const hash = "CAB264B3D92FF3DFE209DADE791A866876DE5DD2A320C1200F9C5EC5F0E7B14B";

console.log(getTransactionLink(hash));

```

--------------------------------

### Install palomad from binary (Testnet)

Source: https://docs.palomachain.com/guide/develop/palomad/install-palomad

Installs the palomad binary from a pre-built release for Linux on the testnet. It downloads version v2.4.11, extracts it to /usr/local/bin, and makes it executable. It also installs libwasmvm to the correct directory.

```shell
wget -O - https://github.com/palomachain/paloma/releases/download/v2.4.11/paloma_Linux_x86_64.tar.gz  | \
sudo tar -C /usr/local/bin -xvzf - palomad
sudo chmod +x /usr/local/bin/palomad

sudo wget -P /usr/lib https://github.com/CosmWasm/wasmvm/releases/download/v1.5.2/libwasmvm.x86_64.so
```

--------------------------------

### Build Paloma CLI with Ledger Support

Source: https://docs.palomachain.com/guide/resources/paloma-ledger

This command builds the `palomad` binary with Ledger support enabled and installs it to the system's PATH. It requires Go and Git to be installed. The `LEDGER_ENABLED=true` environment variable is crucial for enabling Ledger functionality during the build process.

```bash
LEDGER_ENABLED=true make build
sudo mv ./build/palomad /usr/local/bin/palomad
```

--------------------------------

### Start Paloma Testnet with Docker Compose

Source: https://docs.palomachain.com/guide/develop/smart-contracts/interact-with-smart-contract

This command starts the Paloma testnet environment using Docker Compose. Ensure you have TestNest-6 set up and running before executing this command. It creates the necessary containers and network for the testnet.

```bash
cd testnet
docker-compose up
```

--------------------------------

### Format and Check Paloma.py Code Quality

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-py/getting-started

Applies code formatting and quality checks to the Paloma SDK codebase using Black, isort, and Mypy. Run this after installing dependencies.

```bash
make qa && make format
```

--------------------------------

### Decode Protobuf-Encoded Messages - JavaScript

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/common-examples

Shows how to decode transaction messages that have been encoded using Protobuf. It fetches block data, unpacks transaction data from base64, and then searches for specific message types like `MsgInstantiateContract` within the transaction body.

```javascript
import { LCDClient, Tx } from "@paloma/Paloma.js";

// const lcd = new LCDClient(...);

const blockData = await lcd.tendermint.blockInfo(5923213);

const txInfos = blockData.block.data.txs.map((tx) =>
  Tx.unpackAny({ value: Buffer.from(tx, "base64") })
);

// Find messages where a contract was initialized.
const initMessages = txInfos
  .map((tx) => tx.body.messages)
  .flat()
  .find((i) => i.constructor.name === "MsgInstantiateContract");

console.log(initMessages);

```

--------------------------------

### Configure Cosmovisor Environment Variables

Source: https://docs.palomachain.com/guide/maintain/validator/cosmovisor

Sets essential environment variables for Cosmovisor to identify the daemon name, home directory, and upgrade behavior. These variables are typically added to the user's profile.

```bash
cat <<EOT >> ~/.profile

# Setup Cosmovisor
export DAEMON_NAME=palomad
export DAEMON_HOME=$HOME/.paloma
export DAEMON_ALLOW_DOWNLOAD_BINARIES=false
export DAEMON_LOG_BUFFER_SIZE=512
export DAEMON_RESTART_AFTER_UPGRADE=true
export UNSAFE_SKIP_BACKUP=true
EOT

source ~/.profile
```

--------------------------------

### Update Systemd Service for Cosmovisor

Source: https://docs.palomachain.com/guide/maintain/validator/cosmovisor

Configures the systemd service file to use Cosmovisor for running the `palomad` daemon. This ensures Cosmovisor manages the daemon process and its upgrades.

```ini
[Unit]
Description=Paloma (Cosmovisor)
After=network-online.target

[Service]
LimitNOFILE=4096
Restart=always
RestartSec=5
WorkingDirectory=~
ExecStartPre=
ExecStart=/usr/local/go/bin/cosmovisor run start
Environment=PIGEON_HEALTHCHECK_PORT=5757
ExecReload=

[Install]
WantedBy=multi-user.target
```

--------------------------------

### Verify palomad installation

Source: https://docs.palomachain.com/guide/develop/palomad/install-palomad

Verifies the installation of the palomad executable by running the `palomad version --long` command. This command displays detailed version information, including the name, server name, version number, commit hash, build tags, and Go version.

```shell
palomad version --long
```

--------------------------------

### Build palomad from source

Source: https://docs.palomachain.com/guide/develop/palomad/install-palomad

Builds the Paloma project from source code using the `make build` command and then moves the compiled `palomad` executable to the system's binary path (/usr/local/bin).

```shell
make build
sudo mv ./build/palomad /usr/local/bin/palomad
```

--------------------------------

### Get palomad Query Command Documentation

Source: https://docs.palomachain.com/guide/resources/paloma-ledger

Display documentation for the `query` commands within `palomad`. This helps in understanding how to retrieve data from the network.

```bash
palomad query --help
```

--------------------------------

### Instantiate, Transfer, and Burn CW20 Tokens using Paloma.py

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-py/cw20

This Python example demonstrates how to use the Paloma.py SDK to interact with CW20 tokens. It covers storing CW20 compatible WASM code, instantiating a new CW20 token, transferring tokens to another address, and burning tokens. The example requires specific mnemonic phrases for wallet creation and assumes a local or testnet environment for Paloma.

```python
import asyncio
from pathlib import Path

import uvloop
from terra_proto.cosmwasm.wasm.v1 import AccessType
from paloma_sdk.client.lcd import AsyncLCDClient
from paloma_sdk.client.lcd.api.tx import CreateTxOptions
from paloma_sdk.core.wasm import MsgStoreCode
from paloma_sdk.key.mnemonic import MnemonicKey
from paloma_sdk.core.wasm.data import AccessConfig
from paloma_sdk.util.contract import get_code_id, read_file_as_b64


async def main():
    paloma = AsyncLCDClient(url="https://lcd.testnet.palomaswap.com/", chain_id="paloma-testnet-13")
    paloma.gas_prices = "0.01ugrain"

    acc = MnemonicKey(
        mnemonic="notice oak worry limit wrap speak medal online prefer cluster roof addict wrist behave treat actual wasp year salad speed social layer crew genius"
    )

    acc2 = MnemonicKey(
        mnemonic="index light average senior silent limit usual local involve delay update rack cause inmate wall render magnet common feature laundry exact casual resource hundred"
    )
    test1 = paloma.wallet(acc)
    test2 = paloma.wallet(acc2)

    store_code_tx = await test1.create_and_sign_tx(
        CreateTxOptions(
            msgs=[
                MsgStoreCode(
                    test1.key.acc_address,
                    read_file_as_b64(Path(__file__).parent / "./cw20_base.wasm"),
                    AccessConfig(AccessType.ACCESS_TYPE_EVERYBODY, ""),
                )
            ]
        )
    )
    store_code_tx_result = await paloma.tx.broadcast(store_code_tx)
    print(store_code_tx_result)

    code_id = get_code_id(store_code_tx_result)

    print(f"code_id:{code_id}")

    result = await paloma.cw20.instantiate(
        test1, code_id, "CW20 Token", "CWFT", 9, 1_000_000_000_000_000
    )
    print(result)
    
    contract_address = result.logs[0].events_by_type["instantiate"
```

--------------------------------

### Increase Max Open Files for palomad (Linux Config)

Source: https://docs.palomachain.com/guide/maintain/node/set-up-production

This snippet demonstrates how to increase the maximum number of files that the `palomad` process can open by modifying the `/etc/security/limits.conf` file on a Linux system. This is a recommended setting for production environments to prevent resource exhaustion. Ensure you have superuser privileges to modify this file.

```bash
# If you have never changed this system config or your system is fresh, most of this file will be commented
# ...
*                soft    nofile          65535   # Uncomment the following two lines at the bottom
*                hard    nofile          65535   # Change the default values to ~65535
# ...


```

--------------------------------

### Query Result Example

Source: https://docs.palomachain.com/guide/develop/smart-contracts/interact-with-smart-contract

This is an example of the expected output when querying the count from the smart contract after performing reset and increment operations.

```plaintext
query_result:
  count: 7
```

--------------------------------

### Basic Paloma Address Validation (JavaScript)

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/common-examples

Performs a basic validation of a Paloma address using a regular expression. It checks if the address starts with 'paloma1', has a length of 44 characters, and contains only numbers and lowercase letters. This method does not verify the checksum and may yield false positives.

```javascript
// basic address validation (no library required)
function isValid(address) {
  // check the string format:
  // - starts with "paloma1"
  // - length == 44 ("paloma1" + 38)
  // - contains only numbers and lower case letters
  return /(paloma1[a-z0-9]{38})/g.test(address);
}

console.log(isValid("paloma1dcegyrekltswvyy0xy69ydgxn9x8x32zdtapd8")); // true
console.log(isValid("paloma1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")); // true (even if this doesn't have a valid checksum)
console.log(isValid("cosmos1zz22dfpvw3zqpeyhvhmx944a588fgcalw744ts")); // false
console.log(isValid("random string")); // false

```

--------------------------------

### Write Smart Contract Deployment Script

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

Creates a JavaScript file (deploy.js) to deploy a smart contract. It uses ethers.js and Hardhat's Ethers plugin to get a ContractFactory, deploy the contract, and log the deployed contract's address.

```javascript
async function main() {
   const HelloWorld = await ethers.getContractFactory("HelloWorld");

   // Start deployment, returning a promise that resolves to a contract object
   const hello_world = await HelloWorld.deploy("Hello World!");   
   console.log("Contract deployed to address:", hello_world.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
```

--------------------------------

### Install libwasm for palomad

Source: https://docs.palomachain.com/guide/develop/palomad/install-palomad

Installs the required libwasm version (2.1.3) for palomad. It downloads the binary, moves it to the system's library path, and clears the wasm cache. This is a prerequisite for running palomad.

```shell
wget https://github.com/CosmWasm/wasmvm/releases/download/v1.5.2/libwasmvm.x86_64.so
sudo mv libwasmvm.x86_64.so /usr/lib/

rm -r ~/.paloma/data/wasm/cache
```

--------------------------------

### Run Hardhat Deployment Script

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

This command executes the Hardhat deployment script located at 'scripts/deploy.js' on the 'goerli' network. Ensure Hardhat is installed and configured for the Goerli network. The output will include the deployed contract address.

```bash
npx hardhat run scripts/deploy.js --network goerli
```

--------------------------------

### Example: Sign Unsigned Transaction

Source: https://docs.palomachain.com/guide/develop/palomad/using-palomad

A concrete example of signing an unsigned transaction using specific testnet details. This command takes the chain ID and the sender's address to sign the provided unsigned transaction file.

```bash
palomad tx sign \
    --chain-id=paloma-testnet-10 \
    --from=paloma1EXAMPLEy09tEXAMPLEtf9EXAMPLE3h0EXAMPLEss unsignedTx.json
```

--------------------------------

### Get palomad Top-Level Command Documentation

Source: https://docs.palomachain.com/guide/resources/paloma-ledger

Display documentation for the top-level `palomad` commands, such as `status`, `config`, `query`, and `tx`. This provides an overview of available functionalities.

```bash
palomad --help
```

--------------------------------

### Compile Vyper Contract

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-vyper

Commands to compile a Vyper smart contract. The first command compiles the contract into bytecode, and the second extracts the ABI. Ensure the Vyper compiler is installed and accessible in your PATH.

```bash
vyper contract.vy
vyper -f abi contract.v
```

--------------------------------

### Get palomad Transaction Command Documentation

Source: https://docs.palomachain.com/guide/resources/paloma-ledger

Display documentation for the `tx` (transaction) commands within `palomad`. This is useful for understanding how to construct and send transactions.

```bash
palomad tx --help
```

--------------------------------

### Solidity 'HelloWorld' Smart Contract

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

A basic smart contract written in Solidity. It initializes a message, allows it to be updated, and emits an event when the message changes. This contract serves as a foundational example for smart contract development.

```solidity
// SPDX-License-Identifier: None

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.8.9;

// Defines a contract named `HelloWorld`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract HelloWorld {

   //Emitted when update function is called
   //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
   event UpdatedMessages(string oldStr, string newStr);

   // Declares a state variable `message` of type `string`.
   // State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
   string public message;

   // Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
   // Constructors are used to initialize the contract's data. Learn more:https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
   constructor(string memory initMessage) {

      // Accepts a string argument `initMessage` and sets the value into the contract's `message` storage variable).
      message = initMessage;
   }

   // A public function that accepts a string argument and updates the `message` storage variable.
   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}
```

--------------------------------

### Configure React Native for Paloma.js

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/getting-started

Installs necessary packages ('node-libs-react-native', 'react-native-get-random-values') and configures the project's entry point and metro.config.js to enable Paloma.js functionality within a React Native environment.

```javascript
import 'node-libs-react-native/globals'; import 'react-native-get-random-values';
```

```javascript
module.exports = {
  // ...
  resolver: {
    // ...
    extraNodeModules: require('node-libs-react-native'),
  },
  // ...
}
```

--------------------------------

### Configure PATH for Go binaries

Source: https://docs.palomachain.com/guide/develop/palomad/install-palomad

Sets the PATH environment variable to include the Go binary directory. This is a troubleshooting step to resolve the 'palomad: command not found' error by ensuring the Go binaries are accessible.

```shell
export PATH=$PATH:$(go env GOPATH)/bin
```

--------------------------------

### Basic Vyper Smart Contract

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-vyper

This is a simple 'Hello World' smart contract written in Vyper. It defines a basic contract structure that can be deployed on the Ethereum blockchain. This serves as a starting point for more complex contract development.

```vyper
# contract.vy

# This is a basic Vyper contract example

# You can define state variables here
# Example: message: public(String[100])

# And functions
# Example: @external
def set_message(_message: String[100]):
    self.message = _message

@external
@view
def get_message() -> String[100]:
    return self.message

```

--------------------------------

### Check Python Version

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-vyper

This command checks if Python version 3.6 or higher is installed on your system. Vyper requires Python 3.6+ to function correctly. Ensure this prerequisite is met before installing Vyper.

```bash
python --version
```

--------------------------------

### GET /greeting/hello/{accAddress}

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/add-modules

Fetches a greeting for a given account address.

```APIDOC
## GET /greeting/hello/{accAddress}

### Description
Retrieves a greeting associated with the provided account address.

### Method
GET

### Endpoint
/greeting/hello/{accAddress}

### Parameters
#### Path Parameters
- **accAddress** (string) - Required - The account address for which to fetch the greeting.

### Response
#### Success Response (200)
- **result** (array of strings) - A list of greetings for the account address.

#### Response Example
{
  "result": [
    "0x123...",
    "0x456..."
  ]
}
```

--------------------------------

### Advanced Paloma Address Validation with Bech32 (JavaScript)

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/common-examples

Validates a Paloma address by decoding it using the 'bech32' library, which verifies the checksum. It also checks if the decoded address prefix matches 'Paloma'. This method ensures a more accurate validation by checking the address integrity.

```javascript
import { bech32 } from "bech32";

// advanced address validation, it verify also the bech32 checksum
function isValid(address) {
  try {
    const { prefix: decodedPrefix } = bech32.decode(address); // throw error if checksum is invalid
    // verify address prefix
    return decodedPrefix === "Paloma";
  } catch {
    // invalid checksum
    return false;
  }
}

console.log(isValid("paloma1dcegyrekltswvyy0xy69ydgxn9x8x32zdtapd8")); // true
console.log(isValid("paloma1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")); // false
console.log(isValid("cosmos1zz22dfpvw3zqpeyhvhmx944a588fgcalw744ts")); // false
console.log(isValid("random string")); // false

```

--------------------------------

### Create Project Directory and Navigate

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

This snippet shows the basic shell commands to create a new directory for the project and navigate into it. This is a foundational step for any new project.

```bash
mkdir hello-world
cd hello-world
```

--------------------------------

### Eth_getBalance JSON-RPC Request Example

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

This JSON-RPC request is used to query the balance of an Ethereum account. It's a common method for checking the amount of Ether an address holds on the network. The result is typically returned in Wei.

```json
{ "jsonrpc": "2.0", "id": 0, "result": "0xde0b6b3a7640000" }
```

--------------------------------

### Bank Module Genesis Parameters Setup - Python

Source: https://docs.palomachain.com/guide/develop/module-specifications/spec-bank

Demonstrates how to set up the genesis parameters for the Paloma bank module using Python. This includes initializing the total supply of the native token (GRAIN) and defining its metadata, such as display units and aliases. This configuration is crucial for the initial state of the blockchain.

```python
# Bank: setup supply
gensis['app_state']['bank']['supply'] = [{
    'denom': DENOM_GRAIN,
    'amount': str(TOTAL_ALLOCATION),
}]

# Bank: set denom meta
gensis['app_state']['bank']['denom_metadata'] = [{
    'description': 'The native staking token of Paloma 2.0',
    'denom_units': [
        {'denom': 'ugrain', 'exponent': 0, 'aliases': ['micrograin']},
        {'denom': 'mgrain', 'exponent': 3, 'aliases': ['milligrain']},
        {'denom': 'grain', 'exponent': 6, 'aliases': []},
    ],
    'base':    'ugrain',
    'display': 'grain',
    'name':    'GRAIN',
    'symbol':  'GRAIN',
}]

```

--------------------------------

### Get Contract Factory with Ethers.js

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

Demonstrates how to obtain a ContractFactory instance using ethers.js. This factory is an abstraction used to deploy new smart contract instances. When using the hardhat-ethers plugin, ContractFactory instances are connected to the first signer by default.

```javascript
const HelloWorld = await ethers.getContractFactory("HelloWorld");
```

--------------------------------

### Recreate Genesis Version with Paloma CLI Commands

Source: https://docs.palomachain.com/guide/maintain/node/troubleshoot

These commands are used to recreate a genesis version after deleting the existing `~/.paloma/config/genesis.json` file. It involves adding genesis accounts, creating a genesis transaction, and collecting gentxs. Replace `<account-name>` and `<network-name>` with your specific values.

```bash
palomad add-genesis-account $(palomad keys show <account-name> -a) 100000000ugrain,1000usd
palomad gentx <account-name> 10000000ugrain --chain-id=<network-name> 
palomad collect-gentxs
```

--------------------------------

### GET /greeting/parameters

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/add-modules

Retrieves the current parameters for the greeting module.

```APIDOC
## GET /greeting/parameters

### Description
Fetches the configuration parameters for the greeting module.

### Method
GET

### Endpoint
/greeting/parameters

### Response
#### Success Response (200)
- **result** (object) - An object containing the module parameters.
  - **max_hellos** (number) - The maximum number of greetings allowed.
  - **max_goodbyes** (number) - The maximum number of goodbyes allowed.

#### Response Example
{
  "result": {
    "max_hellos": "10",
    "max_goodbyes": "5"
  }
}
```

--------------------------------

### Initialize Node.js Project

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

Initializes a new Node.js project using npm. This command sets up the basic project structure and creates a package.json file to manage dependencies and project metadata.

```bash
npm init # (or npm init --yes)
```

--------------------------------

### Instantiate Smart Contract with Paloma.js

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-js/smart-contracts

Creates a new instance of a smart contract using an uploaded code ID and an initialization message (InitMsg). Requires the 'code_id' from a previous store code transaction. Outputs transaction results and the new contract address.

```typescript
import { MsgInstantiateContract } from '@paloma/Paloma.js';


const instantiate = new MsgInstantiateContract(
  wallet.key.accAddress,
  +code_id[0], // code ID
  {
    count: 0,
  }, // InitMsg
  { ugrain: 10000000}, // init coins
  false // migratable
);

const instantiateTx = await wallet.createAndSignTx({
  msgs: [instantiate],
});
const instantiateTxResult = await Paloma.tx.broadcast(instantiateTx);

console.log(instantiateTxResult);

if (isTxError(instantiateTxResult)) {
  throw new Error(
    `instantiate failed. code: ${instantiateTxResult.code}, codespace: ${instantiateTxResult.codespace}, raw_log: ${instantiateTxResult.raw_log}`
  );
}

const { 
  instantiate_contract: { contract_address }, 
} = instantiateTxResult.logs[0].eventsByType;
```

--------------------------------

### Submit Proposal CLI Command Example

Source: https://docs.palomachain.com/guide/develop/module-specifications/spec-feegrant

Demonstrates how to submit a governance proposal using the Paloma CLI, including specifying a fee account for transaction fees. This command is useful for interacting with the governance module and managing transaction costs.

```bash
./palomad tx gov submit-proposal --title="Test Proposal" --description="My awesome proposal" --type="Text" --from validator-key --fee-account=paloma1fmcjjt6yc9wqup2r06urnrd928jhrde6gcld6n --chain-id=paloma-testnet-10 --fees="10uGRAIN"
```

--------------------------------

### Genesis Parameters Configuration (Python)

Source: https://docs.palomachain.com/guide/develop/module-specifications/spec-governance

Example configuration for the Governance module's genesis parameters using Python. This snippet demonstrates how to set the minimum deposit, maximum deposit period, tally parameters (quorum, threshold, veto threshold), and voting period.

```python
# Gov: change min deposit to 512 GRAIN and deposit period to 7 days
genesis['app_state']['gov']['deposit_params'] = {
    'max_deposit_period': '604800s',  # 7days
    'min_deposit': [
        {
            'denom': DENOM_GRAIN,
            'amount': '512000000'
        }
    ],
}

# Gov: set tally params quorum to 10%
genesis['app_state']['gov']['tally_params'] = {
    'quorum': '0.100000000000000000',
    'threshold': '0.500000000000000000',
    'veto_threshold': '0.334000000000000000'
}

# Gov: set voting period to 7 days
genesis['app_state']['gov']['voting_params'] = {
    'voting_period': '604800s'
}
```

--------------------------------

### Create Project Directories

Source: https://docs.palomachain.com/guide/develop/smart-contracts/hello-world-solidity

Creates essential directories for organizing smart contract code and deployment scripts. The 'contracts' directory holds .sol files, and the 'scripts' directory contains JavaScript or TypeScript files for deployment and interaction.

```bash
mkdir contracts
mkdir scripts
```

--------------------------------

### Get Validator Info

Source: https://docs.palomachain.com/guide/develop/palomad/subcommands-q

Queries detailed information for a specific validator.

```APIDOC
## GET /valset/validator-info

### Description
Queries the information for a specific validator.

### Method
GET

### Endpoint
`/valset/validator-info/{validator_valoper_address}`

### Parameters
#### Path Parameters
- **validator_valoper_address** (string) - Required - The valoper address of the validator.

### Response
#### Success Response (200)
- **validator** (object) - An object containing the validator's information.

#### Response Example
```json
{
  "validator": {
    "operator_address": "palomavaloper...",
    "consensus_pubkey": "...",
    "jailed": false,
    "status": 2,
    "tokens": "...",
    "delegator_shares": "..."
  }
}
```
```

--------------------------------

### Get Pigeon Requirements

Source: https://docs.palomachain.com/guide/develop/palomad/subcommands-q

Retrieves the minimum required version for pigeons.

```APIDOC
## GET /valset/pigeon-requirements

### Description
Returns the minimum required pigeon version.

### Method
GET

### Endpoint
`/valset/pigeon-requirements`

### Response
#### Success Response (200)
- **min_version** (string) - The minimum required pigeon version.

#### Response Example
```json
{
  "min_version": "v1.2.0"
}
```
```

--------------------------------

### Clone Paloma GitHub Repository

Source: https://docs.palomachain.com/guide/resources/paloma-ledger

This command clones the official Paloma blockchain repository from GitHub. It is the first step in building the Paloma CLI with Ledger support from source. Ensure Git is installed on your system.

```bash
git clone https://github.com/palomachain/paloma
```

--------------------------------

### Create and Sign Transaction with Automatic Fee Estimation

Source: https://docs.palomachain.com/guide/develop/quick-start/paloma-py/transactions

This example shows how to create and sign a transaction using a `Wallet`, allowing the Paloma SDK to automatically estimate and set the transaction fee. It also demonstrates how to optionally specify `gas_prices` and `gas_adjustment` for fee estimation. This method is useful when you don't want to manually specify fee parameters.

```python
from paloma_sdk.client.lcd import LCDClient
from paloma_sdk.key.mnemonic import MnemonicKey
from paloma_sdk.client.lcd.api.tx import CreateTxOptions
from paloma_sdk.core.bank import MsgSend

# Assuming MNEMONIC, RECIPIENT, and chain ID are defined elsewhere
# MNEMONIC = "your mnemonic phrase"
# RECIPIENT = "recipient address"
# PALOMA_CHAIN_ID = "your paloma chain id"

mk = MnemonicKey(mnemonic=MNEMONIC)
paloma = LCDClient("https://lcd.testnet.palomaswap.com", PALOMA_CHAIN_ID)
wallet = paloma.wallet(mk)

tx = wallet.create_and_sign_tx(CreateTxOptions(
    msgs=[
        MsgSend(
            wallet.key.acc_address,
            RECIPIENT,
            "1000000ugrain" # send 1 Grain
        )
    ],
    memo="test transaction!",
    gas_prices="0.015ugrain", # optional
    gas_adjustment="1.2", # optional
))

# The 'tx' object now contains the transaction with estimated fees.
# You can broadcast it using: paloma.tx.broadcast(tx)
```

--------------------------------

### Get WASM Contract Info

Source: https://docs.palomachain.com/guide/develop/palomad/subcommands-q

Retrieves metadata information about an instantiated WASM contract.

```APIDOC
## GET /wasm/contract

### Description
Retrieves the metadata information about an instantiated contract.

### Method
GET

### Endpoint
`/wasm/contract/{contract_address}`

### Parameters
#### Path Parameters
- **contract_address** (string) - Required - The address of the WASM contract.

### Response
#### Success Response (200)
- **contract_info** (object) - Information about the WASM contract.

#### Response Example
```json
{
  "contract_info": {
    "address": "paloma1...",
    "creator": "paloma1...",
    "code_id": "1",
    "init_msg": "..."
  }
}
```
```

--------------------------------

### Upgrade Paloma Testnet Software

Source: https://docs.palomachain.com/guide/maintain/node/updates-and-additional

This command sequence updates the Paloma project to the latest stable release from the 'master' branch and rebuilds the 'palomad' executable. Ensure you have Go version 1.18 or higher installed. This step assumes you are in the project's root directory.

```bash
git checkout master && git pull
go build ./cmd/palomad
```

--------------------------------

### Optimize Rust Smart Contract Build with Docker

Source: https://docs.palomachain.com/guide/develop/smart-contracts/contracts

This command optimizes your Rust smart contract's WASM binary for size, reducing fees and meeting blockchain size limits. It requires Docker to be installed. The output is an optimized WASM file in the artifacts directory. Note that builds may differ between Intel and ARM machines.

```bash
cargo run-script optimize
```

```bash
docker run --rm -v "$(pwd)":/code \
  --mount type=volume,source="$(basename "$(pwd)")_cache",target=/code/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/rust-optimizer-arm64:0.12.4
```

```bash
docker run --rm -v "$(wslpath -w $(pwd))":/code \
  --mount type=volume,source="$(basename "$(pwd)")_cache",target=/code/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/rust-optimizer:0.12.4
```

--------------------------------

### Get WASM Raw Store

Source: https://docs.palomachain.com/guide/develop/palomad/subcommands-q

Retrieves raw data from a WASM contract's store using a key and optional subkey.

```APIDOC
## GET /wasm/raw-store

### Description
Retrieves the raw store of a contract and prints the results.

### Method
GET

### Endpoint
`/wasm/raw-store/{contract_address}`

### Parameters
#### Path Parameters
- **contract_address** (string) - Required - The address of the WASM contract.

#### Query Parameters
- **key** (string) - Required - The key to query in the store.
- **subkey** (string) - Optional - The subkey to query, used for prefixed data stores.

### Response
#### Success Response (200)
- **data** (string) - The raw data retrieved from the contract store.

#### Response Example
```json
{
  "data": "raw_data_string"
}
```
```

--------------------------------

### Get Validator Jail Reason

Source: https://docs.palomachain.com/guide/develop/palomad/subcommands-q

Queries the reason why a specific validator is currently jailed.

```APIDOC
## GET /valset/validator-jail-reason

### Description
Queries the jail reason for a currently jailed validator.

### Method
GET

### Endpoint
`/valset/validator-jail-reason/{validator_valoper_address}`

### Parameters
#### Path Parameters
- **validator_valoper_address** (string) - Required - The valoper address of the validator.

### Response
#### Success Response (200)
- **jail_reason** (string) - The reason for the validator's jailing.

#### Response Example
```json
{
  "jail_reason": "double signing"
}
```
```

--------------------------------

### Get WASM Parameters

Source: https://docs.palomachain.com/guide/develop/palomad/subcommands-q

Retrieves the current parameters for the WASM module.

```APIDOC
## GET /wasm/params

### Description
Retrieves the current WASM module's parameters.

### Method
GET

### Endpoint
`/wasm/params`

### Response
#### Success Response (200)
- **params** (object) - An object containing the WASM module parameters.

#### Response Example
```json
{
  "params": {
    "max_contract_size": 512000,
    "max_contract_gas": 100000000,
    "max_contract_msg_size": 1024
  }
}
```
```

--------------------------------

### Get Valset Parameters

Source: https://docs.palomachain.com/guide/develop/palomad/subcommands-q

Retrieves the current parameters for the valset module.

```APIDOC
## GET /valset/params

### Description
Prints the parameters of the valset module.

### Method
GET

### Endpoint
`/valset/params`

### Response
#### Success Response (200)
- **params** (object) - An object containing the valset module parameters.

#### Response Example
```json
{
  "params": {
    "min_tokens": "1000000000000000000",
    "max_validators": 100,
    "unbonding_time": "1814400s"
  }
}
```
```

--------------------------------

### Set Transaction Gas Prices

Source: https://docs.palomachain.com/guide/develop/palomad/using-palomad

This example shows how to set the gas price for a transaction using the `--gas-prices` flag. This specifies the minimum price per unit of gas, allowing validators to calculate fees and prioritize transactions.

```bash
palomad tx send ... --gas-prices=0.05uGRAIN
```

--------------------------------

### Genesis Staking Parameters Configuration (Python)

Source: https://docs.palomachain.com/guide/develop/module-specifications/spec-staking

Sets the initial staking module parameters in the genesis configuration. This example modifies the bond denomination to 'ugrain' and sets the maximum validators to 130.

```python
# Staking: change bond_denom to ugrain and max validators to 130
genesis['app_state']['staking']['params'] = {
    'unbonding_time': '1814400s',  # 21 days
    'max_validators': 130,
    'max_entries': 7,
    'historical_entries': 10000,
    'bond_denom': DENOM_GRAIN
}
```

--------------------------------

### Get WASM Bytecode

Source: https://docs.palomachain.com/guide/develop/palomad/subcommands-q

Retrieves the WASM bytecode of a contract identified by its code ID.

```APIDOC
## GET /wasm/bytecode

### Description
Retrieves the contract's WASM bytecode by referencing its ID.

### Method
GET

### Endpoint
`/wasm/bytecode/{code_id}`

### Parameters
#### Path Parameters
- **code_id** (string) - Required - The ID of the WASM code.

### Response
#### Success Response (200)
- **bytecode** (string) - The base64 encoded WASM bytecode.

#### Response Example
```json
{
  "bytecode": "base64encodedbytecode..."
}
```
```

--------------------------------

### Get Latest Published Snapshot

Source: https://docs.palomachain.com/guide/develop/palomad/subcommands-q

Queries the most recent published snapshot for a specified target chain.

```APIDOC
## GET /valset/latest-published-snapshot

### Description
Queries the last published snapshot for a specific target chain.

### Method
GET

### Endpoint
`/valset/latest-published-snapshot/{chain_reference_id}`

### Parameters
#### Path Parameters
- **chain_reference_id** (string) - Required - The reference ID of the target chain.

### Response
#### Success Response (200)
- **snapshot** (object) - The latest published snapshot details.

#### Response Example
```json
{
  "snapshot": {
    "id": "...",
    "chain_id": "...",
    "height": "...",
    "data_hash": "..."
  }
}
```
```