const { networks } = require("../networks")
const { types } = require("hardhat/config")
const { deployConfig } = require("../deploy-config")
const { setMetadata } = require("./metadata/set-metadata")
const fs = require("fs")
const { updateForgeTestConfig } = require("../scripts/update-forge-test-config")

task("deploy-all", "Deploys Domain Registry contract")
  .addOptionalParam("gaslimit", "Maximum amount used for function override gas", 10000000, types.int)
  .setAction(async (taskArgs) => {
    // Deploys contracts to required network and sets the contract variables required for minting.
    const gasLimit = taskArgs.gasLimit
    await deploy(gasLimit)

    console.log("\nAll contracts deployed and set\n")
  })

const deploy = async (_gasLimit) => {
  // Deploys contracts to Localhost / Testnet / Mainnet
  const gasLimit = parseInt(_gasLimit ?? "10000000")
  if (gasLimit > 10_000_000) {
    throw Error("Gas limit must be less than or equal to 10_000_000")
  }
  const overrides = {
    //Gas limit for the large gas use calls
    gasLimit: gasLimit.toString(),
  }
  const baseURL = deployConfig["initializer"]["baseURL"]
  const mintCostUsd = ethers.parseEther(deployConfig["initializer"]["mintCostUsd"])
  const feePercent = deployConfig["initializer"]["feePercent"] * 100
  const verifyContract = networks[network.name]["verifyContract"]

  // Recompile the latest version of the contracts
  console.log("\n__Compiling Contracts__")
  await run("compile")

  // Get the price feed contract address
  let usdPriceFeedAddress = networks[network.name]["usdPriceFeed"]
  if (network.name == "localhost" || network.name == "polygonAmoy") {
    usdPriceFeedAddress = await deployMocks()
  }

  // Deploy Metadata Contract
  const metadataContractConstructorArgs = []
  console.log(`\nDeploying Metadata contract to ${network.name}`)
  const metadataContractFactory = await ethers.getContractFactory("Metadata")
  const metadataContract = await metadataContractFactory.deploy(overrides)
  const metadataContractDeployTx = await metadataContract.deploymentTransaction()
  await metadataContract.waitForDeployment()
  const metadataContractAddress = await metadataContract.getAddress()
  console.log(
    `\nWaiting ${networks[network.name].confirmations} blocks for transaction ${
      metadataContractDeployTx.hash
    } to be confirmed...\n`
  )
  await metadataContractDeployTx.wait(networks[network.name].confirmations)
  console.log(`Metadata Contract deployed to address: ${metadataContractAddress}`)

  // Verify Metadata Contract if set as Optional Param
  await verifyDeployedContract(verifyContract, metadataContract, metadataContractConstructorArgs)
  // Deploy Domain Registry Contract
  const domainRegistryConstructorArgs = [baseURL, metadataContractAddress, mintCostUsd, feePercent, usdPriceFeedAddress]
  console.log(`\nDeploying Domain Registry contract to ${network.name}`)
  const domainRegistryFactory = await ethers.getContractFactory("DomainRegistry")
  const domainRegistry = await domainRegistryFactory.deploy(...domainRegistryConstructorArgs, overrides)
  const domainRegistryDeployTx = await domainRegistry.deploymentTransaction()
  await domainRegistry.waitForDeployment()
  const domainRegistryAddress = await domainRegistry.getAddress()
  console.log(
    `\nWaiting ${networks[network.name].confirmations} blocks for transaction ${
      domainRegistryDeployTx.hash
    } to be confirmed...`
  )
  await domainRegistryDeployTx.wait(networks[network.name].confirmations)
  console.log(`DomainRegistry deployed to address: ${domainRegistryAddress}`)

  // Verify domainRegistry if set as Optional Param
  await verifyDeployedContract(verifyContract, domainRegistry, domainRegistryConstructorArgs)

  console.log(`\nSetting the Metadata Storage variable: domainRegistryAddress = ${domainRegistryAddress}`)
  // Set the DomainRegistry address on the FunctionsConsumer Contract
  const setAddressInMetadataTx = await metadataContract.setDomainRegistry(domainRegistryAddress)
  console.log(
    `\nWaiting ${networks[network.name].confirmations} blocks for transaction ${
      setAddressInMetadataTx.hash
    } to be confirmed...`
  )
  await setAddressInMetadataTx.wait(networks[network.name].confirmations)
  console.log(`Domain registry address has been set in Metadata contract`)

  // set the metadata attributes in Metadata contract.
  await setMetadata(metadataContract, 1)

  console.log("\nDeployed contract addresses")
  if (network.name == "localhost" || network.name == "polygonAmoy") {
    console.table({
      "Metadata contract": metadataContractAddress.toLowerCase(),
      "DomainRegistry contract": domainRegistryAddress.toLowerCase(),
      "usdPriceFeed contract": usdPriceFeedAddress.toLowerCase(),
    })
  } else {
    console.table({
      "Metadata contract": metadataContractAddress.toLowerCase(),
      "DomainRegistry contract": domainRegistryAddress.toLowerCase(),
    })
  }

  //   Read saved addresses from network-addresses.json and write new address to JSON array.
  var jsonData
  var jsonParsed
  const readData = fs.readFileSync("network-addresses.json")
  if (readData == "") {
    jsonData = `{
      "polygonMainnet": {
        "metadata": "",
        "domainRegistry": "",
      },
      "polygonAmoy": {
        "metadata": "",
        "domainRegistry": "",
      },
      "ethereumSepolia": {
        "metadata": "",
        "domainRegistry": "",
      },
      "localhost": {
        "metadata": "",
        "domainRegistry": "",
        "usdPriceFeed": ""
      }
  }`
  } else {
    jsonData = readData
  }
  // parse json
  jsonParsed = JSON.parse(jsonData)
  jsonParsed[network.name].metadata = metadataContractAddress.toLowerCase()
  jsonParsed[network.name].domainRegistry = domainRegistryAddress.toLowerCase()
  if (network.name == "localhost" || network.name == "polygonAmoy") {
    jsonParsed[network.name].usdPriceFeed = usdPriceFeedAddress.toLowerCase()
  }

  // stringify JSON Object
  var jsonContent = JSON.stringify(jsonParsed, null, 2)
  fs.writeFileSync("network-addresses.json", jsonContent)

  // Update forge test config with contract names
  updateForgeTestConfig(
    domainRegistryAddress,
    metadataContractAddress,
    usdPriceFeedAddress,
    baseURL,
    mintCostUsd,
    feePercent
  )
}

const deployMocks = async () => {
  const latestRoundData = BigInt(deployConfig["initializer"]["latestRoundData"])
  // Deploy mock MATIC/USD price feed
  console.log(`\nDeploying Mock price feed contract to ${network.name}`)
  const usdPriceFeedFactory = await ethers.getContractFactory("MockV3Aggregator")
  const usdPriceFeed = await usdPriceFeedFactory.deploy(0, latestRoundData)
  const usdPriceFeedDeployTx = await usdPriceFeed.deploymentTransaction()
  console.log(
    `\nWaiting ${networks[network.name].confirmations} blocks for transaction ${
      usdPriceFeedDeployTx.hash
    } to be confirmed...\n`
  )
  await usdPriceFeed.waitForDeployment()
  const usdPriceFeedAddress = await usdPriceFeed.getAddress()
  console.log(`Mock MATIC/USD price feed deployed to address: ${usdPriceFeedAddress}`)

  return usdPriceFeedAddress
}

const verifyDeployedContract = async (verifyContract, contractInstance, constructorArgs) => {
  if (verifyContract && !!networks[network.name].verifyApiKey && networks[network.name].verifyApiKey !== "UNSET") {
    try {
      console.log("\nVerifying contract...")
      const contractInstanceAddress = await contractInstance.getAddress()
      const contractInstanceDeployTx = await contractInstance.deploymentTransaction()
      await contractInstanceDeployTx.wait(Math.max(8 - networks[network.name].confirmations, 0))
      await run("verify:verify", {
        address: contractInstanceAddress,
        constructorArguments: [...constructorArgs],
      })
      console.log(`\nContract verified: ${contractInstanceAddress}`)
    } catch (error) {
      if (!error.message.includes("Already Verified")) {
        console.log("\nError verifying contract.  Delete the build folder and try again.\n")
        console.log(error)
        console.log(
          "\nIf the Metadata contract failed verification (common on mainnet) a separate task 'verify-metadata' is available to verify after deployment"
        )
      } else {
        console.log(`\nContract already verified: ${contractInstance}`)
      }
    }
  } else if (verifyContract) {
    console.log("\n<network>_API_KEY is missing. Skipping contract verification...")
  }
}

exports.deploy = deploy
