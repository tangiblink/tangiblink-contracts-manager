// cSpell:enableCompoundWords
const { getContract } = require("./utils/getContract")

task("withdraw", "Withdraws funds from Domain Registry contract")
  .addOptionalParam("to", "Address to withdraw token to")
  .addOptionalParam("amount", "Amount in Wei to withdraw", 0, types.int)
  .setAction(async (taskArgs) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
      )
    }

    const to = taskArgs.to
    const amount = taskArgs.amount
    const domainRegistry = await getContract("domainRegistry")

    await withdraw(to, amount, domainRegistry)
  })

const withdraw = async (to, amount, domainRegistry) => {
  const domainRegistryAddress = await domainRegistry.getAddress()
  const payeeAddress = to ?? (await domainRegistry.owner())
  const payeeBalanceBefore = await ethers.provider.getBalance(payeeAddress)
  const balanceBefore = await ethers.provider.getBalance(domainRegistryAddress)
  let txStatus = "Failed"
  let txHash = null
  let gasCost = 0
  let gasUsed = 0
  let balanceAfter = 0
  let payeeBalanceAfter = 0

  if (amount == 0) {
    amount = balanceBefore
  }

  console.log(`\nWithdrawing native currency`)

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
      .withdraw(payeeAddress, amount)
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

  balanceAfter = await ethers.provider.getBalance(domainRegistryAddress)
  payeeBalanceAfter = await ethers.provider.getBalance(payeeAddress)

  console.table({
    "Domain registry": domainRegistryAddress,
    "Transaction status": txStatus,
    "Transaction hash": txHash ?? "ERROR",
    "Gas used": gasUsed.toString(),
    "Gas cost": gasCost.toString(),
    "Domain ballance before": balanceBefore.toString(),
    "Domain ballance after": balanceAfter.toString(),
    "Payee address": payeeAddress,
    "Payee balance before": payeeBalanceBefore.toString(),
    "Payee balance after": payeeBalanceAfter.toString(),
    "Withdrawl amount": amount.toString(),
  })

  return true
}

exports.withdraw = withdraw
