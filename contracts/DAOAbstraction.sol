pragma solidity ^0.4.8;

import "./zeppelin/Ownable.sol";
import "./milestones/MilestonesFactory.sol";
import "./forecasts/ForecastingFactory.sol";
import "./crowdsales/CrowdsaleFactory.sol";

contract DAOAbstraction is Ownable {
  bytes32 public id; // id of project
  string public name; // name of project
  string public symbol; // symbol of project
  bytes32 public infoHash; // information hash of project

  address public token; // token contract address

  uint public timestamp; // timestamp when project created

  uint public reviewHours; // review period of project
  uint public forecastHours; // forecasting hours

  uint public rewardPercent; // reward percent

  bool public underCap; // is project under cap and latest milestone is cap
  uint public startTimestamp; // time of DAO start activity

  /*
    Factories
  */
  MilestonesFactory public milestonesFactory;
  ForecastingFactory public forecastingFactory;
  CrowdsaleFactory public crowdsaleFactory;

  address public milestones;
  address public forecasting;
  address public crowdsale;

  modifier isStarted(bool _value) {
    if (_value == true) {
      if (startTimestamp == 0) {
        throw;
      }

      _;
    } else {
      if (startTimestamp == 0) {
        _;
      } else {
        throw;
      }
    }
  }

  modifier checkReviewHours(uint _hours) {
    if (_hours < 1 || _hours > 504) {
      throw;
    }

    _;
  }

  modifier checkForecastHours(uint _hours) {
    if (_hours < 120 || _hours > 720) {
      throw;
    }

    _;
  }

  modifier checkCrowdsaleHours(uint _hours) {
    if (_hours < 168 || _hours > 2016) {
      throw;
    }

    _;
  }

  modifier onlyReview() {
   if (startTimestamp == 0 || (block.timestamp < (startTimestamp + (reviewHours * 1 hours)))) {
     _;
   } else {
     throw;
   }
 }

  /*
    Update project data
  */
  function update(bytes32 _infoHash) onlyOwner() onlyReview();

  /*
    Start DAO process
    //onlyOwner() isStarted(false) checkForecastHours(_forecastHours) checkCrowdsaleHours(_crowdsaleHours)
  */
  function start(
    uint _forecastHours,
    uint _crowdsaleHours,
    address _multisig,
    uint _initialPrice,
    uint _rewardPercent) onlyOwner() isStarted(false);

}
