/*
  Basic milestones contract
*/
pragma solidity ^0.4.2;

import "../zeppelin/Ownable.sol";

contract MilestonesAbstraction is Ownable {
    /*
      Milestone structure
    */
    struct Milestone {
      uint timestamp;
      uint updated_at;

      uint amount;
      bytes32 items;
      bool completed;
    }

    /*
      List of milestones
    */
    mapping(uint => Milestone) milestones;

    /*
      Milestones count
    */
    uint milestonesCount;

    /*
      Max count of milestones
    */
    uint maxCount;

    /*
      Adding milestones
    */
    function add(uint amount, bytes32 items) onlyOwner();

    /*
      Updating milestones
    */
    function update(uint index, uint amount, bytes32 items) onlyOwner();

    /*
      Removing milestones
    */
    function remove(uint index) onlyOwner();

    /*
      Completing milestone.
      Temporary version.
      ToDo: Use forecast consensus to complete milestones
    */
    function complete(uint index) onlyOwner();

    /*
      Get milestone by index
    */
    function get(uint index) constant returns (uint _amount, bytes32 _items, bool _completed);

    /*
      Get total milestones count
    */
    function getTotalCount() constant returns (uint _count);

    /*
      Get milestones sum
    */
    function getTotalAmount() constant returns (uint _amount);
}
