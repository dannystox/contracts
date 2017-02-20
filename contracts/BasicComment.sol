pragma solidity ^0.4.2;

import "./CommentAbstraction.sol";

contract BasicComment is CommentAbstraction {
  function addComment(bytes32 projectId, bytes32 data) {
    var count = commentsCount[projectId]+1;
    var comment = Comment(msg.sender, data, projectId, block.timestamp);

    comments[projectId][count] = comment;
    commentsCount[projectId] = count;
  }

  function getCommentsCount(bytes32 projectId) constant returns (uint) {
    return commentsCount[projectId];
  }

  function getComment(bytes32 projectId, uint index) constant returns (address, bytes32, bytes32, uint) {
    var comment = comments[projectId][index];

    return (comment.author, comment.data, comment.projectId, comment.timestamp);
  }
}
