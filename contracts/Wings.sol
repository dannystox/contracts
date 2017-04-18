pragma solidity ^0.4.8;

import "./DAOAbstraction.sol";
import "./DAO.sol";

contract Wings  {
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
  uint public totalDAOsCount;

  /*
    Who creator contract
  */
  address public creator;

  /*
    Wings Token Address
  */
  address public token;

  function Wings(address _token) {
    token = _token;
    creator = msg.sender;
  }

  /*
    Add new project to Wings
  */
  function addDAO(string _name, string _symbol, bytes32 _infoHash, bool _underCap, uint _reviewHours) {
    bytes32 _daoId = sha256(_name);

    if (daos[_daoId] != address(0)) {
      throw;
    }

    var dao = new DAO(msg.sender, _name, _symbol, _infoHash, _underCap, _reviewHours, token);

    daos[_daoId] = dao;
    daosIds[totalDAOsCount++] = _daoId;
    myDAOsIds[msg.sender][myDAOsCount[msg.sender]++] = _daoId;
  }

  /*
    Get DAO by Id
  */
  function getDAOById(bytes32 _daoId) constant returns (address _dao) {
    return daos[_daoId];
  }

  /*
    Get DAO Id by index
  */
  function getDAOId(uint _n) constant returns (bytes32 _id) {
    return daosIds[_n];
  }

  /*
    Get user daos count
  */
  function getUserDAOsCount(address _user) constant returns (uint _count) {
    return myDAOsCount[_user];
  }

  /*
    Get user daos id
  */
  function getUserDAOsId(address _user, uint _n) constant returns (bytes32 _id) {
    return myDAOsIds[_user][_n];
  }
}
