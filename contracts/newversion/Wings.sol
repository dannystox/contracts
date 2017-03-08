pragma solidity ^0.4.2;

import "./DAOAbstraction.sol";
import "../zeppelin/Ownable.sol";

contract Wings is Ownable {
  /*
    DAOs
  */
  mapping(bytes32 => DAO) daos;

  /*
    DAOs ids
  */
  mapping(uint => bytes32) daosIds;

  /*
    User DAOs
  */
  mapping(address => mapping(uint => bytes32)) myDAOsIds;
  mapping(address => uint) myDAOsCount;

  /*
    Total amount of DAOs
  */
  uint totalDAOsCount;

  /*
    Add new project to Wings
  */
  function addDAO(string _name, bytes32 _infoHash, Categories _category, bool _underCap) {
    bytes32 _daoId = sha256(_name);

    if (daos[_daoId] != address(0)) {
      throw;
    }

    var dao = new DAO(msg.sender, _name, _infoHash, _category, _underCap);

    daos[_daoId] = dao;
    daosIds[totalDAOsCount++] = _daoId;
    myDAOsIds[msg.sender][myDAOsCount[msg.sender]++] = _daoId;
  }

  /*
    Get DAO by Id
  */
  function getDAOById(bytes32 _daoId) returns constant (address _dao) {
    return daos[_daoId];
  }

  /*
    Get total count of projects
  */
  function getTotalCount() returns constant (uint _count) {
    return totalDAOsCount;
  }

  /*
    Get DAO Id by index
  */
  function getDAOId(uint _n) returns constant (bytes32 _id) {
    return daosIds[_n];
  }

  /*
    Get user daos count
  */
  function getUserDAOsCount(address _user) returns constant (uint _count) {
    return myDAOsCount[_user];
  }

  /*
    Get user daos id
  */
  function getUserDAOsId(uint _n) returns constant (bytes32 _id) {
    return myDAOsIds[_n];
  }
}
