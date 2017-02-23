/*
  Abstraction comment contract

  ToDo: Add comments storage
*/
pragma solidity ^0.4.2;

contract CommentAbstraction {
    /*
      Storage
    */
    address storage;

    /*
      Creator
    */
    address creator;

    /*
      Modifiers
    */
    modifier onlyCreator {
      if (msg.sender == creator) {
        _;
      }
    }

    /*
      Comments Storage
    */
    function CommentAbstraction(address _storage) {
      storage = _storage;
      creator = msg.sender;
    }

    /*
      Change storage
    */
    function changeStorage(address newStorage) onlyCreator  {
      storage = newStorage;
    }

    /*
      Add comment
    */
    function addComment(bytes32 projectId, bytes32 data);

    /*
      Get comments count for specific project
    */
    function getCommentsCount(bytes32 projectId) constant returns (uint);

    /*
      Get speific comment by project id and index of comment
    */
    function getComment(bytes32 projectId, uint index) constant returns (address, bytes32, bytes32, uint);
}
