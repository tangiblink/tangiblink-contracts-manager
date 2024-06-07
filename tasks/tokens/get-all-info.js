// cSpell:enableCompoundWords
const { getContract } = require("../utils/getContract")

task("get-all-info", "Gets token infomation for all minted tokens")
  .addOptionalParam("filter", "Filters result columns. Use one of the following - 'tokenId', 'owner', 'user', 'rented'")
  .addOptionalParam("expand", "When set to 'true' the results are returned as un-sliced strings")
  .setAction(async (taskArgs) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
      )
    }

    const filter = taskArgs.filter
    const expand = taskArgs.expand

    const domainRegistry = await getContract("domainRegistry")

    await getAllTokenInfo(domainRegistry, filter, expand)
  })

const getAllTokenInfo = async (domainRegistry, filter, expand) => {
  const arrayLength = await domainRegistry.getTokenIdsCount()

  console.log(`\nRequesting all Token Info`)

  const plusCodes = await domainRegistry.getPlusCodesArray(0, arrayLength)
  const owners = await domainRegistry.getOwnersArray(0, arrayLength)
  const tokenIds = await domainRegistry.getTokenIdsArray(0, arrayLength)
  const users = await domainRegistry.getUsersArray(0, arrayLength)

  function AllInfo(tokenId, owner, user) {
    this.tokenId =
      filter || expand ? tokenId.toString() : `${tokenId.toString().slice(0, 14)}...${tokenId.toString().slice(63)}`
    this.owner = filter || expand ? owner : `${owner.slice(0, 7)}...${owner.slice(38)}`
    this.user = filter || expand ? user : `${user.slice(0, 7)}...${user.slice(38)}`
    this.rented = user !== owner
  }

  const allInfo = {}

  for (let i = 0; i < arrayLength; i++) {
    allInfo[plusCodes[i]] = new AllInfo(tokenIds[i], owners[i], users[i])
  }

  console.log(`\nAll token info:`)
  if (filter) {
    console.table(allInfo, [filter])
  } else {
    console.table(allInfo)
  }

  return allInfo
}

exports.getAllTokenInfo = getAllTokenInfo
