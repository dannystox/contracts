pragma solidity ^0.4.2;

import "../zeppelin/Ownable.sol"

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

  /*
    Contracts
  */
  address comments;
  //address milestones;
  //address forecasting;
  //address crowdsale;

  function DAO(string _name, bytes32 _infoHash, Categories _category);

  /*
    Get Comments Contract
  */
  function getComments() returns constant (address _comments);

  /*
    Update project data
  */
  function update(bytes32 _infoHash, Categories _category) onlyOwner();
}
