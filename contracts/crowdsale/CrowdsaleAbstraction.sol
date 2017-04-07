pragma solidity ^0.4.2;

import "../zeppelin/token/StandardToken.sol";
import "../milestones/MilestonesAbstraction.sol";
import "../forecasting/ForecastingAbstraction.sol";
import "../zeppelin/Ownable.sol";

/*
  ToDo:
    - Pre-mine allocation
    - User reward allocation
    - Price based on time
    - Check timestamps verifications
*/
contract CrowdsaleAbstraction is StandardToken, Ownable {
  /*
    It's possible to change condition
  */
  modifier isPossibleToModificate() {
    if (lockDataTimestamp != 0 && block.timestamp > lockDataTimestamp) {
      throw;
    }

    _;
  }

  /*
    Crowdsale completed
  */
  modifier isCrowdsaleCompleted() {
    if ((endTimestamp != 0 && endTimestamp < block.timestamp) || (cap == true && totalCollected > milestones.totalAmount())) {
      _;
    } else {
      throw;
    }
  }

  /*
    Crowdsale alive
  */
  modifier isCrowdsaleAlive() {
    if ((startTimestamp < block.timestamp && endTimestamp > block.timestamp)
      || (cap == true && totalCollected < milestones.totalAmount()) ) {
        _;
    } else {
      throw;
    }
  }

  /*
    Only forecaster
  */
  modifier onlyForecasting() {
    if (msg.sender != forecasting) {
      throw;
    }

    _;
  }

  /*
    Struct Vesting Account
  */
  struct VestingAccount {
    address account;
    uint initialPayment;

    uint payment;
    uint latestAllocation;

    uint allocationsCount;
    mapping(uint => uint) allocations;
  }

  /*
    Vesting accounts list
  */
  mapping(address => VestingAccount) vestingAccounts;


  /*
    Owner of crowdsale
  */
  address public owner;

  /*
    Multisignature account
  */
  address public multisig;

  /*
    Contract where milestones placed
  */
  MilestonesAbstraction public milestones;

  /*
    Contract where forecasting placed
  */
  ForecastingAbstraction public forecasting;

  /*
    Total collected amount
  */
  uint public totalCollected;

  /*
    Price of token
  */
  uint public price;

  /*
    Under cap
  */
  bool public cap;

  /*
    Lock data timestamp
  */
  uint public lockDataTimestamp;

  /*
   Start & end timestamp
  */
  uint public startTimestamp;
  uint public endTimestamp;

  /*
    Reward percent
  */
  uint public rewardPercent;

  /*
    Create tokens for participiant
  */
  function createTokens(address recipient) payable isCrowdsaleAlive();

  /*
    Set timestamp limitations
  */
  function setLimitations(uint _startTimestamp, uint _endTimestamp) onlyOwner() isPossibleToModificate();

  /*
    Token transfer
  */
  function transfer(address _to, uint _value) isCrowdsaleCompleted() returns (bool success);

  /*
    Token transfer from
  */
  function transferFrom(address _from, address _to, uint _value) isCrowdsaleCompleted() returns (bool success);

  /*
    Approve of transfer
  */
  function approve(address _spender, uint _value) isCrowdsaleCompleted() returns (bool success);

  /*
    Add vesting account
  */
  function addVestingAccount(address _account, uint _initialPayment, uint _payment) onlyOwner() isPossibleToModificate();

  /*
    Add vesting allocation
  */
  function addVestingAllocation(address _account, uint _timestamp) onlyOwner() isPossibleToModificate();

  /*
    Release vesting allocation
  */
  function releaseVestingAllocation() isCrowdsaleCompleted();

  /*
    Give reward to forecaster based on percent from reward percent
  */
  function giveReward(address _account, uint _percent) onlyForecasting() isCrowdsaleCompleted();

  /*
    Withdraw ETH
  */
  function withdraw(uint _amount) payable onlyOwner() isCrowdsaleCompleted();
}
