pragma solidity ^0.4.11;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

import "../helpers/Temporary.sol";

/*
  Basic milestones contract
*/
contract IMilestones is Ownable, Temporary {
    using SafeMath for uint;
    /*
      Milestone structure
    */
    struct Milestone {
      uint created_at;
      uint updated_at;

      uint amount;
      bytes32 items;
      bool completed;
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
      Get milestone by index
    */
    function get(uint index) constant returns (uint, bytes32, bool);
}
