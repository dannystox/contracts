pragma solidity ^0.4.8;

import "../Factory.sol";
import "./BasicMilestones.sol";

contract MilestonesFactory is Factory {
  function create(
      address _owner,
      bool _cap
    ) public returns (address) {
      var milestones = new BasicMilestones(timeManager, _owner, _cap);

      register(milestones);

      return milestones;
  }
}
