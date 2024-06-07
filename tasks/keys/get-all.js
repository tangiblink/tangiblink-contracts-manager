// cSpell:enableCompoundWords
const { keyArrays, valueArrays } = require("../../key-value-arrays")
const { getContract } = require("../utils/getContract")
const { plusCodeToTokenId } = require("../utils/plusCodeToTokenId")

task("get-all", "Gets all key values (records) for a given token ID")
  .addParam("pluscode", "google Plus Code for the domain NFT to get records for")

  .setAction(async (taskArgs) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
      )
    }

    const domainRegistry = await getContract("domainRegistry")
    const plusCode = taskArgs.pluscode

    await getAll(plusCode, domainRegistry)
  })

const getAll = async (plusCode, domainRegistry) => {
  let tokenId = plusCodeToTokenId(plusCode)
  console.log(`\nGetting keys and values for token ID: ${tokenId}\nDomain: ${plusCode}`)
  const keys = await domainRegistry.getKeysOf(tokenId)
  const values = await domainRegistry.getMany([...keys], tokenId)

  function Record(key, value) {
    this.key = key
    this.value = value
  }

  const records = keys.map((key, index) => {
    return new Record(key, values[index])
  })
  console.log(`\nRecords: ${records.length}`)
  if (keys.length == 0 || values.length == 0) {
    console.log(`\nNo records present for this domain.\n`)
  } else {
    console.table([...records])
  }

  return records
}
exports.getAll = getAll
