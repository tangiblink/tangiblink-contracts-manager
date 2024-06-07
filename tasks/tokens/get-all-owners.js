// cSpell:enableCompoundWords
const { getContract } = require("../utils/getContract")

task("get-all-owners", "Gets all the token owners using getOwnersArray function").setAction(async () => {
  if (network.name === "hardhat") {
    throw Error(
      'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
    )
  }

  const domainRegistry = await getContract("domainRegistry")

  await getAllOwners(domainRegistry)
})

const getAllOwners = async (domainRegistry) => {
  const arrayLength = await domainRegistry.getTokenIdsCount()
  console.log(`\nRequesting all token owners`)
  const owners = await domainRegistry.getOwnersArray(0, arrayLength)

  function Owner(owner) {
    this.address = owner
  }

  const ownersList = [...new Set(owners)].map((owner) => {
    return new Owner(owner)
  })
  console.log(`\nToken owners:`)
  console.table([...ownersList])

  return owners
}

exports.getAllOwners = getAllOwners
