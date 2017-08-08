pragma solidity ^0.4.11;

import "../Forecasting.sol";

contract ForecastingFactory {
  address public token;

  function ForecastingFactory(address _token) {
    token = _token;
  }

  function create(
      address _timeManager,
      uint _rewardPercent,
      address _milestones,
      address _crowdsale
    ) public returns (address) {
      var forecasting = new Forecasting(
          _timeManager,
          _rewardPercent,
          token,
          _milestones,
          _crowdsale
        );

      return forecasting;
  }
}
