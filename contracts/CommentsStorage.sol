pragma solidity ^0.4.2;

contract CommentsStorage {
  /*
    Creator
  */
  address creator;

  /*
    Whitelist.
    Which contract can add comments
  */
  mapping(address => bool) whitelist;

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
  mapping(bytes32 => mapping(uint => Comment)) comments;

  /*
    Count of comments for specific project.
    Should allow to call only from Comment Abstraction
  */
  mapping(bytes32 => uint) commentsCount;

  function addComment(Comment comment) {
    var count = commentsCount[comment.projectId];

    comments[comment.projectId][count] = comment;
    commentsCount[comment.projectId] = count+1;
  }
}
