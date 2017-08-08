pragma solidity ^0.4.11;

import "./interfaces/ICrowdsale.sol";
import "./interfaces/IMilestones.sol";

/*
  Basic Crodwsale Class
*/
contract Crowdsale is ICrowdsale {
  function Crowdsale(
    address _owner,
    address _parent,
    address _multisig,
    string _name,
    string _symbol,
    address _milestones,
    uint _price,
    uint _rewardPercent) {
      owner = _owner;
      parent = _parent;
      name = _name;
      symbol = _symbol;
      milestones = IMilestones(_milestones);
      price = _price;
      multisig = _multisig;
      cap = milestones.cap();
      rewardPercent = _rewardPercent;
  }

  function () public payable isCrowdsaleAlive() checkCap() {
    require(msg.value > 0);
    createTokens(msg.sender);
  }

  function createTokens(address recipient) internal isCrowdsaleAlive() checkCap() {
    uint tokens = msg.value.mul(getPrice());

    paritcipiants[recipient] = paritcipiants[recipient].add(msg.value);

    totalCollected = totalCollected.add(msg.value);
    contractBalance = contractBalance.add(msg.value);

    totalSupply = totalSupply.add(tokens);
    balances[recipient] = balances[recipient].add(tokens);
  }

  function setLimitations(uint _lockDataTimestamp, uint _startTimestamp, uint _endTimestamp) public onlyParent() isPossibleToModificate() {
    require(lockDataTimestamp > startTimestamp || startTimestamp > endTimestamp || lockDataTimestamp != 0);

    lockDataTimestamp = _lockDataTimestamp;
    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
  }

  function setForecasting(address _forecasting) public onlyParent() isPossibleToModificate() {
    forecasting = _forecasting;
  }

  function getPrice() public constant returns (uint result) {
    uint currentPrice = price;

    for (uint i = 0; i < priceChangesLength; i++) {
      if (priceChanges[i].timestamp < block.timestamp) {
        currentPrice = priceChanges[i].price;
      } else {
        break;
      }
    }

    return currentPrice;
  }

  function transfer(address _to, uint _value) public isCrowdsaleCompleted() returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public isCrowdsaleCompleted() returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint _value) public isCrowdsaleCompleted() returns (bool success) {
    return super.approve(_spender, _value);
  }

  function addVestingAccount(address _account, uint _initialPayment, uint _payment) public onlyOwner() isPossibleToModificate() {
    require(vestingAccounts[_account].account == address(0));

    var vestingAccount = VestingAccount(
        _account,
        _initialPayment,
        _payment,
        0,
        0
      );

    balances[_account] = balances[_account].add(_initialPayment);
    vestingAccounts[_account] = vestingAccount;
  }

  function addVestingAllocation(address _account, uint _timestamp) public onlyOwner() isPossibleToModificate() {
    var vestingAccount = vestingAccounts[_account];

    require(vestingAccount.account == address(0) || _timestamp == 0);

    if (vestingAccount.allocationsCount == 0) {
      uint previousAllocation = vestingAccount.allocations[vestingAccount.allocationsCount-1];

      assert(previousAllocation > _timestamp);
    }

    vestingAccount.allocations[vestingAccount.allocationsCount++] = _timestamp;
  }

  function releaseVestingAllocation() public isCrowdsaleCompleted() {
    var vestingAccount = vestingAccounts[msg.sender];

    if (vestingAccount.account == address(0)) {
      throw;
    }

    for (uint i = vestingAccount.latestAllocation; i < vestingAccount.allocationsCount; i++) {
      if (vestingAccount.allocations[i] < block.timestamp) {
        if (vestingAccount.allocations[i] == 0) {
          continue;
        }

        balances[vestingAccount.account] = balances[vestingAccount.account].add(vestingAccount.payment);
        vestingAccount.latestAllocation = i;
        vestingAccount.allocations[i] = 0;
      } else {
        break;
      }
    }
  }


  /*
    Get vesting account
  */
  function getVestingAccount(address _account) public constant returns (uint, uint, uint) {
    var vestingAccount = vestingAccounts[_account];
    return (vestingAccount.payment, vestingAccount.latestAllocation, vestingAccount.allocationsCount);
  }

  /*
    Get vesting allocation
  */
  function getVestingAllocation(address _account, uint _index) public constant returns (uint) {
    var vestingAccount = vestingAccounts[_account];

    return vestingAccount.allocations[_index];
  }

  function addPriceChange(uint _timestamp, uint _price) public onlyOwner() isPossibleToModificate() {
    if (priceChangesLength == 10) {
      throw;
    }

    if (priceChangesLength > 0) {
      var previousPriceChange = priceChanges[priceChangesLength-1];

      if (previousPriceChange.timestamp < _timestamp) {
        throw;
      }
    }

    priceChanges[priceChangesLength++] = PriceChange(_timestamp, _price);
  }

  /*
    Here we giving reward to account in percents
  */
  function giveReward(address _account, uint _amount) public onlyForecasting() isCrowdsaleCompleted() {
    balances[_account] = balances[_account].add(_amount);
  }

  /*
    Withdraw eth
  */
  function withdraw(uint _amount) public onlyOwner() isCrowdsaleCompleted() {
    if (_amount > contractBalance) {
      throw;
    }

    if (!multisig.send(_amount)) {
      throw;
    }
  }

  /*
    Is crowdsale failed
  */
  function payback() public isCrowdsaleFailed() {
    uint sendBack = paritcipiants[msg.sender];

    if (sendBack > 0) {
      paritcipiants[msg.sender] = 0;

      if (!msg.sender.send(sendBack)) {
        throw;
      }
    } else {
      throw;
    }
  }


  /*
    Is cap reached (if there is cap)
  */
  function isCapReached() public constant returns (bool) {
    return cap == true && totalCollected >= milestones.totalAmount();
  }

  /*
    Is minimal goal reached (if there is minimal goal)
  */
  function isMinimalReached() public constant returns (bool) {
    var (firstMilestoneAmount, items, completed) = milestones.get(0);

    return milestones.milestonesCount() == 0 || firstMilestoneAmount <= totalCollected;
  }
}
