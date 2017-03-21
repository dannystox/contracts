pragma solidity ^0.4.2;

import "../zeppelin/Ownable.sol";

contract CrowdPoll is Ownable {
  // Ctor - called by owner
  function CrowdPoll(
    uint _proponentFee, int32[] _ratingLevels, int32 _maxRating,
    int32 _spamThreshold,
    int32 _gamma1, int32 _theta1, int32 _gamma2, int32 _theta2,
    int32 _c, int32 _K,
    uint _projectGoal, uint _projectMax, uint _bucketStep)
  {
    stage = 1;
    proponentFee = _proponentFee;
    ratingLevels = _ratingLevels;
    maxRating = _maxRating;
    spamThreshold = _spamThreshold;
    gamma1 = _gamma1;
    theta1 = _theta1;
    gamma2 = _gamma2;
    theta2 = _theta2;
    c = _c;
    K = _K;
    projectGoal = _projectGoal;
    projectMax = _projectMax;
    bucketStep = _bucketStep;
    for (uint i=0; i<=projectMax; i += bucketStep) {
      buckets[i] = Bucket({ grades: 0, voters: 0, psi: 0 })
    }

    logMasks[0] = 0xFFFFFFFF00000000;
    logMasks[1] = 0xFFFF0000;
    logMasks[2] = 0xFF00;
    logMasks[3] = 0xF0;
    logMasks[4] = 0x0C;
    logMasks[5] = 2;
  }

  // Q: sortof ACL, can anybody call those fns, need to be called only from accounts from system!

  // Stage 1: account posts hashed forecast
  function post_forecast(uint value, uint bi, uint gi) {
    if (stage != 1 || value > projectMax || (value % bucketStep) != 0 || bi == 0) {
        throw;
    }

    address from = msg.sender;

    if (hashedVotes[from] != 0) {
      throw;
    }

    hashedVotes[from] = sha256(from, value, bi, gi); // ??? hash *maybe* (haha) 0 -> | from;
  }

  // Stop voting, start reveal period, called by owner
  function start_reveal_period() onlyOwner() {
    stage = 2;
  }

  // Stage 2: accounts reveal their forecasts
  function reveal_forecast(uint v, uint bi, uint gi) {
    if (stage != 2) {
        throw;
    }

    address from = msg.sender;

    if (hashedVotes[from] != sha256(from, v, bi, gi) || revealedVotes[from].balance != 0) {
      throw;
    }

    ++totalVotes;
    totalGrade += gi;

    // how to obtain reference ???

    buckets[v].grades += gi;
    ++buckets[v].voters;
    tokensVoted += bi;

    revealedVotes[from] = Vote({ value: v, balance: bi});
  }

  // Q: return values of external calls

  // Stage 3: the owner stops reveal period and calculates stats
  function make_stats(uint _tokensCollected, uint _totalTokensInSystem) onlyOwner() {
    stage = 3;
    totalTokensInSystem = _totalTokensInSystem;
    collected = _tokensCollected;
    if (totalTokensInSystem < tokensVoted || totalGrades == 0) {
      return;
    }

    spamFactor = make_ratio(buckets[0].grades, totalGrades);
    if (spamFactor >= spamThreshold) {
      isSpam = true;
      uint votersForSpam = buckets[0].voters;
      if (votersForSpam) {
          rewardForSpamVote = proponentFee / votersForSpam;
          creatorRefund = proponentFee % votersForSpam;
          // so, do a refund right here or whatever
      } else {
          // TODO log illegal state
          return;
      }
      stage = 4;
      return;
    }

    uint q1Index = totalGrades / 4;
    uint q3Index = totalGrades * 3 / 4;
    uint spamGrades = buckets[0].grades;
    uint mIndex = spamGrades + (totalGrades - spamGrades) / 2;
    uint Q1 = NOT_FOUND;
    uint Q3 = NOT_FOUND;
    median = NOT_FOUND;

    uint acc = 0;
    for (uint i=0; i<=projectMax; i += bucketStep) {
      Bucket bucket = buckets[i]; // Q: copied to memory ???
      acc += bucket.grades;
      if (Q1 == NOT_FOUND && acc >= q1Index) {
        Q1 = i;
      }
      if (median == NOT_FOUND && acc >= mIndex) {
        median = i;
      }
      if (Q3 == NOT_FOUND && acc >= q3Index) {
        Q3 = i;
        if (Q3 >= median)
          break;
      }
    }

    if (Q3 == NOT_FOUND || st.median == NOT_FOUND || Q1 == NOT_FOUND) {
      // polling failed, no stats
      return;
    }

    if (Q3 > Q1) {
      q = make_ratio(Q3 - Q1, Q3 + Q1);

       // TODO v.0.8 page 3: q = max(q, (1-p)q1)

    } else {
      q = 0;
    }

    int lsq = make_ratio(tokensVoted, totalTokensInSystem);
    lsquare = (lsq*lsq) >> 10;
    valueOfPoll = (lsquare*q) >> 10;

    for (uint i=0; i<=projectMax; i += bucketStep) {
      buckets[i].psi = psi(i);
    }

    stage = 4;
  }

  function take_result(uint rating, uint g) returns(int deltaTokens, int deltaR, int deltaG) {
    // TODO what to do if stage == 3?

    if (stage != 4) {
        // stats not yet collected, we are on wrong stage
        throw;
    }

    Vote v = votes[msg.sender];

    if (v.balance == 0 || v.balance == RESULT_TAKEN) {
      throw;
    }

    if (isSpam) {
        deltaR = 0;
        if (v.value == 0) {
            deltaTokens = rewardForSpamVote;
        }
        //if (from == dp.creator) {
      //  ?????????    out.deltaTokens += creatorRefund;
        //}
    } else {
        if (v.value > 0) deltaR = delta_r(v, rating);
        else deltaR = 0;

        // TODO where project fee is going???

        out.deltaTokens = 0;
    }

    if (deltaR != 0) {
      deltaG = delta_g(v, g, rating, deltaR);
    } else {
      deltaG = 0;
    }
  }

  function make_ratio(uint num, uint denom) internal returns(int) {
    // 1024 is the base for fixed point ratios
    return (num << 10) / denom;
  }

  function psi(uint value) internal returns(int32) {
    int gamma, theta, x_Y;
    if (value <= collected) {
        gamma = gamma1;
        theta = theta1;
        x_Y = (collected - value) << 20;
    } else {
        gamma = gamma2;
        theta = theta2;
        x_Y = (value - collected) << 20;
    }

    int m_Y = ((int)median - collected) << 20;
    if (m_Y < 0) m_Y = -m_Y;

    // z in fixed pt base 1024, can be > 1024
    int z = (x_Y / gamma) >> 20;
    z = z / (m_Y + (theta * q));

    int Psi = (1024 - (z*z) >> 10);

    if (c != 0 && Psi < -c) {
        Psi = -c;
    }

    return Psi;
  }

  function log2(uint64 x) internal returns(uint64 y) {
    y = 0;
    uint64 c = 32;
    for (int i=0; i<6; ++i, c>>1) {
      if (x & logMasks[i]) {
        y += c;
      }
    }
    // TODO check that
  }

  function delta_r(Vote v, uint rating) internal returns(int deltaR) {
    // TODO
  }

  uint constant NOT_FOUND = 1 << 128;
  uint64 constant RESULT_TAKEN = 0xFFFFFFFFFFFFFFFF;
  uint64[6] constant logMasks;

  /* Stage of the process:
    1 -> polling period
    2 -> reveal period
    3 -> reveal period finished, but stats are not ready (this stage is terminal if polling itself has failed)
    4 -> stats available, polling succeeded
  */
  int stage;

  // 'x' - proponent's fee that was taken
  uint public proponentFee;

  // rating levels a[i], (8 is max ??? to fit into 1 slot)
  int32[] public ratingLevels; // mapping vs array ????

  // 'R' - max forecast rating
  int32 public maxRating;

  // 's0' - spam threshold [0..1024]
  int32 public spamThreshold;

  // gamma, theta, c, K parameters for 'psi' function (*1024)
  int32 public gamma1;
  int32 public theta1;
  int32 public gamma2;
  int32 public theta2;
  int32 public c;
  int32 public K;

  // goal of the project in tokens
  uint public projectGoal;

  // project's maximum in tokens
  uint public projectMax;

  // step of discrete bucket levels
  uint bucketStep;

  // total tokens in system at the moment of collecting stats
  uint public totalTokensInSystem;

  // Spam factor of the poll
  int32 public spamFactor;

  // True if the poll considered spam
  bool public isSpam;

  // reward to those who reported spam
  uint rewardForSpamVote;

  // refund to creator to avoid losing tokens
  uint creatorRefund;

  // median of votes distribution
  uint public median;

  // Quartile coefficient of dispersion [0..1024]
  uint32 public q;

  // squared 'l' in value of the poll formula [0..1024]
  uint32 public lsquare;

  // Value of the poll
  uint32 public valueOfPoll;

  // total votes not weighted by g
  uint32 totalVotes;

  // votes weighted by g
  uint32 totalGrades;

  // total tokens voted
  uint tokensVoted;

  struct Bucket {
    // Grade of the level, this is also histogram item
    uint32 grades;

    // voters distributed per level, w/o grade weighting
    uint32 voters;

    // Psi (formula 5) values [0..1024]
    int32 psi;
  }

  // value => bucket, value = [0, bucketStep, ... projectGoal ... projectMax]
  mapping(uint => Bucket) buckets;

  // hidden votes passed on stage 1
  mapping(address => uint) hashedVotes;

  struct Vote {
    uint64 value;
    uint64 balance;
  }

  // votes revealed on stage 2
  mapping(address => Vote) revealedVotes;
}
