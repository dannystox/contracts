pragma solidity ^0.4.2;

import './helpers/strings.sol';

contract Wings {
  using strings for *;

  /*
    Project Events
  */
  event ProjectCreation(address indexed creator, bytes32 indexed id, string name);
  event ProjectReady(bytes32 indexed id, string name);
  event ProjectPublishing(bytes32 indexed creator, bytes32 indexed id);

  /*
    Milestone Events
   */
  event MilestoneAdded(bytes indexed id);

  /*
    Forecast type
  */
  enum ForecastRaiting {
    Low,
    Middle,
    Top
  }

  /*
    Project Categories
   */
  enum Categories {
    Software,
    Hardware,
    Service,
    Platform,
    NonProfit
  }

  /*
    Reward types
  */
  enum RewardTypes {
    PercentDaoTokens,
    PercentCollectedFunds,
    Both
  }

  /*
    Milestone type
  */
  enum MilestoneType {
    Forecast,
    Automatic
  }

  /*
    Milestone Structure
  */
  struct Milestone {
    bytes32 projectId; // id of project
    MilestoneType _type; // type of milestone
    uint amount; // amount of milestone to spent
    string[] items; // milestone items
  }

  struct Forecast {
    address creator;  // creator
    bytes32 project; // project
    ForecastRaiting raiting; // raiting
    uint timestamp; // timestamp
    bytes32 message; // message
  }

  /*
    Wings Project Structure
  */
  struct Project {
    bytes32 id; // id of project

    string name; // name of project
    bytes32 shortBlurb; // hash of shortBlurb
    bytes32 logoHash; // hash of project logotype

    Categories category; // category of project
    RewardTypes rewardType; // reward type
    uint rewardPercent; // reward percent
    uint duration; // duration of token sale
    uint goal; // goal that project expect to collect

    string videolink; // link to the video
    bytes32 story; //hash of project story

    address creator; // creator of the projects

    uint timestamp; // timestamp when project created
    bool cap; // project cupped under latest milestone

    uint milestonesCount; // amount of milestones
    uint forecastsCount;  // amount of forecasts

    mapping(uint => Milestone) milestones; // Milestones
    mapping(uint => Forecast) forecasts; // Forecasts
  }

  mapping(bytes32 => Project) projects; // project by name hash to project object
  mapping(uint => bytes32) projectsIds; // project ids

  mapping(address => mapping(uint => bytes32)) myProjectsIds; // my projects ids
  mapping(address => uint) myProjectsCount; // my projects count

  mapping(address => mapping(bytes32 => Forecast)) myForecasts; // my forecast to the project

  uint count; // amount of projects
  address creator; // creator of the contract

  modifier projectOwner(bytes32 projectId) {
    var project = projects[projectId];

    if (project.creator == msg.sender) {
      _;
    }
  }

  modifier allowToAddMilestone(bytes32 projectId) {
    var project = projects[projectId];

    if (block.timestamp < project.timestamp + 24 hours) {
      _;
    }
  }

  function Wings() {
    creator = msg.sender;
  }

  function getProjectId(uint n) returns (bytes32) {
    return projectsIds[n];
  }

  function getMyProjectsCount(address owner) returns (uint) {
    return myProjectsCount[owner];
  }

  function getMyProjectId(address owner, uint id) returns (bytes32) {
    return myProjectsIds[owner][id];
  }

  /*
    Publish project
  */
  function addProject(
      string _name,
      bytes32 _shortBlurb,
      bytes32 _logoHash,
      Categories _category,
      RewardTypes _rewardType,
      uint _rewardPercent,
      uint _duration,
      uint _goal,
      string _videolink,
      bytes32 _story,
      bool cap
    ) returns (bool) {
      bytes32 _projectId = sha256(_name);

      if (projects[_projectId].creator != address(0)) {
        throw;
      }

      if (_rewardPercent > 100 || _rewardPercent == 0) {
        throw;
      }

      if (_duration > 180 || _duration < 30) {
        throw;
      }

      var project = Project(
        _projectId,
        _name,
        _shortBlurb,
        _logoHash,
        _category,
        _rewardType,
        _rewardPercent,
        _duration,
        _goal,
        _videolink,
        _story,
        msg.sender, // creator
        block.timestamp, // timestamp
        cap, // cap
        0, // milestones count
        0  // forecasts count
      );

      projects[_projectId] = project;
      projectsIds[count++] = _projectId;
      myProjectsIds[msg.sender][myProjectsCount[msg.sender]++] = _projectId;

      ProjectCreation(msg.sender, _projectId, project.name);
      return true;
  }


  /* Get base project info */
  function getBaseProject(bytes32 id) returns (
      bytes32 projectId,
      string name,
      bytes32 logoHash,
      Categories category,
      bytes32 shortBlurb,
      bool cap,
      uint duration,
      uint goal,
      uint timestamp
    ) {
      var project = projects[id];

      return (
          project.id,
          project.name,
          project.logoHash,
          project.category,
          project.shortBlurb,
          project.cap,
          project.duration,
          project.goal,
          project.timestamp
        );
    }

  function getProject(bytes32 id) returns (
      bytes32 projectId,
      string name,
      RewardTypes rewardType,
      uint rewardPercent,
      string videolink,
      bytes32 story,
      address creator,
      uint timestamp
    ) {
    var project = projects[id];

    return (
      project.id,
      project.name,
      project.rewardType,
      project.rewardPercent,
      project.videolink,
      project.story,
      project.creator,
      project.timestamp
    );
  }

  /*
    Change owner of project
   */
  function changeCreator(bytes32 id, address to) projectOwner(id) {
    var project = projects[id];
    project.creator = to;
  }

  function getItemsFromString(string str) private constant returns (string[]) {
    var s = str.toSlice();
    var delim = "\n".toSlice();
    var parts = new string[](s.count(delim));
    for(uint i = 0; i < parts.length; i++) {
        parts[i] = s.split(delim).toString();
    }

    return parts;
  }

  function concatStrs(string[] strs) private constant returns (string) {
    var s = "";
    for (var i = 0; i < strs.length; i++) {
      s = s.toSlice().concat(strs[i].toSlice());
      s = s.toSlice().concat("\n".toSlice());
    }

    return s;
  }

  /*
    Get count of projects
  */
  function getCount() returns (uint) {
    return count;
  }

  /*
    Add milestone
  */
  function addMilestone(bytes32 id, MilestoneType _type, uint amount, string _items) projectOwner(id) allowToAddMilestone(id) {
    var project = projects[id];
    if (project.creator == address(0) || project.milestonesCount == 10 || amount == 0) {
      throw;
    }

    uint milestonesSum = 0;
    for (var i = 0; i < project.milestonesCount; i++) {
      milestonesSum += project.milestones[i].amount;
    }


    uint diff = project.goal - milestonesSum;

    if (diff < amount) {
      throw;
    }

    var items = getItemsFromString(_items);

    if (items.length > 10 || items.length == 0) {
      throw;
    }

    var milestone = Milestone(id, _type, amount, items);
    project.milestones[project.milestonesCount++] = milestone;
  }

  // get milestones count
  function getMilestonesCount(bytes32 id) returns (uint) {
    var project = projects[id];

    return project.milestonesCount;
  }

  /*
    Get milestone
  */
  function getMilestone(bytes32 id, uint milestoneId) returns (MilestoneType _type, uint amount, string items) {
    var project = projects[id];

    if (project.creator == address(0)) {
      throw;
    }

    var milestone = project.milestones[milestoneId];
    var _items = concatStrs(milestone.items);

    return (milestone._type, milestone.amount, _items);
  }

  /*
    Get minimal goal of the project
  */
  function getMinimalGoal(bytes32 id) returns (uint minimal) {
    var project = projects[id];

    if (project.creator == address(0)) {
      throw;
    }

    if (project.milestonesCount == 0) {
      return 0;
    }

    return project.milestones[0].amount;
  }

  /*
    Get cap goal of the project
  */
  function getCap(bytes32 id) returns (uint cap) {
    var project = projects[id];

    if (project.creator == address(0) || project.cap == false) {
      throw;
    }

    uint amount = 0;
    for (var i = 0; i < project.milestonesCount; i++) {
      amount = amount + project.milestones[i].amount;
    }

    return amount;
  }

  /*
    Forecasting
  */
  function addForecast(bytes32 projectId, ForecastRaiting raiting, bytes32 message) {
    var project = projects[projectId];

    if (project.creator == address(0)) {
      //throw;
    }

    if (myForecasts[msg.sender][projectId].creator != address(0)) {
      //throw;
    }

    var forecast = Forecast(
      msg.sender,
      projectId,
      raiting,
      block.timestamp,
      message
    );

    project.forecasts[project.forecastsCount++] = forecast;
    myForecasts[msg.sender][projectId] = forecast;
  }

  /*
    Get forecasts count
  */
  function getForecastCount(bytes32 projectId) returns (uint) {
    var project = projects[projectId];
    return project.forecastsCount;
  }

  /*
    Get forecast by number
    address creator;  // creator
    bytes32 project; // project
    ForecastRaiting raiting; // raiting
    uint timestamp; // timestamp
  */
  function getForecast(bytes32 projectId, uint id) returns (
      address _creator,
      bytes32 _project,
      ForecastRaiting _raiting,
      uint _timestamp,
      bytes32 _message
    ) {
      var project = projects[projectId];
      var forecast = project.forecasts[id];

      return (
        forecast.creator,
        forecast.project,
        forecast.raiting,
        forecast.timestamp,
        forecast.message
      );
  }

  /*
    Get my forecast for project
  */
  function getMyForecast(bytes32 projectId) returns (
      address _creator,
      bytes32 _project,
      ForecastRaiting _raiting,
      uint _timestamp,
      bytes32 _message
    ) {
      var forecast = myForecasts[msg.sender][projectId];

      return (
        forecast.creator,
        forecast.project,
        forecast.raiting,
        forecast.timestamp,
        forecast.message
      );
    }
}
