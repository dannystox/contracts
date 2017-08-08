pragma solidity ^0.4.11;

import "./interfaces/IMilestones.sol";

/*
  Basic Milestone implementation
*/
contract Milestones is IMilestones {
  function Milestones(address _timeManager, address _owner, bool _cap) {
    timeManager = _timeManager;
    owner = _owner;
    cap = _cap;
  }

  /*
    Adding milestones
  */
  function add(uint amount, bytes32 items) onlyOwner() inTime() {
    require(milestonesCount < MAX_COUNT);
    require(amount > 0);

    var milestone = Milestone(block.timestamp, block.timestamp, amount, items, false);
    milestones[milestonesCount++] = milestone;
    totalAmount = totalAmount.add(amount);
  }

  /*
    Updating milestones
  */
  function update(uint index, uint amount, bytes32 items) onlyOwner() inTime() {
    require(amount > 0);

    var milestone = milestones[index];

    totalAmount = totalAmount.sub(milestone.amount);

    milestone.amount = amount;
    milestone.items = items;
    milestone.updated_at = block.timestamp;

    totalAmount = totalAmount.add(amount);
  }

  /*
    Removing milestones
  */
  function remove(uint index) onlyOwner() inTime() {
    if (cap) {
      require(milestonesCount > 1);
    }

    require(index < milestonesCount);

    totalAmount = totalAmount.sub(milestones[index].amount);

    for (var i = index; i < milestonesCount-1; i++) {
      milestones[i] = milestones[i+1];
    }

    delete milestones[milestonesCount-1];
    milestonesCount--;
  }

  /*
    Get milestone by index
  */
  function get(uint index) constant returns (uint, bytes32, bool) {
    var milestone = milestones[index];

    return (milestone.amount, milestone.items, milestone.completed);
  }

}
