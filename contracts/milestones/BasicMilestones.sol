/*
  Basic Milestone implementation
*/
pragma solidity ^0.4.2;

import "./MilestonesAbstraction.sol";

contract BasicMilestones is MilestonesAbstraction {
  function BasicMilestones(address _owner, bool _cap) {
    owner = _owner;
    parent = msg.sender;
    cap = _cap;
  }

  /*
    Set time when it's possible to start adding milestones and when it's not possible.
  */
  function setLimitations(uint _startTimestamp, uint _endTimestamp) onlyParent() beforeTime() {
    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
  }

  /*
    Adding milestones
  */
  function add(uint amount, bytes32 items) onlyOwner() inTime() {
    if (milestonesCount == MAX_COUNT || amount < 1) {
      throw;
    }

    var milestone = Milestone(block.timestamp, block.timestamp, amount, items, false);
    milestones[milestonesCount++] = milestone;
    totalAmount = safeAdd(totalAmount, amount);
  }

  /*
    Updating milestones
  */
  function update(uint index, uint amount, bytes32 items) onlyOwner() inTime() {
    if (amount < 1) {
      throw;
    }

    var milestone = milestones[index];

    totalAmount = safeSub(totalAmount, milestone.amount);

    milestone.amount = amount;
    milestone.items = items;
    milestone.updated_at = block.timestamp;

    totalAmount = safeAdd(totalAmount, amount);
  }

  /*
    Removing milestones
  */
  function remove(uint index) onlyOwner() inTime() {
    if (cap && milestonesCount == 1) {
      throw;
    }

    if (index > milestonesCount) {
      throw;
    }

    totalAmount = safeSub(totalAmount, milestones[index].amount);

    for (var i = index; i < milestonesCount-1; i++) {
      milestones[i] = milestones[i+1];
    }

    delete milestones[milestonesCount-1];
    milestonesCount--;
  }

  /*
    Completing milestone.
    Temporary version.
    ToDo: Use forecast consensus to complete milestones
  */
  function complete(uint index) onlyOwner() {
    if (index > milestonesCount) {
      throw;
    }

    milestones[index].completed = true;
  }

  /*
    Get milestone by index
  */
  function get(uint index) constant returns (uint, bytes32, bool) {
    var milestone = milestones[index];

    return (milestone.amount, milestone.items, milestone.completed);
  }

}
