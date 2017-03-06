/* global contract, Token, before */
const Token = artifacts.require("../contracts/Token.sol")

contract('Token', function (accounts) {
  let wings
  let creator

  before('Initialize Wings contract', () => {
    creator = accounts[0]

    return Token.new({
      from: creator
    }).then((_wings) => {
      wings = _wings
    })
  })
})
