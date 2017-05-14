pragma solidity ^0.4.8;

import "../Factory.sol";
import "./BasicForecasting.sol";

contract ForecastingFactory is Factory {
  function create(
      uint _startTimestamp,
      uint _endTimestamp,
      uint _rewardPercent,
      address _token,
      address _milestones,
      address _crowdsale,
      bool _cap
    ) public returns (address) {
      var forecasting = new BasicForecasting(
          _startTimestamp,
          _endTimestamp,
          _rewardPercent,
          _token,
          _milestones,
          _crowdsale,
          _cap
        );

      register(forecasting);

      return forecasting;
  }
}
