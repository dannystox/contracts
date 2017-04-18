pragma solidity ^0.4.8;

import "../zeppelin/Ownable.sol";
import "../zeppelin/SafeMath.sol";

/*
  Basic milestones contract
*/
contract MilestonesAbstraction is Ownable, SafeMath {
    modifier onlyParent() {
      if (msg.sender == parent) {
        _;
      } else {
        throw;
      }
    }

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

    modifier beforeTime {
      if (startTimestamp == 0 && endTimestamp == 0) {
        _;
      } else {
        throw;
      }
    }

    modifier inTime {
      if (startTimestamp == 0 || (block.timestamp > (startTimestamp) && block.timestamp < endTimestamp)) {
        _;
      } else {
        throw;
      }
    }

    /*
      List of milestones
    */
    mapping(uint => Milestone) public milestones;

    /*
      Milestones count
    */
    uint public milestonesCount;

    /*
      When we allow to add milestones
    */
    uint public startTimestamp;

    /*
      When we doesnt allow to add milestones
    */
    uint public endTimestamp;

    /*
      Address of parent contract or parent creator
    */
    address public parent;

    /*
      Max count of milestones
    */
    uint public MAX_COUNT = 10;

    /*
      Is we under cap
    */
    bool public cap;

    /*
      Total amount
    */
    uint public totalAmount;

    /*
      Set time when it's possible to start adding milestones and when it's not possible.
    */
    function setLimitations(uint _startTimestamp, uint _endTimestamp) onlyParent() beforeTime();

    /*
      Adding milestones
    */
    function add(uint amount, bytes32 items) onlyOwner() inTime();

    /*
      Updating milestones
    */
    function update(uint index, uint amount, bytes32 items) onlyOwner() inTime();

    /*
      Removing milestones
    */
    function remove(uint index) onlyOwner() inTime();

    /*
      Completing milestone.
      Temporary version.
      ToDo: Use forecast consensus to complete milestones
    */
    function complete(uint index) onlyOwner();

    /*
      Get milestone by index
    */
    function get(uint index) constant returns (uint, bytes32, bool);
}
