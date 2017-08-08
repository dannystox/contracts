pragma solidity ^0.4.11;

import "./DAO.sol";
import "./factories/MilestonesFactory.sol";
import "./factories/ForecastingFactory.sol";
import "./factories/CrowdsaleFactory.sol";

contract Wings  {
  event DAO_ADD(bytes32 indexed id, address owner);

  modifier isValidReviewHours(uint _reviewHours) {
    require(_reviewHours >= 1);
    require(_reviewHours < 504);
    _;
  }

  modifier isValidForecastingHours(uint _forecastingHours) {
    require(_forecastingHours >= 120);
    require(_forecastingHours < 720);
    _;
  }

  modifier isValidCrowdsaleHours(uint _crowdsaleHours) {
    require(_crowdsaleHours >= 168);
    require(_crowdsaleHours < 2016);
    _;
  }

  struct BaseDAOInfo {
    address milestones;
    address forecasting;
    address crowdsale;

    uint reviewHours;
    uint crowdsaleHours;
    uint forecastingHours;

    bool inProgress;
  }

  mapping(address => mapping(uint => BaseDAOInfo)) baseInfos;
  mapping(address => uint) baseInfosCount;

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
    Contracts
  */
  address public token;

  MilestonesFactory public milestonesFactory;
  CrowdsaleFactory public crowdsaleFactory;
  ForecastingFactory public forecastingFactory;

  function Wings(
      address _token,
      address _milestonesFactory,
      address _crowdsaleFactory,
      address _forecastingFactory
  ) public {
    token = _token;
    creator = msg.sender;

    milestonesFactory = MilestonesFactory(_milestonesFactory);
    crowdsaleFactory = CrowdsaleFactory(_crowdsaleFactory);
    forecastingFactory = ForecastingFactory(_forecastingFactory);
  }

  function getBaseInfo(uint _index) internal returns (BaseDAOInfo) {
    uint length = baseInfosCount[msg.sender];

    if (length > _index) {
      return baseInfos[msg.sender][_index];
    } else {
      require(length == _index);
      var baseInfo = BaseDAOInfo(
          address(0),
          address(0),
          address(0),
          0,
          0,
          0,
          true
        );

      baseInfos[msg.sender][_index] = baseInfo;
      baseInfosCount[msg.sender]++;

      return baseInfo;
    }
  }

  function createMilestones(
      uint _index,
      bool _cap,
      uint _reviewHours
    ) public isValidReviewHours(_reviewHours) returns (address) {
      var baseInfo = getBaseInfo(_index);

      require(baseInfo.inProgress);
      require(baseInfo.milestones == address(0));

      baseInfo.milestones = milestonesFactory.create(address(this), msg.sender, _cap);
      baseInfo.reviewHours = _reviewHours;
      baseInfos[msg.sender][_index] = baseInfo;

      return baseInfo.milestones;
  }

  function createCrowdsale(
      uint _index,
      address _multisig,
      string _name,
      string _symbol,
      uint _price,
      uint _rewardPercent,
      uint _crowdsaleHours
    ) public isValidCrowdsaleHours(_crowdsaleHours) returns (address) {
      var baseInfo = getBaseInfo(_index);

      require(baseInfo.inProgress);
      require(baseInfo.crowdsale == address(0));
      require(baseInfo.milestones == address(0));

      baseInfo.crowdsale = crowdsaleFactory.create(
          msg.sender,
          address(this),
          _multisig,
          _name,
          _symbol,
          baseInfo.milestones,
          _price,
          _rewardPercent
        );

      baseInfos[msg.sender][_index] = baseInfo;

      return baseInfo.crowdsale;
  }

  function createForecasting(
      uint _index,
      uint _rewardPercent,
      uint _forecastingHours
    ) public isValidForecastingHours(_forecastingHours) returns (address) {
      var baseInfo = getBaseInfo(_index);

      require(baseInfo.inProgress);
      require(baseInfo.forecasting == address(0));
      require(baseInfo.milestones != address(0));
      require(baseInfo.crowdsale != address(0));

      baseInfo.forecasting = forecastingFactory.create(
          address(this),
          _rewardPercent,
          baseInfo.milestones,
          baseInfo.crowdsale
        );

      baseInfo.forecastingHours = _forecastingHours;
      baseInfos[msg.sender][_index] = baseInfo;

      return baseInfo.forecasting;
    }



  /*
    Add new project to Wings
  */
  function createDAO(uint _index,
                  string _name,
                  bytes32 _infoHash) public returns (address) {
    bytes32 _daoId = sha256(_name);

    require(daos[_daoId] == address(0));
    require(baseInfosCount[msg.sender] > _index);
    var baseInfo = baseInfos[msg.sender][_index];


    require(baseInfo.inProgress);
    require(baseInfo.milestones != address(0));
    require(baseInfo.crowdsale != address(0));
    require(baseInfo.forecasting != address(0));

    uint startReviewTime = block.timestamp;
    uint endReviewTime = startReviewTime + (baseInfo.reviewHours * 1 hours);
    uint endForecastTime = endReviewTime + (baseInfo.forecastingHours * 1 hours);
    uint endCrowdsaleTime = endForecastTime + (baseInfo.crowdsaleHours * 1 hours);

    require(startReviewTime < endReviewTime);

    var dao = new DAO(
        address(this),
        msg.sender,
        _daoId,
        _infoHash,
        baseInfo.milestones,
        baseInfo.forecasting,
        baseInfo.crowdsale
    );

    dao.setTime(startReviewTime, endReviewTime);
    Milestones(baseInfo.milestones).setTime(startReviewTime, endReviewTime);
    Forecasting(baseInfo.forecasting).setTime(endReviewTime, endForecastTime);
    Crowdsale(baseInfo.crowdsale).setLimitations(endReviewTime, endForecastTime, endCrowdsaleTime);
    Crowdsale(baseInfo.crowdsale).setForecasting(baseInfo.forecasting);

    baseInfo.inProgress = false;
    daos[_daoId] = dao;
    daosIds[totalDAOsCount++] = _daoId;
    myDAOsIds[msg.sender][myDAOsCount[msg.sender]++] = _daoId;
    DAO_ADD(_daoId, msg.sender);
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
