pragma solidity ^0.4.11;

contract Temporary {
  uint public startTimestamp;
  uint public endTimestamp;
  address public timeManager;

  modifier inTime {
    require(startTimestamp < block.timestamp);
    require(endTimestamp > block.timestamp);
    _;
  }

  modifier before {
    require(startTimestamp == 0);
    require(endTimestamp == 0);
    _;
  }

  modifier onlyTimeManager {
    require(msg.sender == timeManager);
    _;
  }

  function setTime(uint _start, uint _end) public onlyTimeManager() before() {
    require(_start < _end);
    startTimestamp = _start;
    endTimestamp = _end;
  }
}
