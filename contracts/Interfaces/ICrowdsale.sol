pragma solidity ^0.4.11;

import "./IMilestones.sol";

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/StandardToken.sol";

contract ICrowdsale is StandardToken, Ownable {
  /*
    Only parent
  */
  modifier onlyParent() {
    require(msg.sender == parent);
    _;
  }

  /*
    Check cap
  */
  modifier checkCap() {
    if (cap == true) {
      uint afterFund = msg.value.add(totalCollected);
      require(afterFund <= milestones.totalAmount());
      _;
    } else {
      _;
    }
  }

  /*
    It's possible to change condition
  */
  modifier isPossibleToModificate() {
    require(lockDataTimestamp != 0);
    require(block.timestamp > lockDataTimestamp);
    _;
  }

  /*
    Crowdsale failed
  */
  modifier isCrowdsaleFailed() {
    require(endTimestamp < block.timestamp);
    require(isMinimalReached() == false);
    _;
  }

  /*
    Crowdsale completed
  */
  modifier isCrowdsaleCompleted() {
    bool inTime = endTimestamp != 0 && endTimestamp < block.timestamp;
    require(isCapReached() == true || (inTime == true && isMinimalReached() == true));
    _;
  }

  /*
    Crowdsale alive
  */
  modifier isCrowdsaleAlive() {
    require((startTimestamp < block.timestamp && endTimestamp > block.timestamp));
    require(isCapReached() == false);
    _;
  }

  /*
    Only forecaster
  */
  modifier onlyForecasting() {
    require(msg.sender == address(forecasting));
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
    Struct Price change
  */
  struct PriceChange {
    uint timestamp;
    uint price;
  }

  /*
    Vesting accounts list
  */
  mapping(address => VestingAccount) public vestingAccounts;

  /*
    Paritcipiants
  */
  mapping(address => uint) public paritcipiants;

  /*
    Mapping price changing time
  */
  uint public priceChangesLength;
  mapping(uint => PriceChange) public priceChanges;

  /*
    ERC20
  */
  string public name;
  string public symbol;
  uint public decimals = 18;

  /*
    Owner of crowdsale
  */
  address public owner;
  address public parent;

  /*
    Multisignature account
  */
  address public multisig;

  /*
    Contract where milestones placed
  */
  IMilestones public milestones;

  /*
    Contract where forecasting placed
  */
  address public forecasting;

  /*
    Total collected amount
  */
  uint public totalCollected;

  /*
    Contract balance
  */
  uint public contractBalance;

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
    Wings Crowdsale Functional
  */

  /*
    Create tokens for participiant
  */
  function createTokens(address recipient) internal isCrowdsaleAlive() checkCap();

  /*
    Set timestamp limitations
  */
  function setLimitations(uint _lockDataTimestamp, uint _startTimestamp, uint _endTimestamp) public onlyParent() isPossibleToModificate();

  /*
    Set forecasting contract
  */
  function setForecasting(address _forecasting) public onlyParent() isPossibleToModificate();

  /*
      Vesting
  */

  /*
    Add vesting account
  */
  function addVestingAccount(address _account, uint _initialPayment, uint _payment) public onlyOwner() isPossibleToModificate();

  /*
    Add vesting allocation
  */
  function addVestingAllocation(address _account, uint _timestamp) public onlyOwner() isPossibleToModificate();

  /*
    Release vesting allocation
  */
  function releaseVestingAllocation() public isCrowdsaleCompleted();

  /*
    Get vesting account
  */
  function getVestingAccount(address _account) public constant returns (uint, uint, uint);

  /*
    Get vesting
  */
  function getVestingAllocation(address _account, uint _index) public constant returns (uint);

  /*
    Bonuses
  */

  /*
    Add price change
  */
  function addPriceChange(uint _timestamp, uint _price) onlyOwner() public isPossibleToModificate();


  /*
    Forecasting
  */

  /*
    Give reward to forecaster based on percent from reward percent
  */
  function giveReward(address _account, uint _amount) public onlyForecasting() isCrowdsaleCompleted();

  /*
    ETH functions (Payable)
  */

  /*
    Withdraw ETH
  */
  function withdraw(uint _amount) public onlyOwner() isCrowdsaleCompleted();

  /*
    Payback (only if crowdsale is not success)
  */
  function payback() public isCrowdsaleFailed();

  /*
    Is cap reached (if there is cap)
  */
  function isCapReached() public constant returns (bool);

  /*
    Is minimal goal reached (if there is minimal goal)
  */
  function isMinimalReached() public constant returns (bool);
}
