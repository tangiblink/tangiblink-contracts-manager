const { developmentChains } = require("../networks")
const CONFIG_CONTRACT_FILE_PATH = "ForgeTestConfig.s.sol"
const fs = require("fs")

const updateForgeTestConfig = async (
  domainRegistryAddress,
  metadataAddress,
  usdPriceFeedAddress,
  baseURL,
  mintCostUsd,
  feePercent
) => {
  console.warn("\nRemember to check forgeTestConfig values:")
  console.table({
    domainRegistryAddress: domainRegistryAddress,
    metadataAddress: metadataAddress,
    usdPriceFeedAddress: usdPriceFeedAddress,
    baseURL: baseURL,
    mintCostUsd: `${mintCostUsd.toString()} ($${ethers.formatUnits(mintCostUsd)})`,
    feePercent: `${feePercent.toString()} (${(feePercent / 100).toString()}%)`,
    network: network.name,
  })

  if (!domainRegistryAddress || !metadataAddress || !usdPriceFeedAddress) {
    throw new Error("missing arguments")
  }
  if (!network.name) {
    throw new Error("network is undefined")
  }
  let networkName = ""
  if (network.name == "ethereumSepolia") {
    networkName = "SEPOLIA"
  }
  if (network.name == "polygonAmoy") {
    networkName = "AMOY"
  }
  if (network.name == "polygon") {
    networkName = "POLYGON"
  }
  if (developmentChains.includes(network.name)) {
    networkName = "LOCALHOST"
  }
  const filePath = `${__dirname}/${CONFIG_CONTRACT_FILE_PATH}`

  const file = fs.readFileSync(filePath).toString("utf-8")
  if (!file) {
    throw new Error(`Could not read file ${CONFIG_CONTRACT_FILE_PATH}`)
  }
  let replacement = file
  let placeholder_domain_registry = new RegExp(
    networkName + `_DOMAIN_REGISTRY_ADDRESS\\s*=\\s*(0x[a-fA-F0-9]{40})\\s*;`,
    "g"
  )
  let placeholder_metadata = new RegExp(networkName + `_METADATA_ADDRESS\\s*=\\s*(0x[a-fA-F0-9]{40})\\s*;`, "g")
  let placeholder_matic_usd = new RegExp(networkName + `_MATIC_USD_ADDRESS\\s*=\\s*(0x[a-fA-F0-9]{40})\\s*;`, "g")
  let placeholder_base_url = new RegExp(`BASE_URL\\s*=\\s*"([a-zA-Z0-9])*"\\s*;`, "g")
  let placeholder_domain_cost = new RegExp(`MINT_COST_USD\\s*=\\s*([0-9])*\\s*;`, "g")
  let placeholder_fee_percent = new RegExp(`FEE_PERCENT\\s*=\\s*([0-9])*\\s*;`, "g")

  replacement = replacement.replace(
    placeholder_domain_registry,
    constructDomainRegistryAddressReplacement(domainRegistryAddress)
  )
  replacement = replacement.replace(placeholder_metadata, constructMetadataAddressReplacement(metadataAddress))
  replacement = replacement.replace(placeholder_matic_usd, constructMaticUsdAddressReplacement(usdPriceFeedAddress))
  replacement = replacement.replace(placeholder_base_url, `BASE_URL = "${baseURL}";`)
  replacement = replacement.replace(placeholder_domain_cost, `MINT_COST_USD = ${mintCostUsd};`)
  replacement = replacement.replace(placeholder_fee_percent, `FEE_PERCENT = ${feePercent};`)

  // write
  fs.writeFileSync(filePath, replacement)

  function enforceStartWith0X(address) {
    if (!address.startsWith("0x")) {
      return `0x${address}`
    }
    return address
  }

  function constructDomainRegistryAddressReplacement(domainRegistryAddress) {
    return `${networkName}_DOMAIN_REGISTRY_ADDRESS = ${enforceStartWith0X(domainRegistryAddress)};`
  }

  function constructMetadataAddressReplacement(metadataAddress) {
    return `${networkName}_METADATA_ADDRESS = ${enforceStartWith0X(metadataAddress)};`
  }

  function constructMaticUsdAddressReplacement(usdPriceFeedAddress) {
    return `${networkName}_MATIC_USD_ADDRESS = ${enforceStartWith0X(usdPriceFeedAddress)};`
  }
}
module.exports = { updateForgeTestConfig }
