pragma solidity ^0.4.2;

import './zeppelin/Ownable.sol';
import "./zeppelin/token/StandardToken.sol";

/*
  Wings ERC20 Token.
  Added allocation for users who participiated in Wings Campagin.
*/
contract Token is StandardToken, Ownable {
  string public name = "WINGS";
  string public symbol = "WINGS";

  /*
    Is allocation completed?
  */
  bool public allocation;

  /*
    How many accounts allocated?
  */
  uint public allocatedAccountsCount;
  uint public allocatedAccounts;

  /*
    Modifier for checking is allocation completed
  */
  modifier whenAllocation(bool value) {
    if (allocation == value) {
      _;
    }
  }

  function Token(uint _allocatedAccountsCount) {
    totalSupply = 100000000000000000000000000;
    owner = msg.sender;
    allocation = true;

    allocatedAccountsCount = _allocatedAccountsCount;
  }

  /*
    Allocate tokens for users.
    Only owner and only while allocation active.
  */
  function allocate(address user, uint balance) onlyOwner() whenAllocation(true) {
    if (allocatedAccounts < allocatedAccountsCount) {
      balances[user] = balance;
      allocatedAccounts++;
    } else {
      throw;
    }
  }

  /*
    Compliting allocation.
    Only for owner and while allocation active.
  */
  function completeAllocation() onlyOwner() whenAllocation(true) {
    if (allocatedAccounts != allocatedAccountsCount) {
      throw;
    }

    allocation = false;
  }

  function transfer(address _to, uint _value) whenAllocation(false) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) whenAllocation(false) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) whenAllocation(false) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

}
