pragma solidity ^0.4.2;

import './DAOAbstraction.sol';
import './comments/BasicComments.sol';
import './milestones/BasicMilestones.sol';
import './forecasts/BasicForecasting.sol';

contract DAO is DAOAbstraction {
  modifier isStarted(bool _value) {
    if (_value == true) {
      if (startTimestamp == 0) {
        throw;
      }

      _;
    } else {
      if (startTimestamp == 0) {
        _;
      }

      throw;
    }
  }

  modifier onlyReview() {
    if (block.timestamp < (startTimestamp + (reviewHours * 1 hours))) {
      _;
    }
  }

  modifier onlyForecasting() {
    if (block.timestamp < (startTimestamp + (reviewHours + forecastHours) * 1 hours) {
      _;
    }
  }

  function DAO(address _owner, string _name, bytes32 _infoHash, Categories _category, bool _underCap) {
    owner = _owner;
    projectId = sha256(_name);
    name = _name;
    infoHash = _infoHash;
    category = _category;
    creator = msg.sender;
    timestamp = block.timestamp;
    underCap = _underCap;
  }

  /*
    Start DAO process
  */
  function start() onlyOwner() isStarted(false) {
    if (comments == address(0) || milestones == address(0) || forecasting == address(0)) {
      throw;
    }

    if (reviewHours == 0 || forecastHours == 0) {

    }

    startTimestamp = block.number;
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
  function getReviewHours() constant returns (uint _reviewHours) {
    return _reviewHours;
  }

  /*
    Update project data
  */
  function update(bytes32 _infoHash, Categories _category) onlyOwner() isStarted(true) onlyReview() {
    infoHash = _infoHash;
    category = _category;
  }

  /*
    Comments
  */

  /*
    Get comments contract
  */
  function getCommentsContract() constant returns (address _comments) {
    return comments;
  }

  /*
    Enable comments contract
  */
  function enableComments() onlyOwner() isStarted(false) {
    comments = new BasicComment()
  }

  /*
    Add comment
  */
  function addComment(bytes32 _data) isStarted(true) {
    comments.addComment(msg.sender, _data);
  }

  /*
    Get comments count for specific project
  */
  function getCommentsCount() constant returns (uint _count) {
    comments.getCommentsCount();
  }

  /*
    Get speific comment by project id and index of comment
  */
  function getComment(uint index) constant returns (address _creator, uint _timestamp, bytes32 _data) {
    return comments.getComment(index);
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
    Get Milestones Contract
  */
  function getMilestonesContract() constant returns (address _milestones) {
    return milestones;
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
  function enableForecasts() onlyOwner() isStarted(false) {
    forecasting = new BasicForecasting()
  }

  /*
    Add forecast
  */
  addForecast(uint _amount, bytes32 _message) onlyOwner() isStarted(true) onlyForecasting() {
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
