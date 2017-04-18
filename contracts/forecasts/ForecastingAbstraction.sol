pragma solidity ^0.4.8;

import "../zeppelin/Ownable.sol";
import "../Token.sol";
import "../milestones/MilestonesAbstraction.sol";

contract ForecastingAbstraction is Ownable {
  /*
      When it possible to add forecasting
  */
  modifier inTime {
    if (block.timestamp > startTimestamp && block.timestamp < endTimestamp) {
      _;
    } else {
      throw;
    }
  }

  /*
    Allow 6 numbers after dot.
  */
  modifier checkRewardPercent(uint _rewardPercent) {
    if (_rewardPercent > 100000000 || _rewardPercent == 0) {
      throw;
    }

    _;
  }

  struct Forecast {
    address owner;
    uint amount;
    uint timestamp;
    bytes32 message;
  }

  mapping(uint => Forecast) public forecasts;
  mapping(address => Forecast) public userForecasts;

  /*
    Forecasts count
  */
  uint public forecastsCount;

  /*
    When we allow to add milestones
  */
  uint public startTimestamp;

  /*
    When we doesnt allow to add milestones
  */
  uint public endTimestamp;

  /*
    Reward forecasting percent
  */
  uint public rewardPercent;

  /*
    Token
  */
  Token public token;

  /*
    Milestones
  */
  MilestonesAbstraction public milestones;
  address public crowdsale;

  /*
    Max forecast amount
  */
  uint public max;


  /*
    Is under cap?
  */
  bool public cap;

  /*
    Add forecast
  */
  function add(uint _amount, bytes32 _message);

  /*
    Get user forecast
  */
  function getByUser(address _user) constant returns (uint, uint, bytes32);

  /*
    Get forecast
  */
  function get(uint _index) constant returns (address, uint, uint, bytes32);
}
