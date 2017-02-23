pragma solidity ^0.4.2;

import "../helpers/Whitelist.sol";

/*
  Basic Storage
*/
contract Storage is Whitelist {
  /*
    Storage methods
  */
  mapping(bytes32 => uint) UIntStorage;

  function getUIntValue(bytes32 record) constant returns (uint){
      return UIntStorage[record];
  }

  function setUIntValue(bytes32 record, uint value) allowedAccess
  {
      UIntStorage[record] = value;
  }

  mapping(bytes32 => string) StringStorage;

  function getStringValue(bytes32 record) constant returns (string){
      return StringStorage[record];
  }

  function setStringValue(bytes32 record, string value) allowedAccess
  {
      StringStorage[record] = value;
  }

  mapping(bytes32 => address) AddressStorage;

  function getAddressValue(bytes32 record) constant returns (address){
      return AddressStorage[record];
  }

  function setAddressValue(bytes32 record, address value) allowedAccess
  {
      AddressStorage[record] = value;
  }

  mapping(bytes32 => bytes32) BytesStorage;

  function getBytesValue(bytes32 record) constant returns (bytes32){
      return BytesStorage[record];
  }

  function setBytesValue(bytes32 record, bytes32 value) allowedAccess
  {
      BytesStorage[record] = value;
  }

  mapping(bytes32 => bool) BooleanStorage;

  function getBooleanValue(bytes32 record) constant returns (bool){
      return BooleanStorage[record];
  }

  function setBooleanValue(bytes32 record, bool value) allowedAccess
  {
      BooleanStorage[record] = value;
  }

  mapping(bytes32 => int) IntStorage;

  function getIntValue(bytes32 record) constant returns (int){
      return IntStorage[record];
  }

  function setIntValue(bytes32 record, int value) allowedAccess
  {
      IntStorage[record] = value;
  }
}
