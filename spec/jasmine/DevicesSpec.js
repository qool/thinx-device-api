describe("Devices", function() {

  var generated_key_hash = null;
  var devices = require('../../lib/thinx/devices');

  var envi = require("./_envi.json");
  var owner = envi.owner;
  var source_id = envi.sid;
  var udid = envi.udid;

  // All of this expects successful device registration to safely revoke!

  it("should be able to list devices for owner", function(done) {
    devices.list(owner, function(success, response) {
      expect(success).toBe(true);
      expect(response).toBeDefined();
      console.log("Device list response: " + JSON.stringify(
        response));
      done();
    });
  });

  it("should be able to attach a repository to device(s)", function(done) {
    var body = {
      source_id: source_id,
      udid: udid
    };
    devices.attach(owner, body, function(success, response) {
      expect(success).toBe(true);
      expect(response).toBeDefined();
      console.log("Device attach response: " + JSON.stringify(
        response));
      done();
    });
  });

  it("should be able to detach a repository from device(s)", function(done) {
    var body = {
      udid: udid
    };
    devices.detach(owner, body, function(success, response) {
      expect(success).toBe(true);
      expect(response).toBeDefined();
      console.log("Device detach response: " + JSON.stringify(
        response));
      done();
    });
  });

  // requires specific device registered for this test only (udid "to-be-deleted-on-test")
  it("should be able to revoke devices for owner", function(done) {
    var body = {
      udid: udid
    };
    devices.revoke(owner, body, function(success, response) {
      expect(success).toBe(true);
      expect(response).toBeDefined();
      console.log("Device revoke response: " + JSON.stringify(
        response));
      done();
    });
  });

});