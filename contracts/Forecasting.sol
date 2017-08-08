pragma solidity ^0.4.11;

import "./interfaces/IForecasting.sol";
import "./interfaces/IMilestones.sol";

contract Forecasting is IForecasting {
  event ADD_FORECAST(address indexed account, uint amount, address forecast);
  /*
    Lock tokens here in forecast contract?
  */
  function Forecasting(address _timeManager,
                            uint _rewardPercent,
                            address _token,
                            address _milestones,
                            address _crowdsale
                          ) isValidRewardPercent(_rewardPercent) {
    timeManager = _timeManager;
    rewardPercent = _rewardPercent;
    token = ERC20(_token);
    milestones = IMilestones(_milestones);
    crowdsale = _crowdsale;
  }

  /*
    Add forecast
    ToDo: We should check maximum amount of forecasting
  */
  function add(uint _amount, bytes32 _message) inTime() {
    if (milestones.cap() == true) {
        if (max == 0) {
          max = milestones.totalAmount();
        }

        require(max < _amount);
    }

    /*
      Should allow us to lock Wings tokens.
    */
    require(userForecasts[msg.sender].owner == address(0));

    var forecast = Forecast(
      msg.sender,
      _amount,
      block.timestamp,
      _message
    );

    forecasts[forecastsCount++] = forecast;
    userForecasts[msg.sender] = forecast;

    ADD_FORECAST(msg.sender, _amount, address(this));
  }

  /*
    Get user forecast
  */
  function getByUser(address _user) constant returns (uint, uint, bytes32) {
    var forecast = userForecasts[_user];

    return (forecast.amount, forecast.created_at, forecast.message);
  }

  /*
    Get forecast
  */
  function get(uint _index) constant returns (address, uint, uint, bytes32) {
    var forecast = forecasts[_index];

    return (forecast.owner, forecast.amount, forecast.created_at, forecast.message);
  }
}
