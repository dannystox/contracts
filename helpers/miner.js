const Promise = require('bluebird')

const mineBlock = (web3) => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync({
      jsonrpc: "2.0",
      method: "evm_mine",
      params: [],
      id: new Date().getTime()
    }, (err, result) => {
      err? reject(err) : resolve()
    })
  })
}

module.exports = {
  mine: mineBlock
}
