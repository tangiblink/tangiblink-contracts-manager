// cSpell:enableCompoundWords
const { getContract } = require("../utils/getContract")

task("get-all-tokens", "Gets all the token Ids using getTokenIdsArray function").setAction(async () => {
  if (network.name === "hardhat") {
    throw Error(
      'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
    )
  }

  const domainRegistry = await getContract("domainRegistry")

  await getAllTokens(domainRegistry)
})

const getAllTokens = async (domainRegistry) => {
  const arrayLength = await domainRegistry.getTokenIdsCount()
  console.log(`\nRequesting all token Ids`)
  const tokenIds = await domainRegistry.getTokenIdsArray(0, arrayLength)

  function TokenId(tokenId) {
    this.tokenId = tokenId.toString()
  }

  const tokenIdList = tokenIds.map((tokenId) => {
    return new TokenId(tokenId)
  })
  console.log(`\nToken Ids:`)
  console.table([...tokenIdList])

  return tokenIds
}

exports.getAllTokens = getAllTokens
