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
  event MilestoneUpdated(bytes32 indexed id, uint milestoneId);
  event MilestoneAdded(bytes indexed id);
  event MilestoneRemoved(bytes32 indexed id, uint milestoneId);

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
    address creator;
    uint amount;
    uint timestamp;
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
    bool underReview; // project under review
    bool underForecast; // project under forecast

    uint timestamp; // timestamp when project created
    bool cap; // project cupped under latest milestone

    uint milestonesCount; // amount of milestones

    uint hoursToReview; // hours that allow to review
    uint hoursToForecast; // hourse to allow to forecast

    mapping(uint => Milestone) milestones; // Milestones
  }

  mapping(bytes32 => Project) projects; // project by name hash to project object
  mapping(uint => bytes32) projectsIds; // project ids

  uint count; // amount of projects
  address creator; // creator of the contract

  modifier projectOwner(bytes32 projectId) {
    var project = projects[projectId];

    if (project.creator == msg.sender) {
      _;
    }
  }

  modifier allowToChange(bytes32 projectId) {
    var project = projects[projectId];

    if (project.underReview) {
      _;
    }
  }


  function Wings() {
    creator = msg.sender;
  }

  function getHash(string data) returns (bytes32) {
    return sha256(data);
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

      if (_duration > 180 || _duration == 0) {
        throw;
      }

      /*if (hoursToReview < 12 || hoursToReview > 36) {
        throw;
      }*/

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
        true, // under review
        false, // under forecasting
        block.timestamp, // timestamp
        cap, // cap
        0, // milestones count
        0, // hours to review
        0 // hours to forecast
      );

      projects[_projectId] = project;
      projectsIds[count++] = _projectId;

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
      bool underReview,
      bool cap,
      uint duration,
      uint goal
    ) {
      var project = projects[id];

      return (
          project.id,
          project.name,
          project.logoHash,
          project.category,
          project.shortBlurb,
          project.underReview,
          project.cap,
          project.duration,
          project.goal
        );
    }

  function getProject(bytes32 id) returns (
      bytes32 projectId,
      string name,
      bytes32 shortBlurb,
      bytes32 logoHash,
      Categories category,
      RewardTypes rewardType,
      uint rewardPercent,
      uint duration,
      uint goal,
      string videolink,
      bytes32 story,
      address creator
    ) {
    var project = projects[id];

    return (
      project.id,
      project.name,
      project.shortBlurb,
      project.logoHash,
      project.category,
      project.rewardType,
      project.rewardPercent,
      project.duration,
      project.goal,
      project.videolink,
      project.story,
      project.creator
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
    Is project under review
  */
  function isUnderReview(bytes32 id) returns (bool) {
    var project = projects[id];
    return project.underReview;
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
  function addMilestone(bytes32 id, MilestoneType _type, uint amount, string _items) projectOwner(id) allowToChange(id) {
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

  function changeMilestone(bytes32 id, uint milestoneId, MilestoneType _type, uint amount, string items) projectOwner(id) allowToChange(id) {
    var project = projects[id];

    if (project.milestonesCount < milestoneId) {
      throw;
    }

    project.milestones[milestoneId]._type = _type;
    project.milestones[milestoneId].amount = amount;
    project.milestones[milestoneId].items = getItemsFromString(items);

    MilestoneUpdated(id, milestoneId);
  }

  /*
    Remove milestone
   */
  function removeMilestone(bytes32 id, uint milestoneId) projectOwner(id) allowToChange(id) {
    var project = projects[id];

    if (project.milestonesCount == 0 || milestoneId > project.milestonesCount) {
      throw;
    }

    delete project.milestones[milestoneId];

    for (var i = milestoneId; i < project.milestonesCount; i++) {
      if (i + 1 == project.milestonesCount) {
        continue;
      }

      project.milestones[i] = project.milestones[i+1];
    }

    project.milestonesCount--;
    MilestoneRemoved(id, milestoneId);
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
    Setting hours to review
  */
  function setHoursToReview(bytes32 id, uint hoursToReview) projectOwner(id) allowToChange(id) {
    var project = projects[id];

    if (project.hoursToReview != 0) {
      throw;
    }

    if (hoursToReview < 12 || hoursToReview > 36) {
      throw;
    }

    project.hoursToReview = hoursToReview;
  }

  /*
    Move to forecast period
  */
  function closeReview(bytes32 id, uint hoursToForecast) projectOwner(id) allowToChange(id) {
    var project = projects[id];

    if (hoursToForecast < 12 || hoursToForecast > 36) {
      throw;
    }

    //if (block.timestamp >= project.timestamp + project.hoursToReview * 1 hours) {
      project.hoursToForecast = hoursToForecast;
      project.underReview = false;
      project.underForecast = true;
      ProjectReady(id, project.name);
    //} else {
    //  throw;
    //}
  }


}
