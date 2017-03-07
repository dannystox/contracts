/*
  Abstraction comment contract
*/
pragma solidity ^0.4.2;

contract CommentAbstraction {
    /*
      Comment structure
    */
    struct Comment {
      address creator;
      uint timestamp;
      bytes32 data;
    }

    /*
      List of comments
    */
    mapping(uint => Comment) public comments;
    uint public commentsCount;

    /*
      Add comment
    */
    function addComment(bytes32 data);

    /*
      Get comments count for specific project
    */
    function getCommentsCount(bytes32 projectId) constant returns (uint _count);

    /*
      Get speific comment by project id and index of comment
    */
    function getComment(uint index) constant returns (address _creator, uint _timestamp, bytes32 _data);
}
