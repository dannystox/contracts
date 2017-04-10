const removeFromArray = (arr, index) => {
  for (var i = index; i < arr.length-1; i++) {
    arr[i] = arr[i+1];
  }

  arr.pop()
  return arr
}


module.exports = {
  remove: removeFromArray
}
