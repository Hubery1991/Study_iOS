'use strict';

var test = require('node:test');
var assert = require('node:assert/strict');
var rules = require('../js/core/rules');
var hint = require('../js/core/hint');
var solver = require('../scripts/solver');

test('pours a matching run onto the same color', function () {
  var tubes = [
    [1, 1, 2, 2],
    [2],
    [],
  ];
  var applied = rules.applyPour(tubes, 4, 0, 1);
  assert.ok(applied);
  assert.equal(applied.count, 2);
  assert.equal(applied.color, 2);
  assert.deepEqual(applied.tubes[0], [1, 1]);
  assert.deepEqual(applied.tubes[1], [2, 2, 2]);
  assert.deepEqual(tubes[0], [1, 1, 2, 2]);
});

test('pours into an empty bottle', function () {
  var tubes = [[1, 3, 3], [], [1, 1]];
  var applied = rules.applyPour(tubes, 4, 0, 1);
  assert.equal(applied.count, 2);
  assert.deepEqual(applied.tubes[0], [1]);
  assert.deepEqual(applied.tubes[1], [3, 3]);
});

test('partial pour when the destination has little space', function () {
  var tubes = [
    [1, 1, 1],
    [1, 1, 1],
  ];
  var applied = rules.applyPour(tubes, 4, 0, 1);
  assert.equal(applied.count, 1);
  assert.deepEqual(applied.tubes[0], [1, 1]);
  assert.deepEqual(applied.tubes[1], [1, 1, 1, 1]);
});

test('rejects a different color, a full bottle, and pouring onto itself', function () {
  var tubes = [
    [1, 2],
    [3],
    [1, 1, 1, 1],
  ];
  assert.equal(rules.pourAmount(tubes, 4, 0, 1), 0);
  assert.equal(rules.applyPour(tubes, 4, 0, 1), null);
  assert.equal(rules.pourAmount(tubes, 4, 0, 2), 0);
  assert.equal(rules.pourAmount(tubes, 4, 0, 0), 0);
  assert.equal(rules.pourAmount(tubes, 4, 5, 0), 0);
});

test('a finished bottle is sealed', function () {
  var tubes = [
    [1, 1, 1, 1],
    [],
    [2, 2, 2, 1],
  ];
  assert.equal(rules.isComplete(tubes[0], 4), true);
  assert.equal(rules.pourAmount(tubes, 4, 0, 1), 0);
  assert.equal(rules.legalMoves(tubes, 4).some(function (m) { return m.from === 0; }), false);
});

test('win requires every bottle empty or full of one color', function () {
  assert.equal(
    rules.isWon(
      [
        [1, 1],
        [],
        [2, 2],
      ],
      2
    ),
    true
  );
  assert.equal(
    rules.isWon(
      [
        [1, 1],
        [1],
        [2, 2],
      ],
      2
    ),
    false
  );
  assert.equal(
    rules.isWon(
      [
        [1, 2],
        [2, 1],
      ],
      2
    ),
    false
  );
  assert.equal(rules.isWon([[], []], 4), true);
});

test('color counts stay the same after a pour', function () {
  var tubes = [
    [4, 4, 1, 1],
    [1, 2],
    [],
  ];
  var before = rules.colorCounts(tubes);
  var applied = rules.applyPour(tubes, 4, 0, 2);
  assert.deepEqual(rules.colorCounts(applied.tubes), before);
});

test('undo stack restores the previous position and move count', function () {
  var tubes = [
    [1, 2],
    [2],
    [],
  ];
  var history = [rules.cloneTubes(tubes)];
  var moves = 0;
  var applied = rules.applyPour(tubes, 4, 0, 1);
  history.push(rules.cloneTubes(tubes));
  tubes = applied.tubes;
  moves += 1;
  assert.equal(moves, 1);
  tubes = history.pop();
  moves -= 1;
  assert.equal(moves, 0);
  assert.deepEqual(tubes, [
    [1, 2],
    [2],
    [],
  ]);
});

test('hint returns a legal pour and can see a one-move win', function () {
  var tubes = [[1], [1], [2, 2]];
  var move = hint.hint(tubes, 2);
  assert.ok(move);
  var applied = rules.applyPour(tubes, 2, move.from, move.to);
  assert.ok(applied);
  assert.equal(rules.isWon(applied.tubes, 2), true);
});

test('BFS finds a one-move optimum', function () {
  var result = solver.solveBFS([[1], [1], [2, 2]], 2, 100);
  assert.equal(result.solved, true);
  assert.equal(result.optimal, true);
  assert.equal(result.moves.length, 1);
  assert.equal(rules.replay([[1], [1], [2, 2]], 2, result.moves).ok, true);
});

test('segment lower bound is zero only for a solved rack of full colors', function () {
  assert.equal(rules.segmentLowerBound([[1, 1, 1, 1], [], [2, 2, 2, 2]]), 0);
  assert.ok(rules.segmentLowerBound([[1, 2, 2, 2], [1, 1, 1], [], []]) > 0);
});
