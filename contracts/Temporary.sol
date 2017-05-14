pragma solidity ^0.4.8;

contract Temporary {
  uint public startTimestamp;
  uint public endTimestamp;
  address public timeManager;

  modifier inTime {
    if (startTimestamp > block.timestamp || endTimestamp < block.timestamp) {
      throw;
    }

    _;
  }

  modifier before {
    if (startTimestamp != 0 || endTimestamp != 0) {
      throw;
    }

    _;
  }

  modifier verifyTimestamps(uint _startTimestamp, uint _endTimestamp) {
    if (startTimestamp >= endTimestamp) {
      throw;
    }

    _;
  }

  modifier onlyTimeManager {
    if (msg.sender != timeManager) {
      throw;
    }

    _;
  }

  function setTime(uint _s, uint _e) before() verifyTimestamps(_s, _e) onlyTimeManager() {
    startTimestamp = _s;
    endTimestamp = _e;
  }
}
