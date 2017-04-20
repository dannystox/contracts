const keccak_256 = require('js-sha3').keccak_256

const getFunctionName = (name) => {
  let buffer = new Buffer(keccak_256.array(name));
  let bytes = buffer.slice(0, 4)
  return bytes.toString('hex')
}

const getAddress = (address) => {
  if (address.indexOf('0x') == 0) {
    address = address.substr(2)
  }

  return `000000000000000000000000${address}`
}

module.exports = {
  getFunctionName: getFunctionName,
  getAddress: getAddress
}
