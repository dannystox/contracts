/*
  Abstraction comment contract
*/
pragma solidity ^0.4.2;

contract CommentInterface {
    /*
      Comment structure
    */
    struct Comment {
      address author;
      bytes32 data;
      bytes32 projectId;
      uint timestamp;
    }

    /*
      Commentaries list
    */
    public mapping(bytes32 => mapping(uint => Comment)) comments;

    /*
      Count of comments for specific project
    */
    public mapping(bytes32 => uint) commentsCount;

    /*
      Add comment
    */
    function addComment(bytes32 data, bytes32 projectId);

    /*
      Get comments count for specific project
    */
    function getCommentsCount(bytes32) constant returns (uint);

    /*
      Get speific comment by project id and index of comment
    */
    function getComment(bytes32 projectId, uint index) constant returns (address, bytes32, bytes32, uint);
}
