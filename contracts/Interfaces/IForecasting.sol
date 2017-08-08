pragma solidity ^0.4.11;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/ERC20.sol";

import "../helpers/Temporary.sol";
import "./IMilestones.sol";

contract IForecasting is Ownable, Temporary {
  /*
    Allow 6 numbers after dot.
  */
  modifier isValidRewardPercent(uint _rewardPercent) {
    require(_rewardPercent < 100000000);
    require(_rewardPercent > 0);
    _;
  }

  struct Forecast {
    address owner;
    uint amount;
    uint created_at;
    bytes32 message;
  }

  mapping(uint => Forecast) public forecasts;
  mapping(address => Forecast) public userForecasts;

  /*
    Forecasts count
  */
  uint public forecastsCount;

  /*
    Reward forecasting percent
  */
  uint public rewardPercent;

  /*
    Token
  */
  ERC20 public token;

  /*
    Milestones
  */
  IMilestones public milestones;

  /*
    Crowdsale
  */
  address public crowdsale;

  /*
    Max forecast amount
  */
  uint public max;

  /*
    Add forecast
  */
  function add(uint _amount, bytes32 _message) inTime();

  /*
    Get user forecast
  */
  function getByUser(address _user) constant returns (uint, uint, bytes32);

  /*
    Get forecast
  */
  function get(uint _index) constant returns (address, uint, uint, bytes32);
}
