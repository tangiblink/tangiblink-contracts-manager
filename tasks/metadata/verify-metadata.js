const { networks } = require("../../networks")
const { getContract } = require("../utils/getContract")

task("verify-metadata", "Verifies the metadata contract")
  .setAction(async () => {
    if (network.name === "hardhat" || network.name === "localhost")  {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network on testnet or mainnet.'
      )
    }
    // Verifies metadata contract.
    await verifyMetadata()
    console.log("\nMetadata contract verified\n")
  })

const verifyMetadata = async () => {
  // Verifies a contract on Testnet / Mainnet
  const metadataContract = await getContract("metadata")
  const metadataContractConstructorArgs = []
  const metadataContractAddress = await metadataContract.getAddress()
  console.log("metadataContractAddress:", metadataContractAddress)

  if (!!networks[network.name].verifyApiKey && networks[network.name].verifyApiKey !== "UNSET") {
    try {
      console.log("\nVerifying contract...")
      await run("verify:verify", {
        address: metadataContractAddress,
        constructorArguments: [...metadataContractConstructorArgs],
      })
      console.log(`\nContract verified: ${metadataContractAddress}`)
    } catch (error) {
      if (!error.message.includes("Already Verified")) {
        console.log("\nError verifying contract.  Delete the build folder and try again.\n")
        console.log(error)
      } else {
        console.log(`\nContract already verified: ${metadataContractAddress}`)
      }
    }
  } else {
    console.log("\n<network>_API_KEY is missing. Skipping contract verification...")
  }
}

exports.verifyMetadata = verifyMetadata
