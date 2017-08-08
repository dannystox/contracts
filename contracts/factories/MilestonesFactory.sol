pragma solidity ^0.4.11;

import "./Factory.sol";
import "../Milestones.sol";

contract MilestonesFactory is Factory {
  function create(address _timeManager, address _owner, bool _cap) public returns (address) {
      var milestones = new Milestones(_timeManager, _owner, _cap);
      return milestones;
  }
}
