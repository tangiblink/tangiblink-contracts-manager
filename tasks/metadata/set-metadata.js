const { getContract } = require("../utils/getContract")
const { attributeArrays, svgArrays } = require("../../metadata-arrays")
const { networks } = require("../../networks")

// cSpell:enableCompoundWords

task("set-metadata", "Sets metadata attributes in the metadata contract")
  .addOptionalParam(
    "v",
    "metadata array version number of the metadata in metadata-arrays.json file (defaults to '1')",
    1,
    types.int
  )
  .setAction(async (taskArgs) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
      )
    }

    const metadata = await getContract("metadata")
    const versionNumber = taskArgs.v

    await setMetadata(metadata, versionNumber)
  })

const setMetadata = async (metadata, versionNumber) => {
  const svgArray = svgArrays[`${versionNumber}`]
  const attributeArray = attributeArrays[`${versionNumber}`]

  overrides = {
    //Gas limit for setting the metadata arrays due to large string lengths.
    gasLimit: 15000000,
  }

  const setMetadataSVGTx = await metadata.setSvgStringArray(svgArray, overrides)
  console.log(`\nWaiting for transaction ${setMetadataSVGTx.hash} to be confirmed...`)
  await setMetadataSVGTx.wait()
  console.log(`SVG String Arrays set`)

  const setMetadataAttributesTx = await metadata.setAttributeStringArray(attributeArray, overrides)
  console.log(`\nWaiting for transaction ${setMetadataAttributesTx.hash} to be confirmed...`)
  await setMetadataAttributesTx.wait()
  console.log(`Attributes String Arrays set`)
}

exports.setMetadata = setMetadata
