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

  /*
    Update project data
  */
  function update(bytes32 _infoHash) onlyOwner() inTime();
}
