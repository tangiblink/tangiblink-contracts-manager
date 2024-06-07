// cSpell:enableCompoundWords
const { getContract } = require("../utils/getContract")

task("get-all-users", "Gets all the token users using getUsersArray function").setAction(async (taskArgs) => {
  if (network.name === "hardhat") {
    throw Error(
      'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
    )
  }

  const domainRegistry = await getContract("domainRegistry")

  await getAllUsers(domainRegistry)
})

const getAllUsers = async (domainRegistry) => {
  const arrayLength = await domainRegistry.getTokenIdsCount()
  console.log(`\nRequesting all token users`)
  const users = await domainRegistry.getUsersArray(0, arrayLength)

  function User(user) {
    this.user = user
  }

  const userList = users.map((user) => {
    return new User(user)
  })
  console.log(`\nUsers:`)
  console.table([...userList])

  return users
}

exports.getAllUsers = getAllUsers
