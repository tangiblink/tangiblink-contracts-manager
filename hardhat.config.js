require("@nomicfoundation/hardhat-toolbox")
require("@nomicfoundation/hardhat-foundry")
require("@nomicfoundation/hardhat-ledger")
require("./tasks")
require("hardhat-contract-sizer")
require("hardhat-gas-reporter")
require("@chainlink/env-enc").config()
const { networks } = require("./networks")

// Enable gas reporting (optional)
const REPORT_GAS = process.env.REPORT_GAS?.toLowerCase() === "true" ? true : false

const SOLC_SETTINGS = {
  optimizer: {
    enabled: true,
    runs: 1_000,
  },
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "localhost",
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: SOLC_SETTINGS,
      },
      {
        version: "0.8.9",
        settings: SOLC_SETTINGS,
      },
      {
        version: "0.8.7",
        settings: SOLC_SETTINGS,
      },
      {
        version: "0.7.6",
        settings: SOLC_SETTINGS,
      },
      {
        version: "0.7.0",
        settings: SOLC_SETTINGS,
      },
      {
        version: "0.6.6",
        settings: SOLC_SETTINGS,
      },
      {
        version: "0.4.24",
        settings: SOLC_SETTINGS,
      },
    ],
  },
  networks: {
    ...networks,
  },
  etherscan: {
    // npx hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
    // to get exact network names: npx hardhat verify --list-networks
    apiKey: {
      polygonAmoy: networks.polygonAmoy.verifyApiKey,
      sepolia: networks.ethereumSepolia.verifyApiKey,
      polygon: networks.polygon.verifyApiKey,
    },
  },
  gasReporter: {
    enabled: REPORT_GAS,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
  },
  contractSizer: {
    runOnCompile: false,
    only: ["PlusCodes", "DomainRegistry", "Metadata"],
  },
  mocha: {
    timeout: 200000, // 200 seconds max for running tests
  },
}
