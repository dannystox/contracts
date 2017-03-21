const isJump = (msg) => {
  return msg === 'VM Exception while processing transaction: invalid JUMP'
}

module.exports = {
  isJump: isJump
}
