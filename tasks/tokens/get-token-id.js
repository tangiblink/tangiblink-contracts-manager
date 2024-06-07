// cSpell:enableCompoundWords
const { getContract } = require("../utils/getContract")

task("get-token-id", "Gets the token Id from the Plus Code using plusCodeToTokenId function")
  .addParam("pluscode", "google Plus Code to be minted")

  .setAction(async (taskArgs) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
      )
    }

    const domainRegistry = await getContract("domainRegistry")
    const plusCode = taskArgs.pluscode

    await getTokenId(plusCode, domainRegistry)
  })

const getTokenId = async (_plusCode, domainRegistry) => {
  console.log(`\nRequesting Token ID for Plus Code: ${_plusCode}`)
  const tokenId = await domainRegistry.plusCodeToTokenId(_plusCode)

  function TokenId(tokenId) {
    this.tokenId = tokenId.toString()
  }

  console.log(`\nToken Id:`)
  console.table([new TokenId(tokenId)])

  return tokenId
}

exports.getTokenId = getTokenId
