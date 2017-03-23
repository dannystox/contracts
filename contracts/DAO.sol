pragma solidity ^0.4.2;

import "./DAOAbstraction.sol";
import "./milestones/BasicMilestones.sol";
import "./forecasts/BasicForecasting.sol";

contract DAO is DAOAbstraction {
  function DAO(address _owner, string _name, bytes32 _infoHash, uint _category, bool _underCap) {
    if (_category > 5) {
      throw;
    }

    owner = _owner;
    id = sha256(_name);
    name = _name;
    infoHash = _infoHash;
    category = _category;
    timestamp = block.timestamp;
    underCap = _underCap;
  }

  /*
    Start DAO process
  */
  function start() onlyOwner() isStarted(false) {
    if (milestones == address(0) || forecasting == address(0)) {
      throw;
    }

    if (reviewHours == 0 || forecastHours == 0) {
      throw;
    }

    startTimestamp = block.timestamp;
  }

  /*
    Set review hours.
    ToDo: Maximum review hours. And
  */
  function setReviewHours(uint _reviewHours) onlyOwner() isStarted(false) checkReviewHours(_reviewHours) {
    reviewHours = _reviewHours;
  }

  /*
    Update project data
  */
  function update(bytes32 _infoHash, uint _category) onlyOwner() isStarted(true) onlyReview() {
    if (_category > 5) {
      throw;
    }

    infoHash = _infoHash;
    category = _category;
  }

  /*
    Milestones
  */

  /*
    Enable milestones
  */
  function enableMilestones() onlyOwner() isStarted(false) {
    milestones = new BasicMilestones();
  }

  /*
    Add milestone
  */
  function addMilestone(uint amount, bytes32 data) onlyOwner() isStarted(true) onlyReview() {
    milestones.add(amount, data);
  }

  /*
    Update milestone
  */
  function updateMilestone(uint index, uint amount, bytes32 data) onlyOwner() isStarted(true) onlyReview() {
    milestones.update(index, amount, data);
  }

  /*
    Remove milestone
  */
  function removeMilestone(uint index) onlyOwner() isStarted(true) onlyReview() {
    milestones.remove(index);
  }

  /*
    Get milestone
  */
  function getMilestone(uint index) constant returns (uint _amount, bytes32 _items, bool _completed) {
    return milestones.get(index);
  }

  /*
    Get milestones count
  */
  function getMilestonesCount() constant returns (uint _count) {
    return milestones.milestonesCount();
  }


  /*
    Forecasts
  */
  function setForecastHours(uint _forecastHours) onlyOwner() isStarted(false) checkForecastHours(_forecastHours) {
    forecastHours = _forecastHours;
  }

  /*
    Enable forecasts
  */
  function enableForecasts() onlyOwner() isStarted(false) {
    forecasting = new BasicForecasting();
  }

  /*
    Add forecast
  */
  function addForecast(uint _amount, bytes32 _message) onlyOwner() isStarted(true) onlyForecasting() {
    if (underCap) {
      var milestonesSum = milestones.getTotalAmount();

      if (milestonesSum < _amount) {
        throw;
      }
    }

    forecasting.add(msg.sender, _amount, _message);
  }

  /*
    Get user forecast
  */
  function getUserForecast(address _user) constant returns (uint _amount, uint _timestamp, bytes32 _message) {
    return forecasting.getByUser(_user);
  }

  /*
    Get forecast
  */
  function getForecast(uint _index) constant returns (uint _amount, uint _timestamp, bytes32 _message) {
    return forecasting.get(_index);
  }

  /*
    Get forecasts count
  */
  function getForecastsCount() constant returns (uint _count) {
    return forecasting.forecastsCount();
  }
}
