pragma solidity ^0.4.2;

import "../zeppelin/Ownable.sol";
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

  Categories category; // category of project

  uint timestamp; // timestamp when project created

  uint reviewHours; // review period of project
  uint forecastHours; // forecasting hours

  bool underCap; // is project under cap and latest milestone is cap
  bool startTimestamp; // time of DAO start activity

  /*
    Contracts
  */
  CommentAsbstraction comments;
  MilestonesAbstraction milestones;
  ForecastAbstraction forecasting;
  //address crowdsale;

  modifier onlyReview();
  modifier onlyForecasting();
  modifier isStarted(bool _value);

  function DAO(string _name, bytes32 _infoHash, Categories _category, bool _underCap);

  /*
    Set review hours
  */
  function setReviewHours(uint _reviewHours) onlyOwner();

  /*
    Get review hours
  */
  function getReviewHours() returns constant (uint _reviewHours);

  /*
    Set forecast hours
  */
  function setForecastHours(uint _forecastHours) onlyOwner();

  /*
    Get forecast hours
  */
  function getForecastHours() returns (uint _forecastHours);

  /*
    Update project data
  */
  function update(bytes32 _infoHash, Categories _category) onlyOwner() isStarted(true) onlyReview();

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
  function getCommentsContract() returns constant (address _comments);

  /*
    Enable comments
  */
  function enableComments() onlyOwner() isStarted(false);


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
  function getMilestonesContract() returns constant (address _milestones);

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
  function getForecastsContract() returns constant (address _comments);

  /*
    Enable forecasts
  */
  function enableForecasts() onlyOwner() isStarted(false);

  /*
    Add forecast
  */
  addForecast(uint _amount, bytes32 _message) onlyOwner() isStarted(true) onlyForecasting();

  /*
    Get user forecast
  */
  getUserForecast(address _user) returns constant (uint _amount, uint _timestamp, bytes32 _message);

  /*
    Get forecast
  */
  getForecast(uint _index) returns constant (uint _amount, uint _timestamp, bytes32 _message);

  /*
    Get forecasts count
  */
  getForecastsCount() returns constant (uint _count);


}
