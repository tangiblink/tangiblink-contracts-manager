# Tangiblink - Domain Registry

#### Tangiblink Domain Registry smart contracts. Author: Tangiblink, 2024. All rights reserved.

## Official deployments

Tangiblink Domain Registry Contracts are officially deployed to the Polygon mainnet (soon) and Polygon Amoy testnet networks.
The contract addresses are distributed via a [Network Addresses File](https://github.com/tangiblink/plus_code_domains/blob/main/network-addresses.json) and always kept up to date.

## Overview

Tangiblink Domain Registry provides domains names that represent physical geo-locations identified by [Plus Codes](https://maps.google.com/pluscodes/).<br>
Each domain is minted as an NFT using the ERC721 token standard.<br>
Domains allow mapping of any information to pre-defined or unique user defined keys.<br>
For example, the domain owner may want to list their business website address using the `key:'url'` and `value:'https://tangiblink.io/'`
or list their wallet address with `key:'BTC'` and `value:'0x...'`.

## Specifications

1. Implements ERC721

    [ERC-721](https://eips.ethereum.org/EIPS/eip-721) Non-Fungible Token Standard

2. Implements ERC165

    [ERC-165](https://eips.ethereum.org/EIPS/eip-165) Standard Interface Detection

3. Implements IERC721Metadata

    > IERC721Metadata is an extension of ERC-721. IERC721Metadata allows the smart contract to be interrogated for its name and for details about the assets which your NFTs represent.

    Ref: https://eips.ethereum.org/EIPS/eip-721

4. Implements ERC721URIStorage

    [ERC721URIStorage](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol) is an OpenZeppelin extension of ERC-721. ERC721URIStorage allows the smart contract to use the token name for the token URI instead of the token ID.

5. Implements [DomainRegistry](./contracts/DomainRegistry.sol)
   
6. Implements [PlusCodes](./contracts/PlusCodes.sol)
    
    PlusCodes contract checks validity of Plus Codes used for token minting

7. Record Storage (aka Resolver)

    Record Storage implements [RecordStorage](./contracts/RecordStorage.sol)

8. Implements [Metadata](./contracts/Metadata.sol)
    
    Metadata contract generates the NFT metadata and SVG image for market places


## Supported Networks

### Mainnets

- Polygon: `POLYGON_MAINNET_RPC_URL`, `POLYGONSCAN_API_KEY`, `LEDGER_WALLET_ADDRESS`, `--network polygon`

### Testnets

- Polygon Amoy: `POLYGON_AMOY_RPC_URL`, `POLYGONSCAN_API_KEY`, `--network polygonAmoy`
- 
- Polygon Sepolia:  `ETHEREUM_SEPOLIA_RPC_URL`, `ETHERSCAN_API_KEY`, `--network ethereumSepolia`

### Local networks

- [Foundry Anvil](#start-a-local-network): `--network localhost`

# Quickstart

## Requirements

- Node.js version [18](https://nodejs.org/en/download/) or latest

## Steps

1. Clone this repository to your local machine<br><br>
2. Open this directory in your command line, then run `npm install` to install all dependencies.<br><br>
3. Set the required environment variables.
   1. Set an encryption password for your environment variables to a secure password by running:
   ```
   npx env-enc set-pw
   ```
   2. Set the required environment variables (see [Environment Variable Management](#environment-variable-management)) using the command:
   ```
   npx env-enc set
   ```
      - _PRIVATE_KEY_ for your development wallet
      - _LEDGER_WALLET_ADDRESS_ for mainnet deployment using ledger wallet
      - _REPORT_GAS_ for displaying the gas used. Set `true` or `false`.
      - _FORKING_BLOCK_NUMBER_ for defining a specific block number when fork testing.
      - _ETHEREUM_SEPOLIA_RPC_URL_, _POLYGON_AMOY_RPC_URL_, _POLYGON_MAINNET_RPC_URL_ for the network that you intend to use
   3. If desired, the `<explorer>_API_KEY` can be set in order to verify contracts such as `_POLYGONSCAN_API_KEY_` or `_ETHERSCAN_API_KEY_`.<br><br>
4. There are two main files to notice that will be deployed:
   - _contracts/DomainRegistry.sol_ contains the smart contract that registers domains a resolves mapped key values (records).
   - _contracts/Metadata.sol_ contains the smart contract that builds each domains NFT metadata for use in domain registry tokenUri function calls.
   - A mock contract _contract/test/MockV3Aggregator.sol_ will also be deployed when deploying to a local network such as hardhat node or foundry anvil.<br><br>
5. If intending to deploy on local network, start a local node (see [Start a local network](#start-a-local-network)).<br><br>
6. Deploy and verify the client contract to an actual blockchain network by running:
   ```
   npx hardhat deploy-all --network <network_name_here>
   ```
   **Note**: Make sure `<explorer>_API_KEY` is set, depending on which network is used.<br>
   By default contracts are verified on Polygon mainnet/Amoy and not verified on local networks. This can be configured by altering `verifyContract` in `./networks.js`.<br>
   **Tip**: Deployed contract addresses are written to [network-addresses.json](./network-addresses.json) when running `deploy-all` and can be viewed there if required.
   <br><br>
7.  Test the contacts by running:
      ```
      forge test --fork-url <network-url-here>
      ```
   **Note**: This is the RPC URL, for local testing use `http://127.0.0.1:8545` or as displayed when starting a local network node. <br><br>

## Start a local network

A local network must be running for `localhost` network deployment, usage and testing. 

1. Open a new terminal. <br>**Note**: If this terminal is terminated follow these instructions again and re-deploy contracts to `localhost`.<br><br>
2. Set the encryption password for your environment variables by running:
   ```
   npx env-enc set-pw
   ```
   This must be the same password as used when setting up the Environment Variables in [Steps](#steps) above.<br><br>
3. Start a new local node by running:
   ```
   anvil
   ```
   You should see a list of accounts and private keys available for use, as well as the address and port that the node is listening on.<br>
   For more information on use of `Anvil` and it configurations visit [Foundry Book](https://book.getfoundry.sh/anvil/).<br><br>
4. Leave this terminal running for the duration of local network use, opening a new terminal to run any commands. 

Commands using the `--network` flag can now use `localhost` network name to run on the local network. 

# Environment Variable Management

This repo uses the NPM package `@chainlink/env-enc` for keeping environment variables such as wallet private keys, RPC URLs, and other secrets encrypted at rest. This reduces the risk of credential exposure by ensuring credentials are not visible in plaintext.

By default, all encrypted environment variables will be stored in a file named `.env.enc` in the root directory of this repo.

First, set the encryption password by running the command `npx env-enc set-pw`.
The password must be set at the beginning of each new session.
If this password is lost, there will be no way to recover the encrypted environment variables.

Run the command `npx env-enc set` to set and save environment variables.
These variables will be loaded into your environment when the `config()` method is called at the top of `hardhat.config.js`.
Use `npx env-enc view` to view all currently saved environment variables.
When pressing _ENTER_, the terminal will be cleared to prevent these values from remaining visible.
Running `npx env-enc remove VAR_NAME_HERE` deletes the specified environment variable.
The command `npx env-enc remove-all` deletes the entire saved environment variable file.

When running this command on a Windows machine, you may receive a security confirmation prompt. Enter `r` to proceed.

> **NOTE:** When you finish each work session, close down your terminal to prevent your encryption password from becoming exposes if your machine is compromised.

## Environment Variable Management Commands

The following commands accept an optional `--path` flag followed by a path to the desired encrypted environment variable file.
If one does not exist, it will be created automatically by the `npx env-enc set` command.

The `--path` flag has no effect on the `npx env-enc set-pw` command as the password is stored as an ephemeral environment variable for the current terminal session.

| Command                     | Description                                                                                                                                       | Parameters            |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| `npx env-enc set-pw`        | Sets the password to encrypt and decrypt the environment variable file **NOTE:** On Windows, this command may show a security confirmation prompt |                       |
| `npx env-enc set`           | Sets and saves variables to the encrypted environment variable file                                                                               |                       |
| `npx env-enc view`          | Shows all currently saved variables in the encrypted environment variable file                                                                    |                       |
| `npx env-enc remove <name>` | Removes a variable from the encrypted environment variable file                                                                                   | `name`: Variable name |
| `npx env-enc remove-all`    | Deletes the encrypted environment variable file                                                                                                   |                       |

# Command Glossary

The Domain Registry commands can be executed in the following format:
`npx hardhat command_here --parameter1 parameter_1_value_here --parameter2 parameter_2_value_here`

Example: `npx hardhat get-token-id --network polygonAmoy --pluscode 9GR776FF+9RX`

**Tip**: Install [hardhat-shorthand](https://www.npmjs.com/package/hardhat-shorthand) to allow use of `hh` in place of `npx hardhat` with command: 
```
npm i hardhat-shorthand
```

## Commands

| Command                            | Description                                                                                                                          | Parameters                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `compile`                          | Compiles all smart contracts                                                                                                         |                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `deploy-all`                   | Deploys all required contracts to required network. **Note**: Before deploying, ensure contract initializer values are correct in [deploy-config.js](./deploy-config.js). For mainnet deployment update `verifyContract` to `true` or `false` as required in [networks.js](./networks.js), if `verifyContract` is `true` please ensure that `_RPC_URL_` and `_API_KEY_` values are correctly set in `.env.enc` file as per [Steps (3)](#steps) above.         | `network`: Name of blockchain network,`gaslimit` (optional): Maximum amount of gas that can be used. Defaults to 10_000_000.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `verify-metadata`                   | Verifies the metadata contract on the required network. To be used if the verification fails during deployment. Available for testnet or mainnet only (not hardhat or localhost). **Note**: Before verifying please ensure that `_RPC_URL_` and `_API_KEY_` values are correctly set in `.env.enc` file as per [Steps (3)](#steps) above, also ensure that enough time has passed from deploying the metadata contract to allow bytecode to be available on the network.         | `network`: Name of blockchain network.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `mint`                   | Mints a new domain represented by the Plus Code as an ERC721 standard NFT on the Domain Registry contract               | `network`: Name of blockchain network, `pluscode`: Plus Code to be minted, `wei` (optional): Maximum amount of MATIC Token in Wei that can be used. Must be more than or equal to the cost of minting a domain. Default gets the cost from the Domain Registry contract, `gaslimit` (optional): Maximum amount of gas that can be used. Defaults to 10_000_000.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `mint-with-records`      | Mints a new domain represented by the Plus Code as an ERC721 standard NFT on the Domain Registry contract, additionally adds records to the token records. **Note**: Keys and Values to be written to the contract are to be predefined in [key-value-arrays.js](./key-value-arrays.js) before `mint-with-records` task is used.              | `network`: Name of blockchain network, `pluscode`: Plus Code to be minted, `wei` (optional): Maximum amount of MATIC Token in Wei that can be used. Must be more than or equal to the cost of minting a domain. Default gets the cost from the Domain Registry contract, `gaslimit` (optional): Maximum amount of gas that can be used. Defaults to 10_000_000.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `check-code`                   | Checks if a Plus Code is valid. Console logs result of validity check.             | `network`: Name of blockchain network, `pluscode`: Plus Code to be checked.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `withdraw`                   | Withdraws the networks native token (e.g MATIC) from the Domain Registry contract.             | `network`: Name of blockchain network, `to` (optional): Address to withdraw token to. Defaults to the deployer address, `amount` (optional): Amount in Wei to withdraw. Defaults to the full contract balance.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `withdraw-token`                   | Withdraws any ERC-20 token from the Domain Registry contract.             | `network`: Name of blockchain network,  `token`: The ERC-20 standard token address, `to` (optional): Address to withdraw token to. Defaults to the deployer address, `amount` (optional): Amount in Wei to withdraw. Defaults to the full contract balance of the specified ERC-20 token.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `get-metadata-attributes` | Gets the attributes used to build the NFT metadata for market place and NFT SVG image.                                                       | `network`: Name of blockchain network.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `set-metadata`      | Sets the metadata and SVG attribute arrays in the metadata contract. **Note**: Arrays to be written to the contract are to be predefined in [metadata-arrays.js](./metadata-arrays.js) before `set-metadata` task is used. Add versions to the arrays in [metadata-arrays.js](./metadata-arrays.js) and then specify the version number required with the `--v (version)` flag. Metadata and SVG arrays are to be updated in parallel i.e both arrays must be version 2. | `network`: Name of blockchain network, `v` (optional): Version of attributes to be set in metadata contract. Defaults to `version 1`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `token-uri`      | Gets the Token URI metadata and SVG image from the Domain Registry contract. **Note**: Outputs to terminal data in 3 formats [`encoded metadata`, `decoded metadata`, `decoded SVG image`].  |`network`: Name of blockchain network,  `pluscode`: The Plus Code of the minted Domain.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `update-base-uri` | Updates the Base URI in the Domain Registry contract, this is the prefix of the token URI (a concatenation of the `Base URI` and a tokens `Plus Code`) or defined as the URL within the tokens metadata (if a metadata contract present).  **Note**: If the `Base URI` is set as an empty string `""` then the Token URI/ URL with be only the `Plus Code` with no prefix.               | `network`: Name of blockchain network, `uri`: The new base URI, `gaslimit` (optional): Maximum amount of gas that can be used. Defaults to 300_000.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `get-all` | Gets all key values (records) for a given token ID.                  | `network`: Name of blockchain network, `pluscode`: The Plus Code of the minted Domain.                                                                                                                                                                                                                                                                                                                                                      |
| `set-many`      | Sets many new key values (records), adding records to the token records in the Domain Registry contract. **Note**: Keys and Values to be written to the contract are to be predefined in [key-value-arrays.js](./key-value-arrays.js) before `set-many` task is used. Define the array index for the keys and values using the relevant flags or default to index `0` (first array).             | `network`: Name of blockchain network,  `pluscode`: The Plus Code of the ERC721 token, `keyarray` (optional): index for the array of keys to be added from  [key-value-arrays.js](./key-value-arrays.js). Defaults to `0` index, `valuearray` (optional): index for the array of values to be added from  [key-value-arrays.js](./key-value-arrays.js). Defaults to `0` index, `gaslimit` (optional): Maximum amount of gas that can be used. Defaults to 10_000_000.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `set`      | Sets a new key and value, adding a record to the token records in the Domain Registry contract.             | `network`: Name of blockchain network,  `pluscode`: The Plus Code of the ERC721 token, `key`: Name of the key to set, `value`: Name of the value to set, `gaslimit` (optional): Maximum amount of gas that can be used. Defaults to 10_000_000.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `set-user`      | Sets a new user of token for a fixed period of time (Rental). This gives a user (other than the owner/authorized account) permission to use set record(s), reconfigure records or reset record functions on a specific token (defined by `pluscode`) for a given amount of time (defined by `expiry`) **Note**: The user then has sole permission for the tokens record manipulation functions. Another user such as the token owner/authorized account can no longer make changes to the tokens records until the user expires, a new user is set, or the token is transferred.         | `network`: Name of blockchain network,  `pluscode`: The Plus Code of the ERC721 token, `user`: Address of the user to set permission for, `expiry`: Expiry time (UNIX) of user permissions, `gaslimit` (optional): Maximum amount of gas that can be used. Defaults to 10_000_000.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `get-all-plus-codes`      | Gets an array of all the Plus Codes that have been minted as Domains. | `network`: Name of blockchain network.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `get-all-tokens`      | Gets an array of all the Token Ids for minted Domains. | `network`: Name of blockchain network.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `get-all-owners`      | Gets an array of all the Token Owners of minted Domains. | `network`: Name of blockchain network.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `get-all-users`      | Gets an array of all the Token users of minted Domains. | `network`: Name of blockchain network.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `get-all-info`      | Gets an array of all minted domains with information (token IDs, owners, users and rented (bool)) indexed by Plus Codes (Domain names). | `network`: Name of blockchain network, `filter`: Filters result columns. Use one of the following - 'tokenId', 'owner', 'user', 'rented', `expanded`: When set to 'true' the results are returned as un-sliced strings.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `get-token-id`      | Gets the Token Id for a minted Domain. | `network`: Name of blockchain network, `pluscode`: The Plus Code of the minted Domain.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `burn`      | Burns (delete) the requested Domain | `network`: Name of blockchain network, `pluscode`: Plus Code of the minted Domain to burn, `gaslimit` (optional): Maximum amount of gas that can be used. Defaults to 10_000_000.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |