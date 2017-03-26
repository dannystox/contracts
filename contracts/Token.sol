pragma solidity ^0.4.2;

import './zeppelin/Ownable.sol';
import "./zeppelin/token/StandardToken.sol";

/*
  Wings ERC20 Token.
  Added allocation for users who participiated in Wings Campagin.
*/
contract Token is StandardToken, Ownable {
  event Allocation(address indexed account, uint amount);
  event PremineRelease(address indexed account, uint timestamp, uint amount);

  /*
    Premine scturcture
  */
  struct Preminer {
    address account;
    uint monthlyPayment;
    uint latestAllocation;

    uint allocationsCount;
    mapping(uint => uint) allocations;
  }

  /*
    List of perminers
  */
  mapping(address => Preminer) preminers;

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
  uint public accountsToAllocate;

  /*
    Modifier for checking is allocation completed.
    Maybe we should add here pre-mine accounts too.
  */
  modifier whenAllocation(bool value) {
    if ((accountsToAllocate > 0) == value) {
      _;
    } else {
      throw;
    }
  }

  function Token(uint _accountsToAllocate) {
    totalSupply = 100000000000000000000000000;
    owner = msg.sender;

    accountsToAllocate = _accountsToAllocate;
  }

  /*
    Allocate tokens for users.
    Only owner and only while allocation active.
  */
  function allocate(address user, uint balance) onlyOwner() whenAllocation(true) {
    balances[user] = balance;

    accountsToAllocate--;
    Allocation(user, balance);
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
  function addPreminer(address preminer, uint initialBalance, uint monthlyPayment) onlyOwner() whenAllocation(true) {
    if (preminers[preminer].account != address(0)) {
      throw;
    }

    var premine = Preminer(
        preminer,
        monthlyPayment,
        0,
        0
      );


    balances[preminer] = safeAdd(balances[preminer], initialBalance);
    preminers[preminer] = premine;
    accountsToAllocate--;
  }

  /*
    Add pre-mine allocation
  */
  function addPremineAllocation(address _preminer, uint _time) onlyOwner() whenAllocation(true) {
    var preminer = preminers[_preminer];

    if (preminer.account == address(0) || _time == 0) {
      throw;
    }

    if (preminer.allocationsCount > 0) {
      var previousAllocation = preminer.allocations[preminer.allocationsCount-1];

      if (previousAllocation > _time) {
        throw;
      }

      preminer.allocations[preminer.allocationsCount++] = _time;
    } else {
      preminer.allocations[preminer.allocationsCount++] = _time;
    }
  }

  /*
    Release premine when preminer asking
    Gas usage: 0x5786 or 22406 GAS.
    Let's add limitation to 20 per cycle for cycle to be sure it could execute.
  */
  function releasePremine() whenAllocation(false) {
    var preminer = preminers[msg.sender];

    if (preminer.account == address(0)) {
      throw;
    }

    for (var i = preminer.latestAllocation; i < preminer.allocationsCount; i++) {
      if (preminer.allocations[i] < block.timestamp) {
        if (preminer.allocations[i] == 0) {
          continue;
        }

        balances[preminer.account] = safeAdd(balances[preminer.account], preminer.monthlyPayment);
        preminer.latestAllocation = i;

        PremineRelease(preminer.account, preminer.monthlyPayment, preminer.allocations[i]);
        preminer.allocations[i] = 0;
      } else {
        break;
      }
    }
  }
}
