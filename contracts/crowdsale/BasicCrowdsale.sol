pragma solidity ^0.4.2;

import "./CrowdsaleAbstraction.sol";
import "../milestones/BasicMilestones.sol";
import "../forecasting/BasicForecasting.sol";

/*
  ToDo:
    - Two mode of creating tokens
    - Time bonuses / Price changing
    - Withdrawal allowing only if milestones completed
*/
contract BasicCrowdsale is CrowdsaleAbstraction {
  /*
    Should check review time and start/end timestamp.
  */
  function BasicCrowdsale(
    address _owner,
    address _multisig,
    string _name,
    string _symbol,
    address _milestones,
    address _forecasting,
    uint _price,
    uint _rewardPercent) {
      owner = _owner;
      name = _name;
      symbol = _symbol;
      milestones = BasicMilestones(_milestones);
      forecasting = BasicForecasting(_forecasting);
      price = _price;
      multisig = _multisig;
      cap = milestones.cap();
      rewardPercent = _rewardPercent;
  }

  function () payable {
    createTokens(msg.sender);
  }

  function createTokens(address recipient) payable isCrowdsaleAlive() {
    if (msg.value == 0) throw;

    uint tokens = safeMul(msg.value, getPrice());

    totalCollected = safeAdd(totalCollected, msg.value);
    totalSupply = safeAdd(totalSupply, tokens);
    balances[recipient] = safeAdd(balances[recipient], tokens);
  }

  function setLimitations(uint _lockDataTimestamp, uint _startTimestamp, uint _endTimestamp) onlyOwner() isPossibleToModificate() {
    if (lockDataTimestamp > startTimestamp || startTimestamp > endTimestamp) {
      throw;
    }

    lockDataTimestamp = _lockDataTimestamp;
    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
  }

  function getPrice() constant returns (uint result) {
    return price;
  }

  function transfer(address _to, uint _value) isCrowdsaleCompleted() returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) isCrowdsaleCompleted() returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint _value) isCrowdsaleCompleted() returns (bool success) {
    return super.approve(_spender, _value);
  }

  function addVestingAccount(address _account, uint _initialPayment, uint _payment) onlyOwner() isPossibleToModificate() {
    if (vestingAccounts[_account].account != address(0)) {
      throw;
    }

    var vestingAccount = vestingAccount(
        _account,
        _initialPayment,
        _payment,
        0,
        0
      );

    balances[_account] = safeAdd(balances[_account], _initialPayment);
    vestingAccounts[_account] = vestingAccount;
  }

  function addVestingAllocation(address _account, uint _timestamp) onlyOwner() isPossibleToModificate() {
    var vestingAccount = vestingAccounts[_account];

    if (vestingAccount.address == address(0) || _timestamp == 0) {
      throw;
    }

    if (vestingAccount.allocationsCount == 0) {
      uint previousAllocation = vestingAccount.allocations[vestingAccount.allocationsCount-1];

      if (previousAllocation > _time) {
        throw;
      }
    }

    vestingAccount.allocations[vestingAccount.allocations++] = _time;
  }

  function releaseVestingAllocation() isCrowdsaleCompleted() {
    var vestingAccount = preminers[msg.sender];

    if (vestingAccount.account == address(0)) {
      throw;
    }

    for (uint i = vestingAccount.latestAllocation; i < vestingAccount.allocationsCount; i++) {
      if (vestingAccount.allocations[i] < block.timestamp) {
        if (vestingAccount.allocations[i] == 0) {
          continue;
        }

        balances[vestingAccount.account] = safeAdd(balances[vestingAccount.account], vestingAccount.monthlyPayment);
        vestingAccount.latestAllocation = i;
        vestingAccount.allocations[i] = 0;
      } else {
        break;
      }
    }
  }

  /*
    Here we giving reward to account in percents
  */
  function giveReward(address _account, uint _percent) onlyForecasting() isCrowdsaleCompleted() {
    uint totalRewardAmount = safeMul(totalSupply, rewardPercent) / 100;
    uint reward = safeMul(totalRewardAmount, _percent) / 100;

    balances[_account] = safeAdd(balances[_account], reward);
  }

  function withdraw(uint _amount) payable onlyOwner() isCrowdsaleCompleted() {
    multisig.send(_amount);
  }
}
