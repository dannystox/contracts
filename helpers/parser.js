const projectFields = {
  0: 'projectId',
  1: 'name',
  2: 'rewardType',
  3: 'rewardPercent',
  4: 'videolink',
  5: 'story',
  6: 'creator',
  7: 'timestamp'
};

const projectBaseFields = {
  0: 'projectId',
  1: 'name',
  2: 'logoHash',
  3: 'category',
  4: 'shortBlurb',
  5: 'cap',
  6: 'duration',
  7: 'goal',
  8: 'timestamp'
};

const milestoneFields = {
  0: 'type',
  1: 'amount',
  2: 'items'
};

let internalParser = (arr, fields) => {
  const result = {};

  for (let i in arr) {
    console.log(i, arr[i]);
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
