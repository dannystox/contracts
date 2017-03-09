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

  address creator; // creator of the projects
  bytes32 id; // id of project
  string name; // name of project
  bytes32 infoHash; // information hash of project

  uint category; // category of project

  uint timestamp; // timestamp when project created

  uint reviewHours; // review period of project
  uint forecastHours; // forecasting hours

  bool underCap; // is project under cap and latest milestone is cap
  uint startTimestamp; // time of DAO start activity

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
    Get review hours
  */
  function getReviewHours() constant returns (uint _reviewHours);

  /*
    Set forecast hours
  */
  function setForecastHours(uint _forecastHours) onlyOwner() isStarted(false);

  /*
    Get forecast hours
  */
  function getForecastHours() constant returns (uint _forecastHours);

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
    Get Comments Contract
  */
  function getCommentsContract() constant returns (address _comments);

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
    Get Milestones Contract
  */
  function getMilestonesContract() constant returns (address _milestones);

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
    Get Forecast Contract
  */
  function getForecastsContract() constant returns (address _comments);

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
