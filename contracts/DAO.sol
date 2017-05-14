pragma solidity ^0.4.8;

import "./DAOAbstraction.sol";

contract DAO is DAOAbstraction {
  function DAO(
      address _owner,
      string _name,
      string _symbol,
      bytes32 _infoHash,
      bool _underCap,
      uint _reviewHours,
      address _token,
      address _milestonesFactory,
      address _forecastingFactory,
      address _crowdsaleFactory) checkReviewHours(_reviewHours)  {
        owner = _owner;
        id = sha256(_name);
        name = _name;
        symbol = _symbol;
        infoHash = _infoHash;
        timestamp = block.timestamp;
        underCap = _underCap;
        reviewHours = _reviewHours;
        token = _token;

        milestonesFactory = MilestonesFactory(_milestonesFactory);
        forecastingFactory = ForecastingFactory(_forecastingFactory);
        crowdsaleFactory = CrowdsaleFactory(_crowdsaleFactory);

        milestones = milestonesFactory.create(_owner, _underCap);
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
    ) onlyOwner() isStarted(false) checkForecastHours(_forecastHours) {
      var milestonesInst = BasicMilestones(milestones);

      if (underCap && milestonesInst.milestonesCount() < 1) {
        throw;
      }

      startTimestamp = block.timestamp;
      forecastHours = _forecastHours;

      uint _startTimestamp = startTimestamp + (reviewHours * 1 hours);
      uint _endTimestamp = _startTimestamp + (_forecastHours * 1 hours);

      crowdsale = crowdsaleFactory.create(
          owner,
          address(this),
          _multisig,
          name,
          symbol,
          milestones,
          _initialPrice,
          _rewardPercent
        );

      forecasting = forecastingFactory.create(
          _startTimestamp,
          _endTimestamp,
          _rewardPercent,
          token,
          milestones,
          crowdsale,
          underCap
        );

      var crowdsaleInst = BasicCrowdsale(crowdsale);

      crowdsaleInst.setForecasting(forecasting);
      crowdsaleInst.setLimitations(_startTimestamp, _endTimestamp, (_endTimestamp + (_crowdsaleHours * 1 hours)));
      milestonesInst.setLimitations(startTimestamp, startTimestamp + reviewHours * 1 hours);
  }

  /*
    Update project data
  */
  function update(bytes32 _infoHash) onlyOwner() onlyReview() {
    infoHash = _infoHash;
  }

}
