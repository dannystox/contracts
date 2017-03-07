pragma solidity ^0.4.2;

import "../zeppelin/Ownable.sol";
import "./comments/CommentsAbstraction.sol";
import "./milestones/MilestonesAbstraction.sol";

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

  /*
    Contracts
  */
  Comment comments;
  Milestones milestones;
  //address forecasting;
  //address crowdsale;

  modifier onlyReview();

  function DAO(string _name, bytes32 _infoHash, Categories _category);

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
  function update(bytes32 _infoHash, Categories _category) onlyOwner() onlyReview();

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
  function enableComments() onlyOwner();


  /*
    Milestones
  */

  /*
    Enable milestones
  */
  function enableMilestones() onlyOwner() onlyReview();


  /*
    Get Milestones Contract
  */
  function getMilestonesContract() returns constant (address _milestones);

  /*
    Add milestone
  */
  function addMilestone(uint amount, bytes32 data) onlyOwner() onlyReview();

  /*
    Update milestone
  */
  function updateMilestone(uint index, uint amount, bytes32 data) onlyOwner() onlyReview();

  /*
    Remove milestone
  */
  function removeMilestone(uint index) onlyOwner() onlyReview();

  /*
    Get milestone
  */
  function getMilestone(uint index) constant returns (uint _amount, bytes32 _items, bool _completed);

  /*
    Get milestones count
  */
  function getMilestonesCount() constant returns (uint _count);
}
