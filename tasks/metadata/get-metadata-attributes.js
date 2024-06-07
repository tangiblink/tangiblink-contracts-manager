// cSpell:enableCompoundWords
const { getContract } = require("../utils/getContract")

task("get-metadata-attributes", "Gets the on-chain metadata attributes").setAction(async () => {
  if (network.name === "hardhat") {
    throw Error(
      'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
    )
  }

  const metadataContract = await getContract("metadata")
  const domainRegistry = await getContract("domainRegistry")

  await getMetadataAttributes(metadataContract, domainRegistry)
})

const getMetadataAttributes = async (metadataContract, domainRegistry) => {
  const metadataContractAddress = await domainRegistry.getMetadataContractAddress()
  console.log(`\nThe metadata contract address set in the Domain Registry is: ${metadataContractAddress}`)

  console.log(`\nFetching metadata attributes...`)
  const SvgStrings = await metadataContract.getSvgStringArray()
  console.log(`\nSVG attribute strings are:\n ${SvgStrings}\n\n`)

  const AttributesStrings = await metadataContract.getAttributeStringArray()
  console.log(`\nNFT attribute strings are:\n ${AttributesStrings}\n\n`)
}

exports.getMetadataAttributes = getMetadataAttributes
