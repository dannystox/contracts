pragma solidity ^0.4.8;

import "../Factory.sol";
import "./BasicForecasting.sol";

contract ForecastingFactory is Factory {
  function create(
      uint _rewardPercent,
      address _milestones,
      address _crowdsale
    ) public returns (address) {
      var forecasting = new BasicForecasting(
          timeManager,
          _rewardPercent,
          token,
          _milestones,
          _crowdsale
        );

      register(forecasting);

      return forecasting;
  }
}
