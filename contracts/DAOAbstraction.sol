pragma solidity ^0.4.2;

import "./zeppelin/Ownable.sol";
import "./comments/CommentsAbstraction.sol";
import "./milestones/MilestonesAbstraction.sol";
import "./forecasts/ForecastingAbstraction.sol";

contract DAOAbstraction is Ownable {
  /*
    Project Categories
  */
  enum Categories {
    Software,
    Hardware,
    Service,
    Platform,
    NonProfit
  }

  /*
    Projects Periods
  */
  enum ProjectPeriod {
    Review,
    Forecasting,
    Funding,
    AfterFunding
  }

  address public creator; // creator of the projects
  bytes32 public id; // id of project
  string public name; // name of project
  bytes32 public infoHash; // information hash of project

  uint public category; // category of project

  uint public timestamp; // timestamp when project created

  uint public reviewHours; // review period of project
  uint public forecastHours; // forecasting hours

  bool public underCap; // is project under cap and latest milestone is cap
  uint public startTimestamp; // time of DAO start activity

  /*
    Contracts
  */
  CommentsAbstraction comments;
  MilestonesAbstraction milestones;
  ForecastingAbstraction forecasting;
  //address crowdsale;

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
    if (block.timestamp < (startTimestamp + (reviewHours + forecastHours) * 1 hours)) {
      _;
    }
  }

  /*
    Set review hours
  */
  function setReviewHours(uint _reviewHours) onlyOwner();

  /*
    Set forecast hours
  */
  function setForecastHours(uint _forecastHours) onlyOwner() isStarted(false);

  /*
    Update project data
  */
  function update(bytes32 _infoHash, uint _category) onlyOwner() isStarted(true) onlyReview();

  /*
    Start DAO process
  */
  function start() onlyOwner() isStarted(false);

  /*
    Comments
  */

  /*
    Enable comments
  */
  function enableComments() onlyOwner() isStarted(false);

  /*
    Add comment
  */
  function addComment(bytes32 _data) isStarted(true);

  /*
    Get comments count for specific project
  */
  function getCommentsCount() constant returns (uint _count);

  /*
    Get speific comment by project id and index of comment
  */
  function getComment(uint index) constant returns (address _creator, uint _timestamp, bytes32 _data);

  /*
    Milestones
  */

  /*
    Enable milestones
  */
  function enableMilestones() onlyOwner() isStarted(false);

  /*
    Add milestone
  */
  function addMilestone(uint amount, bytes32 data) onlyOwner() isStarted(true) onlyReview();

  /*
    Update milestone
  */
  function updateMilestone(uint index, uint amount, bytes32 data) onlyOwner() isStarted(true) onlyReview();

  /*
    Remove milestone
  */
  function removeMilestone(uint index) onlyOwner() isStarted(true) onlyReview();

  /*
    Get milestone
  */
  function getMilestone(uint index) constant returns (uint _amount, bytes32 _items, bool _completed);

  /*
    Get milestones count
  */
  function getMilestonesCount() constant returns (uint _count);


  /*
    Forecasts
  */

  /*
    Enable forecasts
  */
  function enableForecasts() onlyOwner() isStarted(false);

  /*
    Add forecast
  */
  function addForecast(uint _amount, bytes32 _message) onlyOwner() isStarted(true) onlyForecasting();

  /*
    Get user forecast
  */
  function getUserForecast(address _user) constant returns (uint _amount, uint _timestamp, bytes32 _message);

  /*
    Get forecast
  */
  function getForecast(uint _index) constant returns (uint _amount, uint _timestamp, bytes32 _message);

  /*
    Get forecasts count
  */
  function getForecastsCount() constant returns (uint _count);


}
