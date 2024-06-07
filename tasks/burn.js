const { types } = require("hardhat/config")
const { getContract } = require("./utils/getContract")
const { plusCodeToTokenId } = require("./utils/plusCodeToTokenId")

// cSpell:enableCompoundWords

task("burn", "Burns the domain requested")
  .addParam("pluscode", "google Plus Code to be minted")
  .addOptionalParam("gaslimit", "Maximum amount of gas that can be used", 10000000, types.int)
  .setAction(async (taskArgs) => {
    const plusCode = taskArgs.pluscode
    const gasLimit = taskArgs.gaslimit

    await burn(plusCode, gasLimit)
  })

const burn = async (plusCode, _gasLimit) => {
  // Get the Domain Registry contract
  const domainRegistry = await getContract("domainRegistry")

  // Check to see if the maximum gas limit has been exceeded
  const gasLimit = parseInt(_gasLimit ?? "1000000")
  if (gasLimit > 10_000_000) {
    throw Error("Gas limit must be less than or equal to 10_000_000")
  }
  let txStatus = "Failed"
  let txHash = null
  let gasCost = 0
  let gasUsed = 0
  let tokenId = plusCodeToTokenId(plusCode)

  if (!(await domainRegistry.exists(tokenId))) {
    throw Error("Token does not exist")
  }

  const overrides = {
    //Gas limit for the Chainlink Functions request
    gasLimit: gasLimit.toString(),
  }

  // Send a Minting Transaction for the specified domain name.
  console.log(`\nBurning Plus Code: ${plusCode}`)

  let timeOut = 120
  let i = timeOut
  let startTimer = false
  setInterval(function () {
    if (startTimer) {
      process.stdout.clearLine() // clear current text
      process.stdout.cursorTo(0) // move cursor to beginning of line
      i = i - 1
      process.stdout.write("Transaction times out in: " + i + " seconds") // write text
    }
  }, 1000)

  await new Promise(async (resolve) => {
    setTimeout(() => {
      txError = "Transaction took too long"
      return resolve()
    }, timeOut * 1000)

    await domainRegistry
      .burn(tokenId, overrides)
      .then((tx) => {
        console.log(`\nTransaction pending ...`)
        //action prior to transaction being mined
        startTimer = start
        tx.wait().then((receipt) => {
          gasCost = receipt.cumulativeGasUsed * (receipt.effectiveGasPrice ?? receipt.gasPrice)
          gasUsed = receipt.cumulativeGasUsed
          txHash = tx.hash
          if (receipt.status == "0x0") {
            txStatus = "Unsuccessful"
            return resolve()
          } else {
            txStatus = "Success"
            return resolve()
          }
        })
      })
      .catch(() => {
        //action to perform when transaction cancelled"
        txStatus = "Cancelled"
        return resolve()
      })
  })

  console.log(`\nStatus: ${txStatus}`)

  console.table({
    "Domain registry": await domainRegistry.getAddress(),
    "Transaction status": txStatus,
    "Transaction hash": txHash ?? "ERROR",
    "Gas used": gasUsed.toString(),
    "Gas cost": gasCost.toString(),
    "Plus Code": plusCode.toString(),
    "Token ID": tokenId ? tokenId.toString() : "ERROR",
    "Token burned": !(await domainRegistry.exists(tokenId)),
  })
}
exports.burn = burn
