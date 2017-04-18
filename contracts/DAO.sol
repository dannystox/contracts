pragma solidity ^0.4.2;

import "./DAOAbstraction.sol";
import "./milestones/BasicMilestones.sol";
import "./forecasts/BasicForecasting.sol";
import "./crowdsales/BasicCrowdsale.sol";

contract DAO is DAOAbstraction {
  function DAO(
      address _owner,
      string _name,
      string _symbol,
      bytes32 _infoHash,
      bool _underCap,
      uint _reviewHours,
      address _token) checkReviewHours(_reviewHours) {
        owner = _owner;
        id = sha256(_name);
        name = _name;
        symbol = _symbol;
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
  function start(
      uint _forecastHours,
      uint _crowdsaleHours,
      address _multisig,
      uint _initialPrice,
      uint _rewardPercent
    ) onlyOwner() isStarted(false) checkForecastHours(_forecastHours) checkCrowdsaleHours(_crowdsaleHours) {
      if (underCap && milestones.milestonesCount() < 1) {
        throw;
      }

      startTimestamp = block.timestamp;
      forecastHours = _forecastHours;

      uint _startTimestamp = startTimestamp + (reviewHours * 1 hours);
      uint _endTimestamp = _startTimestamp + _forecastHours * 1 hours;

      crowdsale = new BasicCrowdsale(msg.sender, this, _multisig, name, symbol, milestones, _initialPrice, rewardPercent);
      forecasting = new BasicForecasting(_startTimestamp, _endTimestamp, rewardPercent, token, milestones, crowdsale, underCap);

      crowdsale.setForecasting(forecasting);
      crowdsale.setLimitations(_startTimestamp, _endTimestamp, (_endTimestamp + (_crowdsaleHours * 1 hours)));

      milestones.setLimitations(startTimestamp, startTimestamp + reviewHours * 1 hours);
  }

  /*
    Update project data
  */
  function update(bytes32 _infoHash) onlyOwner() onlyReview() {
    infoHash = _infoHash;
  }

}
