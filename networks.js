// All supported networks and related contract addresses are defined here.
//
// Price feeds addresses: https://docs.chain.link/data-feeds/price-feeds/addresses
// Chain IDs: https://chainlist.org/?testnets=true

// Loads environment variables from .env.enc file (if it exists)
require("@chainlink/env-enc").config()
const fs = require("fs")
//   Read saved addresses from network-addresses.json and write new address to JSON array.
const jsonData = fs.readFileSync("network-addresses.json")
// parse json
const networkAddresses = JSON.parse(jsonData)

const DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS = 2

const npmCommand = process.env.npm_lifecycle_event
const isTestEnvironment = npmCommand == "test" || npmCommand == "test:unit"

// Set EVM private keys (required)
const PRIVATE_KEY = process.env.PRIVATE_KEY
const LEDGER_WALLET_ADDRESS = process.env.LEDGER_WALLET_ADDRESS

if (!isTestEnvironment && !PRIVATE_KEY) {
  throw Error("Set the PRIVATE_KEY environment variable with your EVM wallet private key")
}

const accounts = []
if (PRIVATE_KEY) {
  accounts.push(PRIVATE_KEY)
}

const networks = {
  polygon: {
    verifyContract: true,
    url: process.env.POLYGON_MAINNET_RPC_URL || "UNSET",
    gasPrice: undefined,
    nonce: undefined,
    ledgerAccounts: [LEDGER_WALLET_ADDRESS], // replace line with 'accounts,' if you wish to use a metamask account instead
    verifyApiKey: process.env.POLYGONSCAN_API_KEY || "UNSET",
    chainId: 137,
    confirmations: DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS,
    nativeCurrencySymbol: "MATIC",
    metadata: networkAddresses.polygonMainnet.metadata,
    domainRegistry: networkAddresses.polygonMainnet.domainRegistry,
    usdPriceFeed: "0xab594600376ec9fd91f8e885dadf0ce036862de0", // MATIC/USD
  },

  polygonAmoy: {
    verifyContract: true,
    url: process.env.POLYGON_AMOY_RPC_URL || "UNSET",
    gasPrice: 20_000_000_000,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.POLYGONSCAN_API_KEY || "UNSET",
    chainId: 80002,
    confirmations: DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS,
    nativeCurrencySymbol: "MATIC",
    metadata: networkAddresses.polygonAmoy.metadata,
    domainRegistry: networkAddresses.polygonAmoy.domainRegistry,
    usdPriceFeed: networkAddresses.polygonAmoy.usdPriceFeed, // MATIC/USD
  },

  ethereumSepolia: {
    verifyContract: true,
    url: process.env.ETHEREUM_SEPOLIA_RPC_URL || "UNSET",
    gasPrice: 20_000_000_000,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.ETHERSCAN_API_KEY || "UNSET",
    chainId: 11155111,
    confirmations: DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS,
    nativeCurrencySymbol: "ETH",
    metadata: networkAddresses.ethereumSepolia.metadata,
    domainRegistry: networkAddresses.ethereumSepolia.domainRegistry,
    usdPriceFeed: "0x694aa1769357215de4fac081bf1f309adc325306", // ETH/USD
  },

  localhost: {
    allowUnlimitedContractSize: true,
    gasPrice: undefined,
    verifyContract: false,
    confirmations: 1,
    nativeCurrencySymbol: "ETH",
    metadata: networkAddresses.localhost.metadata,
    domainRegistry: networkAddresses.localhost.domainRegistry,
    usdPriceFeed: networkAddresses.localhost.usdPriceFeed, // MATIC/USD
  },
  hardhat: {
    allowUnlimitedContractSize: true,
    gasPrice: undefined,
  },
}

const developmentChains = ["localhost", "anvil", "hardhat"]

module.exports = {
  networks,
  developmentChains,
}
