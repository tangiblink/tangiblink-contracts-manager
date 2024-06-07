const { networks } = require("../../networks")

// Helper function to return a contract object, defined by the saved addresses in networks.js Config file.
const getContract = async (contractName) => {
  // Key pairs for contract name to solidity contract file name.
  const solidityDocKey = {
    usdPriceFeed: "MockV3Aggregator",
    metadata: "Metadata",
    domainRegistry: "DomainRegistry",
  }

  // Get the address from networks.js config file
  const contractAddress = networks[network.name][contractName]

  // Create the contract object
  console.log(
    `\nCreating a contract object for: ${contractName} \nContract Address: ${contractAddress} \nNetwork ${network.name}`
  )

  const contractFactory = await ethers.getContractFactory(solidityDocKey[contractName])
  const contract = await contractFactory.attach(contractAddress)
  console.log(`Contract object created for ${contractName}`)

  return contract
}
module.exports = { getContract }
