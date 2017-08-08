pragma solidity ^0.4.11;

import "../Milestones.sol";

contract MilestonesFactory {
  address public token;

  function MilestonesFactory(address _token) {
    token = _token;
  }

  function create(address _timeManager, address _owner, bool _cap) public returns (address) {
      var milestones = new Milestones(_timeManager, _owner, _cap);
      return milestones;
  }
}
