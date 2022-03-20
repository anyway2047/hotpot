# hotpot
## description
  hotpot is a tool for automatic distribution and deployment, integrating DAO contracts and plugins, that realizes the rapid process of issuing a dao.
  This repository stores all hotpot evm compatible contracts used by hotpot.
  ***
## compile
  You can use contract compilation tools such as remix and solc to compile, The two main functions are in ```BondingSwap.sol``` and ```Hotpot.sol``` file, The constructor of BondingSwap does not need to pass in parameters, but the latter one needs to pass in 3 parameters, namely ```NAME, SYMBOL, CURVE (the address of the first contract)```
  ***
## deploy
  ### Ethereum
  You can use remix or ethersjs to deploy the contract. The testnet example is deployed on the goerli testnet of Ethereum. The contract address is [0x9e81E4eE6440ce2470d8EcD66C6386eC362472EB](https://goerli.etherscan.io/token/0x9e81E4eE6440ce2470d8EcD66C6386eC362472EB)
  ### Polkadot
  You can deploy contract at Moonbeam, an Ethereum-compatible smart contract parachain on Polkadot. Moonbeam is much more than just an EVM implementation: it’s a highly specialized Layer 1 chain that mirrors Web3 RPC, accounts, keys, subscriptions, logs, and more. The Moonbeam platform extends the base Ethereum feature set with additional features such as on-chain governance, staking, and cross-chain integrations. Deployment steps like Ethereum. The testnet example is deployed on the alpha testnet of Moonbase. The contract address is [0xDb443Ec688179E72c7912FB2B6718c078cE3A89F](https://moonbase.moonscan.io/token/0xDb443Ec688179E72c7912FB2B6718c078cE3A89F)
  ***
