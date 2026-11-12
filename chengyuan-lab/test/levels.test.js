'use strict';

var test = require('node:test');
var assert = require('node:assert/strict');
var validate = require('../scripts/validate-levels').validate;

test('all 200 levels are deterministic, solvable, and match their solver par', function () {
  var report = validate();
  assert.deepEqual(report.failures, []);
  assert.equal(report.levels, 200);
  assert.ok(report.exactChecked >= 100);
});
