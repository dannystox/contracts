pragma solidity ^0.4.2;

import "../zeppelin/Ownable.sol";

contract ForecastingAbstraction is Ownable {
  struct Forecast {
    address owner;
    uint amount;
    uint timestamp;
    bytes32 message;
  }

  mapping(uint => Forecast) forecasts;
  mapping(address => Forecast) userForecasts;

  uint forecastsCount;

  /*
    Add forecast
  */
  function add(address _creator, uint _amount, bytes32 _message) onlyOwner();

  /*
    Get user forecast
  */
  function getByUser(address _user) constant returns (uint _amount, uint _timestamp, bytes32 _message);

  /*
    Get forecast
  */
  function get(uint _index) constant returns (uint _amount, uint _timestamp, bytes32 _message);

  /*
    Get forecasts count
  */
  function getTotalCount() constant returns (uint _count);
}
