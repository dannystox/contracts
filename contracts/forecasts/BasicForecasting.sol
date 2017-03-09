pragma solidity ^0.4.2;

import "./ForecastingAbstraction.sol";

contract BasicForecasting is ForecastingAbstraction {
  /*
    Add forecast
  */
  function add(address _creator, uint _amount, bytes32 _message) onlyOwner() {
    if (userForecasts[_creator].owner != address(0)) {
      throw;
    }

    var forecast = Forecast(
      _creator,
      _amount,
      block.timestamp,
      _message
    );

    forecasts[forecastsCount] = forecast;
    userForecasts[_creator] = forecast;
    forecastsCount++;
  }

  /*
    Get user forecast
  */
  function getByUser(address _user) constant returns (uint _amount, uint _timestamp, bytes32 _message) {
    Forecast forecast = userForecasts[_user];

    return (forecast.amount, forecast.timestamp, forecast.message);
  }

  /*
    Get forecast
  */
  function get(uint _index) constant returns (uint _amount, uint _timestamp, bytes32 _message) {
    var forecast = forecasts[_index];

    return (forecast.amount, forecast.timestamp, forecast.message);
  }

  /*
    Get forecasts count
  */
  function getTotalCount() constant returns (uint _count) {
    return forecastsCount;
  }
}
