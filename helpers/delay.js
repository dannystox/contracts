const Promise = require('bluebird');

let delay = (ms) => {
    let deferred = Promise.pending();
    setTimeout(() => {
        deferred.resolve();
    }, ms);
    return deferred.promise;
}

module.exports = delay;
