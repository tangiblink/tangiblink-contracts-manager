// An off-chain conversion of Plus Code to token ID
function plusCodeToTokenId(plusCode) {
  return BigInt(ethers.keccak256(ethers.toUtf8Bytes(plusCode))).toString()
}

module.exports = {
  plusCodeToTokenId,
}
