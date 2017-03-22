pragma solidity ^0.4.2;

import "../zeppelin/Ownable.sol";

contract CrowdPoll is Ownable {
  /* Stage of the process:
    BeforePolling -> model parameters not yet assigned
    PollingPeriod -> accounts place hashes of their data
    RevealPeriod -> accounts reveal their votes
    MakingStats -> reveal period finished, owner is obtaining statistics
    PollingSucceeded -> stats available, polling succeeded, accounts can take their rewards
    PollingFailed -> polling failed due to no votes, etc. Accounts can unlock their tokens
  */
  enum Stage {
    BeforePolling,
    PollingPeriod,
    RevealPeriod,
    MakingStats,
    PollingSucceeded,
    PollingFailed
  }

  // Ctor - called by owner
  function CrowdPoll(
    uint _proponentFee,
    uint _projectGoal, uint _projectMax, uint _bucketStep
  ) {
    // Q: Do we need argument checking here or let it be somewhere else?

    stage = Stage.BeforePolling;

    proponentFee = int128(_proponentFee);
    projectGoal = int128(_projectGoal);
    projectMax = int128(_projectMax);
    bucketStep = int128(_bucketStep);
    for (int128 i=0; i<=projectMax; i += bucketStep) {
      buckets[i] = Bucket({ grades: 0, voters: 0, psi: 0 });
    }

    logMasks[0] = 0xFFFFFFFFFFFFFFFF;
    logMasks[1] = 0xFFFFFFFF;
    logMasks[2] = 0xFFFF;
    logMasks[3] = 0xFF;
    logMasks[4] = 0xF;
    logMasks[5] = 3;
    logMasks[6] = 1;
  }

  // Stage 0: The owner adds model parameters and
  // after that accounts can start to vote
  // if # rating levels < 8 then simply zeroes are passed
  function add_model_parameters(
    int32 _spamThreshold,
    int32 _gamma1, int32 _theta1, int32 _gamma2, int32 _theta2,
    int32 _c, int32 _K,
    int32 _maxRating,
    int32 a1, int32 a2, int32 a3, int32 a4, int32 a5, int32 a6, int32 a7, int32 a8
  ) onlyOwner() {
    // Again, where do we need to check the sanity of all of this?

    if (stage != Stage.BeforePolling) {
      throw;
    }

    spamThreshold = _spamThreshold;
    gamma1 = _gamma1;
    theta1 = _theta1;
    gamma2 = _gamma2;
    theta2 = _theta2;
    c = _c;
    K = _K;
    maxRating = _maxRating;
    ratingLevels[0] = a1;
    ratingLevels[1] = a2;
    ratingLevels[2] = a3;
    ratingLevels[3] = a4;
    ratingLevels[4] = a5;
    ratingLevels[5] = a6;
    ratingLevels[6] = a7;
    ratingLevels[7] = a8;

    stage = Stage.PollingPeriod;
  }

  // Q: sortof ACL, can anybody call those fns, need to be called only from accounts from system!
  // проверим есть ли у адреса токены или он оттуда

  // Stage 1: account posts hashed forecast
  function post_forecast(uint value, uint bi, uint8 gi) {
    if (stage != Stage.PollingPeriod
        || value > uint(projectMax)
        || (value % uint(bucketStep)) != 0
        || bi == 0) {
        throw;
    }

    // bi берем внутри, передаем сюда только хэш

    address from = msg.sender;

    if (hashedVotes[from] != 0) {
      throw;
    }

    hashedVotes[from] = sha256(from, value, bi, gi); // ??? hash *maybe* (haha) 0 -> | from;
  }

  // Stop voting, start reveal period, called by owner
  function start_reveal_period() onlyOwner() {
    if (stage == Stage.PollingPeriod) stage = Stage.RevealPeriod;
  }

  // Stage 2: accounts reveal their forecasts
  function reveal_forecast(uint _v, uint _bi, uint8 gi) {
    if (stage != Stage.RevealPeriod) {
        throw;
    }

    address from = msg.sender;

    if (hashedVotes[from] != sha256(from, _v, _bi, gi) || revealedVotes[from].balance > 0) {
      throw;
    }

    int128 v = int128(_v);
    int128 bi = int128(_bi);

    ++totalVotes;
    totalGrades += gi;

    // how to obtain reference ???

    buckets[v].grades += gi;
    ++buckets[v].voters;
    tokensVoted += bi;

    revealedVotes[from] = Vote({ value: v, balance: bi});
  }

  // Q: return values of external calls

  // Stage 3: the owner stops reveal period and calculates stats
  function make_stats(uint _collected, uint _totalTokensInSystem) onlyOwner() {
    stage = Stage.MakingStats;

    totalTokensInSystem = int128(_totalTokensInSystem);
    collected = int128(_collected);
    if (totalTokensInSystem < tokensVoted || totalGrades == 0) {
      stage = Stage.PollingFailed;
      return;
    }

    spamFactor = make_ratio(buckets[0].grades, totalGrades);
    if (spamFactor > spamThreshold) {
      isSpam = true;
      int64 votersForSpam = buckets[0].voters;
      if (votersForSpam > 0) {
          rewardForSpamVote = proponentFee / votersForSpam;
          creatorRefund = proponentFee % votersForSpam;
          // so, do a refund right here or whatever
      } else {
          // TODO log illegal state
          stage = Stage.PollingFailed;
          return;
      }
      stage = Stage.PollingSucceeded;
      return;
    }

    int q1Index = totalGrades / 4;
    int q3Index = totalGrades * 3 / 4;
    int spamGrades = buckets[0].grades;
    int mIndex = spamGrades + (totalGrades - spamGrades) / 2;
    int128 Q1 = NOT_FOUND;
    int128 Q3 = NOT_FOUND;
    median = NOT_FOUND;

    int acc = 0;
    for (int128 i=0; i<=projectMax; i += bucketStep) {
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

    if (Q3 == NOT_FOUND || median == NOT_FOUND || Q1 == NOT_FOUND) {
      // polling failed, no stats
      stage = Stage.PollingFailed;
      return;
    }

    if (Q3 > Q1) {
      q = make_ratio(Q3 - Q1, Q3 + Q1);

       // TODO v.0.8 page 3: q = max(q, (1-p)q1)

    } else {
      q = 0;
    }

    int lsq = make_ratio(tokensVoted, totalTokensInSystem);
    lsquare = int32((lsq*lsq) >> 10);
    valueOfPoll = (lsquare*q) >> 10;

    for (int128 j=0; j<=projectMax; j += bucketStep) {
      buckets[j].psi = psi(j);
    }

    stage = Stage.PollingSucceeded;
  }

  function take_result(uint rating, uint g) returns(int deltaTokens, int deltaR, int deltaG) {
    // TODO what to do if stage == 3?

    if (stage != Stage.PollingSucceeded) {
        // stats not yet collected, we are on wrong stage
        throw;
    }

    Vote v = revealedVotes[msg.sender]; // спросим макса про копирование

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

        deltaTokens = 0;
    }

    if (deltaR != 0) {
      deltaG = delta_g(v, g, rating, deltaR);
    } else {
      deltaG = 0;
    }

    // куда все возвращать если этот вызов есть tx - начислять
  }

  function make_ratio(int128 num, int128 denom) internal constant returns(int32) {
    // 1024 is the base for fixed point ratios
    return int32((num << 10) / denom);
  }

  function psi(int128 value) internal constant returns(int32) {
    // The default for function parameters (including return parameters) is memory, the default for local variables is storage

    // тоже спросить у макса что с неинициализированными переменными
    int gamma;
    int theta;
    int x_Y;
    if (value <= collected) {
        gamma = gamma1;
        theta = theta1;
        x_Y = (collected - value) << 20;
    } else {
        gamma = gamma2;
        theta = theta2;
        x_Y = (value - collected) << 20;
    }

    int m_Y = median - collected;
    m_Y <<= 20;
    if (m_Y < 0) m_Y = -m_Y;

    // z in fixed pt base 1024, can be > 1024
    int z = (x_Y / gamma) >> 20;
    z = z / (m_Y + (theta * q));

    int Psi = (1024 - (z*z) >> 10);

    if (c != 0 && Psi < -c) {
        Psi = -c;
    }

    return int32(Psi);
  }

  function log2(int128 x) internal constant returns(int128 y) {
    y = 0;
    int128 c = 64;
    for (uint8 i=0; i<7; ++i) {
      if (x > logMasks[i]) {
        y += c;
        x >>= c;
      }
      c >>= 1;
    }
    // TODO check that
  }

  function delta_r(Vote v, uint rating) internal returns(int deltaR) {
    // TODO
  }

  function delta_g(Vote v, uint g, uint rating, int deltaR) internal returns(int deltaG) {

  }

// Project parameters
  // Current stage of forecasting process
  Stage public stage;

  // True if the poll considered spam (zero votes # exceeds spamThreshold)
  bool public isSpam;

  // 'x' - proponent's fee that was taken
  int128 proponentFee;

  // goal of the project in tokens
  int128 projectGoal;

  // project's maximum in tokens
  int128 projectMax;

  // step of discrete bucket levels
  int128 bucketStep;

// Model parameters
  // rating levels a[i], (8 is max ??? to fit into 1 slot)
  int32[8] ratingLevels; // mapping vs array ????

  // 's0' - spam threshold [0..1024]
  int32 spamThreshold;

  // gamma, theta, c, K parameters for 'psi' and deltas functions (*1024)
  int32 gamma1;
  int32 theta1;
  int32 gamma2;
  int32 theta2;
  int32 c;
  int32 K;

  // 'R' - max forecast rating
  int32 maxRating;

// Stats
  // median of values (>0) distribution weighted by grades
  int128 median;

  // Spam factor s0 of the poll [0..1024]
  int32 spamFactor;

  // Quartile coefficient of dispersion [0..1024]
  int32 q;

  // squared 'l' in value of the poll formula [0..1024]
  int32 lsquare;

  // Value of the poll
  int32 valueOfPoll;

  // total votes not weighted by g
  int64 totalVotes;

  // votes weighted by g
  int64 totalGrades;

  // total tokens voted
  int128 tokensVoted;

  // value collected by the project
  int128 collected;

  // total tokens in system at the moment of collecting stats
  int128 totalTokensInSystem;

  // reward to those who reported spam
  int128 rewardForSpamVote;

  // refund to creator to avoid losing tokens
  int128 creatorRefund;

  struct Bucket {
    // Grade of the level, this is also histogram item
    int64 grades;

    // voters distributed per level, w/o grade weighting
    int64 voters;

    // Psi (formula 5) values [-c..1024]
    int32 psi;
  }

  // Vote revealed
  struct Vote {
    // Sum of the project
    int128 value;

    // Balance of account in tokens at the moment of the poll
    int128 balance;
  }

  // value => bucket, value = [0, bucketStep, ... projectGoal ... projectMax]
  mapping(int128 => Bucket) buckets;

  // hidden votes passed on stage 1
  mapping(address => bytes32) hashedVotes;

  // votes revealed on stage 2
  mapping(address => Vote) revealedVotes;

  int128 constant NOT_FOUND = -1;
  int128 constant RESULT_TAKEN = -1;
  int128[7] logMasks;
}
