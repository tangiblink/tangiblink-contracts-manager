// cSpell:enableCompoundWords
const { getContract } = require("../utils/getContract")
const { plusCodeToTokenId } = require("../utils/plusCodeToTokenId")

task("set-user", "Sets a new user of token for a fixed period of time (Rental)")
  .addParam("pluscode", "google Plus Code to set user for")
  .addParam("user", "Address of the user to set permission for")
  .addParam("expiry", "Expiry time (UNIX) of user permissions")
  .addOptionalParam("gaslimit", "Maximum amount of gas that can be used", 10000000, types.int)

  .setAction(async (taskArgs) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
      )
    }

    const user = taskArgs.user
    const plusCode = taskArgs.pluscode
    const expiry = taskArgs.expiry
    const gasLimit = taskArgs.gaslimit

    await setUser(user, plusCode, expiry, gasLimit)
  })

const setUser = async (user, plusCode, expiry, _gasLimit) => {
  // Get the Domain Registry contract
  const domainRegistry = await getContract("domainRegistry")
  const domainRegistryAddress = await domainRegistry.getAddress()
  const dateTimeFormat = "en-US"
  const formattedDate = new Date(Number(expiry) * 1000).toLocaleDateString(dateTimeFormat)
  const formattedTime = new Date(Number(expiry) * 1000).toLocaleTimeString(dateTimeFormat)

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
  let setExpiry = 0

  if (!(await domainRegistry.exists(tokenId))) {
    throw Error("Token does not exist")
  }

  overrides = {
    //Gas limit for the Chainlink Functions request
    gasLimit: gasLimit,
  }

  console.log("Setting token with following user and expiry:")
  console.table({
    "Plus Code": plusCode,
    "token ID": tokenId,
    User: user,
    Expiry: expiry,
  })

  console.log("current user:", await domainRegistry.userOf(tokenId))
  console.log(`\nSetting new user...`)

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
      .setUser(tokenId, user, expiry, overrides)
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

  await new Promise(async (resolve) => {
    await domainRegistry.userExpires(tokenId).then((expiry) => {
      setExpiry = expiry
      resolve()
    })
  })

  console.table({
    "Domain registry": domainRegistryAddress,
    "Transaction status": txStatus,
    "Transaction hash": txHash ?? "ERROR",
    "Gas used": gasUsed.toString(),
    "Gas cost": gasCost.toString(),
    "Plus Code": plusCode,
    "Token ID": tokenId ? tokenId.toString() : "ERROR",
    "Token user": await domainRegistry.userOf(tokenId),
    "Expiry (UNIX)": setExpiry.toString(),
    "Formatted expiry": `${formattedDate} ${formattedTime} (Format: ${dateTimeFormat})`,
  })
}

exports.setUser = setUser
