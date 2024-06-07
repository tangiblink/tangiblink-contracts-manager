// cSpell:enableCompoundWords
const { getContract } = require("../utils/getContract")
const { plusCodeToTokenId } = require("../utils/plusCodeToTokenId")

task("set", "Sets a new key value (record)")
  .addParam("pluscode", "google Plus Code to set a record for")
  .addParam("key", "Name of the key to set")
  .addParam("value", "Name of the value to set")
  .addOptionalParam("gaslimit", "Maximum amount of gas that can be used", 300_000, types.int)
  .setAction(async (taskArgs) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
      )
    }

    const plusCode = taskArgs.pluscode
    const keyName = taskArgs.key
    const value = taskArgs.value
    const gasLimit = taskArgs.gaslimit

    await setKeyValue(keyName, value, plusCode, gasLimit)
  })

const setKeyValue = async (keyName, value, plusCode, _gasLimit) => {
  // Get the Domain Registry contract
  const domainRegistry = await getContract("domainRegistry")
  const domainRegistryAddress = await domainRegistry.getAddress()

  // Check to see if the maximum gas limit has been exceeded
  const gasLimit = parseInt(_gasLimit ?? "10000000")
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

  overrides = {
    //Gas limit for the Chainlink Functions request
    gasLimit: gasLimit,
  }

  console.log(`Setting a domain record`)

  function Record(key, value) {
    this.key = key
    this.value = value
  }

  console.log(`\nRecord to be written:`)
  console.table([new Record(keyName, value)])

  let timeOut = 120
  let i = timeOut
  let startTimer = false
  setInterval(function () {
    if (startTimer && txStatus === "Failed") {
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
      .set(keyName, value, tokenId, overrides)
      .then((tx) => {
        console.log(`\nTransaction pending ...`)
        //action prior to transaction being mined
        startTimer = true
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

  const allKeys = await domainRegistry.getKeysOf(plusCodeToTokenId(plusCode))
  const allValues = await domainRegistry.getMany([...allKeys], plusCodeToTokenId(plusCode))
  const recordsWritten = allKeys.map((key, index) => {
    return new Record(key, allValues[index])
  })

  console.log(`\nAll domain records:`)
  console.table([...recordsWritten])

  console.table({
    "Domain registry": domainRegistryAddress,
    "Transaction status": txStatus,
    "Transaction hash": txHash ?? "ERROR",
    "Gas used": gasUsed.toString(),
    "Gas cost": gasCost.toString(),
    "Plus Code": plusCode,
    "Token ID": tokenId ? tokenId.toString() : "ERROR",
    "Domain records #": recordsWritten.length.toString(),
  })
}

exports.setKeyValue = setKeyValue
