// cSpell:enableCompoundWords
const { getContract } = require("../utils/getContract")

task("get-all-plus-codes", "Gets all the Plus Codes using getPlusCodesArray function").setAction(async () => {
  if (network.name === "hardhat") {
    throw Error(
      'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
    )
  }

  const domainRegistry = await getContract("domainRegistry")

  await getAllPlusCodes(domainRegistry)
})

const getAllPlusCodes = async (domainRegistry) => {
  const arrayLength = await domainRegistry.getTokenIdsCount()
  console.log(`\nRequesting all Plus Codes`)
  const plusCodes = await domainRegistry.getPlusCodesArray(0, arrayLength)

  function PlusCode(plusCode) {
    this.plusCode = plusCode
  }

  const plusCodeList = plusCodes.map((plusCode) => {
    return new PlusCode(plusCode)
  })
  console.log(`\nPlus Codes:`)
  console.table([...plusCodeList])

  return plusCodes
}

exports.getAllPlusCodes = getAllPlusCodes
