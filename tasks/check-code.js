const { getContract } = require("./utils/getContract")

// cSpell:enableCompoundWords

task("check-code", "checks if a Plus Code is valid")
  .addOptionalParam("pluscode", "google Plus Code to be minted")
  .setAction(async (taskArgs) => {
    if (network.name === "hardhat") {
      throw Error(
        "This command cannot be used on a local development chain.  Specify a valid network or run a local node."
      )
    }

    const plusCode = taskArgs.pluscode

    await checkCode(plusCode)
  })

const checkCode = async (plusCode) => {
  // Create the contract object
  const domainRegistry = await getContract("domainRegistry")

  const isValidTx = await domainRegistry.isValid(plusCode)
  if (isValidTx) {
    console.log(`\nPlus Code is Valid`)
  } else {
    console.log(`\Not a Valid Plus Code`)
  }
  const correctedCode = await domainRegistry.checkCode(plusCode)
  console.log(`\nCode returned from checkCode function: ${correctedCode}\n`)
}

exports.checkCode = checkCode
