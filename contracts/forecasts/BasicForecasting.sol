pragma solidity ^0.4.2;

import "./ForecastingAbstraction.sol";
import "../milestones/BasicMilestones.sol";

contract BasicForecasting is ForecastingAbstraction {
  /*
    Lock tokens here in forecast contract?
  */

  function BasicForecasting(uint _startTimestamp,
                           uint _endTimestamp,
                           uint _rewardPercent,
                           address _token,
                           address _milestones,
                           bool _cap) checkRewardPercent(_rewardPercent) {
    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
    rewardPercent = _rewardPercent;
    token = Token(_token);
    milestones = BasicMilestones(_milestones);
    cap = _cap;
  }

  /*
    Add forecast
    ToDo: We should check maximum amount of forecasting
  */
  function add(uint _amount, bytes32 _message) inTime() {
    if (cap) {
        if (max == 0) {
          max = milestones.totalAmount();
        }

        if (max < _amount) {
          throw;
        }
    }

    /*
      Should allow us to lock Wings tokens.
    */
    if (userForecasts[msg.sender].owner != address(0)) {
      throw;
    }

    var forecast = Forecast(
      msg.sender,
      _amount,
      block.timestamp,
      _message
    );

    forecasts[forecastsCount++] = forecast;
    userForecasts[msg.sender] = forecast;
  }

  /*
    Get user forecast
  */
  function getByUser(address _user) constant returns (uint, uint, bytes32) {
    var forecast = userForecasts[_user];

    return (forecast.amount, forecast.timestamp, forecast.message);
  }

  /*
    Get forecast
  */
  function get(uint _index) constant returns (address, uint, uint, bytes32) {
    var forecast = forecasts[_index];

    return (forecast.owner, forecast.amount, forecast.timestamp, forecast.message);
  }
}
