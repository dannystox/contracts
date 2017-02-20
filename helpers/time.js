const Promise = require('bluebird')

const moveTime = (web3, value) => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync({
      jsonrpc: "2.0",
      method: "evm_increaseTime",
      params: [value],
      id: new Date().getTime()
    }, (err, result) => {
      err? reject(err) : resolve()
    })
  })
}


module.exports = {
  moveTime: moveTime
}
