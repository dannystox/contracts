pragma solidity ^0.4.11;

contract Factory {
  address public token;

  function Factory(address _token) {
    token = _token;
  }
}
