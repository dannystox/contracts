pragma solidity ^0.4.8;

import "./DAOAbstraction.sol";

contract DAO is DAOAbstraction {
  function DAO(
      address _timeManager,
      address _owner,
      bytes32 _id,
      bytes32 _infoHash,
      address _milestones,
      address _forecasting,
      address _crowdsale)  {
        timeManager = _timeManager;
        owner = _owner;
        id = _id;
        infoHash = _infoHash;

        milestones = _milestones;
        forecasting = _forecasting;
        crowdsale = _crowdsale;
  }

  /*
    Update project data
  */
  function update(bytes32 _infoHash) onlyOwner() inTime() {
    infoHash = _infoHash;
  }

}
