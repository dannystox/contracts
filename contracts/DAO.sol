pragma solidity ^0.4.2;

import "./DAOAbstraction.sol";
import "./milestones/BasicMilestones.sol";
import "./forecasts/BasicForecasting.sol";

contract DAO is DAOAbstraction {
  event PUBLISH(bytes32 indexed id, bytes32 _infoHash);
  event UPDATE(bytes32 indexed id, bytes32 _infoHash);

  function DAO(
      address _owner,
      string _name,
      bytes32 _infoHash,
      bool _underCap,
      uint _reviewHours,
      address _token) checkReviewHours(_reviewHours) {
        owner = _owner;
        id = sha256(_name);
        name = _name;
        infoHash = _infoHash;
        timestamp = block.timestamp;
        underCap = _underCap;
        reviewHours = _reviewHours;
        token = _token;

        milestones = new BasicMilestones(msg.sender, _underCap);
  }

  /*
    Start DAO process
  */
  function start(uint _forecastHours, uint _rewardPercent) onlyOwner() isStarted(false) checkForecastHours(_forecastHours) {
    if (underCap && milestones.milestonesCount() < 1) {
      throw;
    }

    startTimestamp = block.timestamp;
    forecastHours = _forecastHours;

    uint _startTimestamp = startTimestamp + (reviewHours * 1 hours);
    uint _endTimestamp = _startTimestamp + _forecastHours * 1 hours;
    forecasting = new BasicForecasting(_startTimestamp, _endTimestamp, _rewardPercent, token, milestones, underCap);

    milestones.setLimitations(startTimestamp, startTimestamp + reviewHours * 1 hours);
    PUBLISH(id, infoHash);
  }

  /*
    Update project data
  */
  function update(bytes32 _infoHash) onlyOwner() onlyReview() {
    infoHash = _infoHash;
    UPDATE(id, infoHash);
  }
}
