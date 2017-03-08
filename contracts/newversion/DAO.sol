pragma solidity ^0.4.2;

import './DAOAbstraction.sol';
import './comments/BasicComments.sol';
import './milestones/BasicMilestones.sol';
import './forecasts/BasicForecasting.sol';

contract DAO is DAOAbstraction {
  modifier onlyReview() {
    if (reviewHours < 1) {
      throw;
    }

    if (block.timestamp < (timestamp + reviewHours * 1 hours)) {
      _;
    }
  }

  modifier onlyForecasting() {
    if (forecastHours < 1 || forecasting == address(0)) {
      throw;
    }

    if (block.timestamp < (timestamp + (reviewHours + forecastHours) * 1 hours) {
      _;
    }
  }


  function DAO(string _name, bytes32 _infoHash, Categories _category, bool _underCap) {
    projectId = sha256(_name);
    name = _name;
    infoHash = _infoHash;
    category = _category;
    creator = msg.sender;
    timestamp = block.timestamp;
    underCap = _underCap;
  }

  /*
    Set review hours
  */
  function setReviewHours(uint _reviewHours) onlyOwner() {
    if (reviewHours > 0 || _reviewHours < 1) {
      throw;
    }

    reviewHours = _reviewHours;
  }

  /*
    Get review hours
  */
  function getReviewHours() returns constant (uint _reviewHours) {
    return _reviewHours;
  }

  /*
    Update project data
  */
  function update(bytes32 _infoHash, Categories _category) onlyOwner() onlyReview() {
    infoHash = _infoHash;
    category = _category;
  }

  /*
    Comments
  */

  /*
    Get comments contract
  */
  function getCommentsContract() returns constant (address _comments) {
    return comments;
  }

  function enableComments() onlyOwner() {
    comments = new BasicComment()
  }


  /*
    Milestones
  */

  /*
    Enable milestones
  */
  function enableMilestones() onlyOwner() onlyReview() {
    milestones = new BasicMilestones();
  }


  /*
    Get Milestones Contract
  */
  function getMilestonesContract() returns constant (address _milestones) {
    return milestones;
  }

  /*
    Add milestone
  */
  function addMilestone(uint amount, bytes32 data) onlyOwner() onlyReview() {
    milestones.add(amount, data);
  }

  /*
    Update milestone
  */
  function updateMilestone(uint index, uint amount, bytes32 data) onlyOwner() onlyReview() {
    milestones.update(index, amount, data);
  }

  /*
    Remove milestone
  */
  function removeMilestone(uint index) onlyOwner() onlyReview() {
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
    return milestones.getTotalCount();
  }


  /*
    Forecasts
  */

  /*
    Get Forecast Contract
  */
  function getForecastsContract() returns constant (address _comments) {
    return forecasting;
  };

  /*
    Enable forecasts
  */
  function enableForecasts() onlyOwner() onlyForecasting() {
    forecasting = new BasicForecasting()
  }

  /*
    Add forecast
  */
  addForecast(uint _amount, bytes32 _message) onlyOwner() onlyForecasting() {
    if (underCap) {
      var milestonesSum = milestones.getTotalAmount();

      if (milestonesSum < _amount) {
        throw;
      }
    }

    forecasting.addForecast(msg.sender, _amount, _message);
  }

  /*
    Get user forecast
  */
  getUserForecast(address _user) returns constant (uint _amount, uint _timestamp, bytes32 _message) {
    return forecasting.getUserForecast(_user);
  }

  /*
    Get forecast
  */
  getForecast(uint _index) returns constant (uint _amount, uint _timestamp, bytes32 _message) {
    return forecasting.get(_index);
  }

  /*
    Get forecasts count
  */
  getForecastsCount() returns constant (uint _count) {
    return forecasting.getTotalCount();
  }
}
