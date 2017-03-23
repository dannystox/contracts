/*
  Basic Milestone implementation
*/
pragma solidity ^0.4.2;

import "./MilestonesAbstraction.sol";

contract BasicMilestones is MilestonesAbstraction {
  function BasicMilestones(address _owner) {
    owner = _owner;
    parent = msg.sender;
    maxCount = 10;
  }

  /*
    Set time when it's possible to start adding milestones and when it's not possible.
  */
  function setLimitations(uint _startTimestamp, uint _endTimestamp) onlyOwner() beforeTime() {
    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
  }

  /*
    Adding milestones
  */
  function add(uint amount, bytes32 items) onlyOwner() inTime() {
    if (milestonesCount == maxCount || amount < 1) {
      throw;
    }

    var milestone = Milestone(block.timestamp, block.timestamp, amount, items, false);
    milestones[milestonesCount++] = milestone;
  }

  /*
    Updating milestones
  */
  function update(uint index, uint amount, bytes32 items) onlyOwner() inTime() {
    if (amount < 1) {
      throw;
    }

    var milestone = milestones[index];
    milestone.amount = amount;
    milestone.items = items;
    milestone.updated_at = block.timestamp;
  }

  /*
    Removing milestones
  */
  function remove(uint index) onlyOwner() inTime() {
    if (index > milestonesCount) {
      throw;
    }

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
  function get(uint index) constant returns (uint _amount, bytes32 _items, bool _completed) {
    var milestone = milestones[index];

    return (milestone.amount, milestone.items, milestone.completed);
  }

  /*
    Get milestones sum
  */
  function getTotalAmount() constant returns (uint _amount) {
    uint sum = 0;

    for (var i = 0; i < milestonesCount; i++) {
      sum += milestones[i].amount;
    }

    return sum;
  }
}
