/*
  Basic Comment implementation
*/
pragma solidity ^0.4.2;

import "./CommentAbstraction.sol";

contract BasicComment is CommentAbstraction {
  function addComment(bytes32 data) {
    var comment = Comment(
        msg.sender,
        block.timestamp,
        data
      )

    comments[commentsCount] = comment;
    commentsCount += 1;
  }

  function getCommentsCount(bytes32 projectId) constant returns (uint _count) {
    return commentsCount;
  }

  function getComment(uint index) constant returns (address _creator, uint _timestamp, bytes32 _data) {
    var comment = comments[index];

    return (comment.creator, comment.timestamp, comment.data);
  }
}
