const projectFields = {
  0: 'projectId',
  1: 'name',
  2: 'rewardType',
  3: 'rewardPercent',
  4: 'videolink',
  5: 'story',
  6: 'creator',
  7: 'timestamp'
}

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
}

const milestoneFields = {
  0: 'amount',
  1: 'items'
}

const forecastFields = {
  0: 'creator',
  1: 'amount',
  2: 'timestamp',
  3: 'message'
}

const forecastUserFields = {
  0: 'amount',
  1: 'timestamp',
  2: 'message'
}

const commentFields = {
  0: 'creator',
  1: 'timestamp',
  2: 'data'
}

const preminerFields = {
  0: 'recipient',
  1: 'disabled',
  2: 'payment',
  3: 'latestAllocation',
  4: 'allocationsCount'
}

const internalParser = (arr, fields) => {
  const result = {}

  for (let i in arr) {
    result[fields[i]] = arr[i]
  }

  return result
}

const parseProject = (arr) => internalParser(arr, projectFields)
const parseBaseProject = (arr) => internalParser(arr, projectBaseFields)
const parseMilestone = (arr) => internalParser(arr, milestoneFields)
const parseForecast = (arr) => internalParser(arr, forecastFields)
const parseComment = (arr) => internalParser(arr, commentFields)
const parsePreminer = (arr) => internalParser(arr, preminerFields)
const parseUserForecast = (arr) => internalParser(arr, forecastUserFields)

module.exports = {
  parseProject,
  parseBaseProject,
  parseMilestone,
  parseForecast,
  parseUserForecast,
  parseComment,
  parsePreminer
}
