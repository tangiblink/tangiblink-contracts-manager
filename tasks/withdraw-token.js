// cSpell:enableCompoundWords
const { task } = require("hardhat/config")
const { getContract } = require("./utils/getContract")
const ERC20Json = require("@openzeppelin/contracts/build/contracts/ERC20.json")

task("withdraw-token", "Withdraws specified ERC20 token from Domain Registry contract")
  .addParam("token", "The token address")
  .addOptionalParam("to", "Address to withdraw token to")
  .addOptionalParam("amount", "Amount in Wei to withdraw", 0, types.int)
  .setAction(async (taskArgs) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or run a local node "localhost".'
      )
    }

    const tokenAddress = taskArgs.token
    const to = taskArgs.to
    const amount = taskArgs.amount
    const domainRegistry = await getContract("domainRegistry")

    await withdrawToken(tokenAddress, to, amount, domainRegistry)
  })

const withdrawToken = async (tokenAddress, to, amount, domainRegistry) => {
  const domainRegistryAddress = await domainRegistry.getAddress()
  const ERC20ABI = ERC20Json.abi
  const ERC20Token = new ethers.Contract(tokenAddress, ERC20ABI, ethers.provider)
  const payeeAddress = to ?? (await domainRegistry.owner())
  const payeeBalanceBefore = await ethers.provider.getBalance(payeeAddress)
  const balanceBefore = await ERC20Token.balanceOf(domainRegistryAddress)
  let txStatus = "Failed"
  let txHash = null
  let gasCost = 0
  let gasUsed = 0
  let balanceAfter = 0
  let payeeBalanceAfter = 0

  if (amount == 0) {
    amount = balanceBefore
  }

  console.log(`\nWithdrawing ERC20 tokens: ${tokenAddress}`)

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
      .withdrawErc20(tokenAddress, payeeAddress, amount)
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

  balanceAfter = await ERC20Token.balanceOf(domainRegistryAddress)
  payeeBalanceAfter = await ethers.provider.getBalance(payeeAddress)

  console.table({
    "Domain registry": domainRegistryAddress,
    "Transaction status": txStatus,
    "Transaction hash": txHash ?? "ERROR",
    "Gas used": gasUsed.toString(),
    "Gas cost": gasCost.toString(),
    "ERC20 Token address": tokenAddress,
    "Domain ballance before": balanceBefore.toString(),
    "Domain ballance after": balanceAfter.toString(),
    "Payee address": payeeAddress,
    "Payee balance before": payeeBalanceBefore.toString(),
    "Payee balance after": payeeBalanceAfter.toString(),
    "Withdrawl amount": amount.toString(),
  })

  return true
}

exports.withdrawToken = withdrawToken
