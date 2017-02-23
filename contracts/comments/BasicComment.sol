pragma solidity ^0.4.2;

import "./CommentAbstraction.sol";
import "../storage/Storage.sol";

contract BasicComment is CommentAbstraction {
  function BasicComment(address _storageAddress) {
    storageAddress = _storageAddress;
  }

  function addComment(bytes32 projectId, bytes32 data) {
    var dataStorage = Storage(storageAddress);
    var count = dataStorage.getUIntValue(sha3(projectId, "count"));

    dataStorage.setAddressValue(sha3(projectId, count, "address"), tx.origin);
    dataStorage.setBytesValue(sha3(projectId, count, "data"), data);
    dataStorage.setUIntValue(sha3(projectId, count, "timestamp"), block.timestamp);

    dataStorage.setUIntValue(sha3(projectId, "count"), count+1);
  }

  function getCommentsCount(bytes32 projectId) constant returns (uint) {
    var dataStorage = Storage(storageAddress);
    return dataStorage.getUIntValue(sha3(projectId, "count"));
  }

  function getComment(bytes32 projectId, uint index) constant returns (address, bytes32, bytes32, uint) {
    var dataStorage = Storage(storageAddress);

    var author = dataStorage.getAddressValue(sha3(projectId, index, "address"));
    var data = dataStorage.getBytesValue(sha3(projectId, index, "data"));
    var timestamp = dataStorage.getUIntValue(sha3(projectId, index, "timestamp"));

    return (author, data, projectId, timestamp);
  }
}
