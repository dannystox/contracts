pragma solidity ^0.4.2;

import './zeppelin/Ownable.sol';
import "./zeppelin/token/StandardToken.sol";

/*
  Wings ERC20 Token.
  Added allocation for users who participiated in Wings Campagin.
*/
contract Token is StandardToken, Ownable {
  /*
    Premine scturcture
  */
  struct Premine {
    address account;
    uint startTimestamp;
    uint lastTimeReached;
    uint monthes;
    uint monthlyPayment;
  }

  /*
    List of perminers
  */
  mapping(address => Premine) preminers;

  /*
    Token Name & Token Symbol
  */
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

  /*
    Standard Token functional
  */
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

  /*
    Premine functional
  */

  /*
    Add pre-mine account
  */
  function addPreminer(address preminer, uint initialBalance, uint startTime, uint monthes, uint monthlyPayment) onlyOwner() whenAllocation(true) {
    if (preminers[preminer].account != address(0)) {
      throw;
    }

    var premine = Premine(
        preminer,
        startTime,
        startTime,
        monthes,
        monthlyPayment
      );

    balances[preminer] = safeAdd(balances[preminer], initialBalance);
  }

  /*
    Release premine when preminer asking
  */
  function releasePremine() whenAllocation(false) {
    var preminer = preminers[msg.sender];

    if (preminer.account != address(0)) {
      throw;
    }

    // ToDo: Need to check how it's valid and cover with a lot of tests
    if ((preminer.startTimestamp + preminer.monthes * 31 days) < preminer.lastTimeReached) {
      throw;
    }

    // Calculate different timestamp
    uint diffTime = block.timestamp - preminer.lastTimeReached;
    uint diffMonthes = diffTime / 2678400;

    // Calculated different monthes
    if (diffMonthes > preminer.monthes) {
      diffMonthes = preminer.monthes;
    }

    // Add pre-mine to balance
    uint payment = diffMonthes * preminer.monthlyPayment;
    balances[preminer.account] = safeAdd(balances[preminer.account], payment);

    // Update when preminer asked to premine last time
    preminer.lastTimeReached = block.timestamp;
  }
}
