// cSpell:enableCompoundWords
const { getContract } = require("../utils/getContract")

task("update-base-uri", "Sets the base URI storage variable in the Domain Registry contract")
  .addParam("uri", "The new base URI")
  .addOptionalParam("gaslimit", "Maximum amount of gas that can be used", 300_000, types.int)
  .setAction(async (taskArgs) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
      )
    }

    const domainRegistry = await getContract("domainRegistry")
    const uri = taskArgs.uri
    const gasLimit = taskArgs.gaslimit

    await setBaseURI(uri, domainRegistry, gasLimit)
  })

const setBaseURI = async (uri, domainRegistry, _gasLimit) => {
  // Check to see if the maximum gas limit has been exceeded
  const gasLimit = parseInt(_gasLimit ?? "10000000")
  if (gasLimit > 10_000_000) {
    throw Error("Gas limit must be less than or equal to 10_000_000")
  }
  overrides = {
    //Gas limit for the Chainlink Functions request
    gasLimit: gasLimit,
  }

  const currentURI = await domainRegistry.s_baseURI()
  console.log(`\nThe current URI is: ${currentURI}`)
  console.log(`\nUpdating base URI to: ${uri}`)
  const uriUpdateTx = await domainRegistry.setBaseURI(uri, overrides)
  await uriUpdateTx.wait()
  const newURI = await domainRegistry.s_baseURI()
  console.log(`\nThe new URI confirmed as: ${newURI}\n`)
}

exports.setBaseURI = setBaseURI
