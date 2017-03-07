pragma solidity ^0.4.2;

import './DAOAbstraction.sol';
import './comments/BasicComments.sol';
import './milestones/BasicMilestones.sol';

contract DAO is DAOAbstraction {
  modifier onlyReview() {
    if (reviewHours < 1) {
      throw;
    }

    if (block.timestamp < (timestamp + reviewHours * 1 hours)) {
      _;
    }
  }


  function DAO(string _name, bytes32 _infoHash, Categories _category) {
    projectId = sha256(_name);
    name = _name;
    infoHash = _infoHash;
    category = _category;
    creator = msg.sender;
    timestamp = block.timestamp;
  }

  /*
    Set review hours
  */
  function setReviewHours(uint _reviewHours) onlyOwner() {
    if (reviewHours > 0 || _reviewHours < 1) {
      throw;
    }

    reviewHours = _reviewHours;
  }

  /*
    Get review hours
  */
  function getReviewHours() returns constant (uint _reviewHours) {
    return _reviewHours;
  }

  /*
    Update project data
  */
  function update(bytes32 _infoHash, Categories _category) onlyOwner() onlyReview() {
    infoHash = _infoHash;
    category = _category;
  }

  /*
    Comments
  */

  /*
    Get comments contract
  */
  function getCommentsContract() returns constant (address _comments) {
    return comments;
  }

  function enableComments() onlyOwner() {
    comments = new BasicComment()
  }


  /*
    Milestones
  */

  /*
    Enable milestones
  */
  function enableMilestones() onlyOwner() onlyReview() {
    milestones = new BasicMilestones();
  }


  /*
    Get Milestones Contract
  */
  function getMilestonesContract() returns constant (address _milestones) {
    return milestones;
  }

  /*
    Add milestone
  */
  function addMilestone(uint amount, bytes32 data) onlyOwner() onlyReview() {
    milestones.add(amount, data);
  }

  /*
    Update milestone
  */
  function updateMilestone(uint index, uint amount, bytes32 data) onlyOwner() onlyReview() {
    milestones.update(index, amount, data);
  }

  /*
    Remove milestone
  */
  function removeMilestone(uint index) onlyOwner() onlyReview() {
    milestones.remove(index);
  }

  /*
    Get milestone
  */
  function getMilestone(uint index) constant returns (uint _amount, bytes32 _items, bool _completed) {
    return milestones.get(index);
  }

  /*
    Get milestones count
  */
  function getMilestonesCount() constant returns (uint _count) {
    return milestones.getTotalCount();
  }
}
