const projectFields = {
  0: 'projectId',
  1: 'name',
  2: 'shortBlurb',
  3: 'logoHash',
  4: 'category',
  5: 'rewardType',
  6: 'rewardPercent',
  7: 'duration',
  8: 'goal',
  9: 'videolink',
  10: 'story',
  11: 'creator',
  12: 'underReview'
};

const projectBaseFields = {
  0: 'projectId',
  1: 'name',
  2: 'logoHash',
  3: 'category',
  4: 'shortBlurb',
  5: 'underReview',
  6: 'cap',
  7: 'duration',
  8: 'goal',
  9: 'creator'
};

const milestoneFields = {
  0: 'type',
  1: 'amount',
  2: 'items'
};

let internalParser = (arr, fields) => {
  const result = {};

  for (let i in arr) {
    result[fields[i]] = arr[i];
  }

  return result;
}

let parseProject = (arr) => {
  return internalParser(arr, projectFields);
}

let parseBaseProject = (arr) => {
  return internalParser(arr, projectBaseFields);
}

let parseMilestone = (arr) => {
  return internalParser(arr, milestoneFields);
}

module.exports = {
  parseProject: parseProject,
  parseBaseProject: parseBaseProject,
  parseMilestone: parseMilestone
}
