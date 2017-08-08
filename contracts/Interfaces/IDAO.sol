pragma solidity ^0.4.11;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../helpers/Temporary.sol";

contract IDAO is Ownable, Temporary  {
  bytes32 public id; // id of project
  bytes32 public infoHash; // information hash of project

  /*
    Contracts
  */
  address public milestones;
  address public forecasting;
  address public crowdsale;

  modifier checkReviewHours(uint _hours) {
    require(_hours > 1);
    require(_hours < 504);
    _;
  }

  modifier checkForecastHours(uint _hours) {
    require(_hours >= 120);
    require(_hours < 720);
    _;
  }

  modifier checkCrowdsaleHours(uint _hours) {
    require(_hours >= 168);
    require(_hours < 2016);
    _;
  }

  /*
    Update project data
  */
  function update(bytes32 _infoHash) public onlyOwner() inTime();
}
