pragma solidity ^0.4.2;

import './DAOAbstraction.sol';
import './comments/BasicComment.sol'

contract DAO is DAOAbstraction {
  function DAO(string _name, bytes32 _infoHash, Categories _category) {
    projectId = sha256(_name);
    name = _name;
    infoHash = _infoHash;
    category = _category;
    creator = msg.sender;
    timestamp = block.timestamp;

    comments = new BasicComment();
  }

  function getComments() returns constant (address _comments) {
    return comments;
  }

  function update(bytes32 _infoHash, Categories _category) onlyOwner() {
    infoHash = _infoHash;
    category = _category;
  }
}
