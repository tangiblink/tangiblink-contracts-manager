const { types } = require("hardhat/config")
const { getContract } = require("./utils/getContract")
const { keyArrays, valueArrays } = require("../key-value-arrays")
const { plusCodeToTokenId } = require("./utils/plusCodeToTokenId")

// cSpell:enableCompoundWords

task("mint-with-records", "Mints the domain requested and sets key value records")
  .addParam("pluscode", "google Plus Code to be minted")
  .addOptionalParam("wei", "Maximum amount of MATIC Token in Wei that can be used")
  .addOptionalParam("gaslimit", "Maximum amount of gas that can be used", 10000000, types.int)
  .setAction(async (taskArgs) => {
    const plusCode = taskArgs.pluscode
    const gasLimit = taskArgs.gaslimit
    const maticWeiPayment = taskArgs.wei
    const keysArray = keyArrays[1]
    const valuesArray = valueArrays[1]

    await mintWithRecords(plusCode, keysArray, valuesArray, maticWeiPayment, gasLimit)
  })

const mintWithRecords = async (plusCode, keysArray, valuesArray, _maticWeiPayment, _gasLimit) => {
  // Get the Domain Registry contract
  const domainRegistry = await getContract("domainRegistry")
  const domainRegistryAddress = await domainRegistry.getAddress()
  // Check to see if the maximum gas limit has been exceeded
  const gasLimit = parseInt(_gasLimit ?? "1000000")
  if (gasLimit > 10_000_000) {
    throw Error("Gas limit must be less than or equal to 10_000_000")
  }
  const costUsdWei = parseInt(await domainRegistry.s_mintCostUsd())
  const costUsd = costUsdWei / 1e18
  var maticWeiPayment = _maticWeiPayment ?? "0"
  const cost = parseInt(await domainRegistry.checkPrice())
  const feedData = parseInt(await domainRegistry.getFeedData())
  let txStatus = "Failed"
  let txHash = null
  let gasCost = 0
  let gasUsed = 0
  let tokenId = plusCodeToTokenId(plusCode)

  if (await domainRegistry.exists(tokenId)) {
    throw Error("Token already exists")
  }

  if (parseInt(maticWeiPayment) == 0) {
    maticWeiPayment = cost
  }

  const overrides = {
    //Gas limit for the Chainlink Functions request
    gasLimit: gasLimit.toString(),
    // MATIC payment for verification
    value: maticWeiPayment.toString(),
  }

  // Send a Minting Transaction for the specified domain name.
  console.log(`\nMinting Plus Code: ${plusCode}`)

  function Record(key, value) {
    this.key = key
    this.value = value
  }

  const recordsToBeAdded = keysArray.map((key, index) => {
    return new Record(key, valuesArray[index])
  })
  console.log(`\nRecords to be written:`)
  console.table([...recordsToBeAdded])

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
      .mintWithRecords(plusCode, keysArray, valuesArray, overrides)
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
    "Plus Code": plusCode.toString(),
    "Token ID": tokenId ? tokenId.toString() : "ERROR",
    "Token minted": await domainRegistry.exists(tokenId),
    "Domain records #": recordsWritten.length.toString(),
    "Exchange Value": feedData.toString(),
    "Cost Wei": cost.toString(),
    "Cost USD": costUsd.toString(),
    "Payment Wei": maticWeiPayment.toString(),
  })
}
exports.mintWithRecords = mintWithRecords
