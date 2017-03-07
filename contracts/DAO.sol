pragma solidity ^0.4.2;

import './comments/CommentAbstraction.sol';
import './WingsCrowdsale.sol';

contract DAO {
  enum Categories {
    Software,
    Hardware,
    Service,
    Platform,
    NonProfit
  }

  enum RewardTypes {
    PercentDaoTokens,
    PercentCollectedFunds,
    Both
  }

  enum ProjectPeriod {
    Review,
    Forecasting,
    Funding,
    AfterFunding
  }

  struct Project {
    bytes32 id; // id of project
    //address crowdsale; // crowdsale contract of project
    string name; // name of project

    bytes32 shortBlurb; // hash of shortBlurb
    bytes32 logoHash; // hash of project logotype

    Categories category; // category of project
    RewardTypes rewardType; // reward type
    uint rewardPercent; // reward percent
    uint duration; // duration of token sale
    uint goal; // goal that project expect to collect

    string videolink; // link to the video
    bytes32 story;

    address creator; // creator of the projects

    uint timestamp; // timestamp when project created
    bool cap; // project cupped under latest milestone

    uint milestonesCount; // amount of milestones
    uint forecastsCount;  // amount of forecasts

    mapping(uint => Milestone) milestones; // Milestones
    mapping(uint => Forecast) forecasts; // Forecasts
  }
}
