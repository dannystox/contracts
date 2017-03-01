contract('Token', function(accounts) {
  var wings, creator;

  before("Initialize Wings contract", function (done) {
	 creator = accounts[0];

	 Token.new({
		from: creator
	 }).then(function (_wings) {
		wings = _wings;
	 }).then(done).catch(done);
  });


});
