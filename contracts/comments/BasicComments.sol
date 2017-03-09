/*
  Basic Comment implementation
*/
pragma solidity ^0.4.2;

import "./CommentAbstraction.sol";

contract BasicComments is CommentsAbstraction {
  function addComment(address _sender, bytes32 _data) onlyOwner()  {
    var comment = Comment(
        sender,
        block.timestamp,
        data
      )

    comments[commentsCount] = comment;
    commentsCount += 1;
  }

  function getCommentsCount() constant returns (uint _count) {
    return commentsCount;
  }

  function getComment(uint index) constant returns (address _creator, uint _timestamp, bytes32 _data) {
    var comment = comments[index];

    return (comment.creator, comment.timestamp, comment.data);
  }
}
