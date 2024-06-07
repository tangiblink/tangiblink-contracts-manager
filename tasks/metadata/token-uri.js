// cSpell:enableCompoundWords
const { getContract } = require("../utils/getContract")
const { plusCodeToTokenId } = require("../utils/plusCodeToTokenId")

task("token-uri", "Gets the on-chain metadata using tokenURI function")
  .addParam("pluscode", "google Plus Code for the domain NFT to get token URI for")

  .setAction(async (taskArgs) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
      )
    }

    const domainRegistry = await getContract("domainRegistry")
    const plusCode = taskArgs.pluscode

    await tokenUri(plusCode, domainRegistry)
  })

const tokenUri = async (plusCode, domainRegistry) => {
  let tokenId = plusCodeToTokenId(plusCode)

  console.log(`\nnRequesting metadata for Token ID: ${tokenId}\nDomain: ${plusCode}\n`)

  const metadata = await domainRegistry.tokenURI(tokenId)
  console.log(`RAW METADATA:\n ${metadata}\n`)

  // Decode the metadata from base64
  const dataIdentifier = "data:application/json;base64,"
  const dataIdentifierLength = dataIdentifier.length
  const metadataBase64 = metadata.slice(dataIdentifierLength)
  const decodedMetadata = Buffer.from(metadataBase64, "base64")
  const decodedMetadataString = decodedMetadata.toString()
  console.log(`\nDECODED TOKEN URI:\n ${decodedMetadataString}\n`)

  // Parse the metadata object to JSON
  const metadataJson = JSON.parse(decodedMetadataString)
  const imageJsonData = metadataJson.image

  // Decode the image data from base64
  const imageDataIdentifier = "data:image/svg+xml;base64,"
  const imageDataIdentifierLength = imageDataIdentifier.length
  const decodedImageStringLength = imageJsonData.length
  const imageBase64 = imageJsonData.slice(imageDataIdentifierLength, decodedImageStringLength - 1)
  const decodedImage = Buffer.from(imageBase64, "base64")
  const decodedImageString = decodedImage.toString()
  console.log(`\nDECODED SVG IMAGE:\n ${decodedImageString}\n`)
}

exports.tokenUri = tokenUri
