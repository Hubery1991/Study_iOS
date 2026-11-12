'use strict';

/**
 * 校验 200 关：
 * 1. 重新生成，必须与 data/levels.js、data/solutions.js 逐关一致（种子稳定）。
 * 2. 用规则回放参考解，必须到达胜利。
 * 3. 对标记为最短步数的关卡，再用 BFS 求解器独立核对步数。
 *
 * 用法：node scripts/validate-levels.js
 */

var rules = require('../js/core/rules');
var solver = require('./solver');
var gen = require('./generate-levels');
var levels = require('../data/levels');
var solutions = require('../data/solutions');

function sameLevel(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

function validate() {
  var failures = [];
  function fail(id, msg) {
    failures.push('L' + id + ': ' + msg);
  }

  if (!levels.levels || levels.levels.length !== 200) {
    fail(0, 'expected 200 levels, got ' + (levels.levels ? levels.levels.length : 0));
  }
  if (!solutions || solutions.length !== 200) {
    fail(0, 'expected 200 solutions');
  }

  var exactChecked = 0;
  for (var i = 0; i < levels.levels.length; i++) {
    var lv = levels.levels[i];
    var id = i + 1;
    if (!lv || lv.id !== id) fail(id, 'id mismatch');
    if (lv.colors < 2 || lv.colors > 12) fail(id, 'colors ' + lv.colors);
    if (lv.empty < 1 || lv.empty > 2) fail(id, 'empty ' + lv.empty);
    if ([3, 4, 5].indexOf(lv.capacity) < 0) fail(id, 'capacity ' + lv.capacity);
    if (!lv.tubes || lv.tubes.length !== lv.colors + lv.empty) fail(id, 'tube count');
    var counts = rules.colorCounts(lv.tubes);
    for (var c = 1; c <= lv.colors; c++) {
      if (counts[c] !== lv.capacity) fail(id, 'color ' + c + ' count ' + counts[c]);
    }
    var extraColors = Object.keys(counts).some(function (k) {
      return Number(k) < 1 || Number(k) > lv.colors;
    });
    if (extraColors) fail(id, 'unexpected color');
    if (id > 8) {
      for (var t = 0; t < lv.tubes.length; t++) {
        if (rules.isComplete(lv.tubes[t], lv.capacity)) fail(id, 'starts with a finished bottle');
      }
    }
    if (rules.isWon(lv.tubes, lv.capacity)) fail(id, 'already won');
    var lower = rules.segmentLowerBound(lv.tubes);
    if (lv.par < lower) fail(id, 'par ' + lv.par + ' below lower bound ' + lower);
    if (lv.goal !== lv.par) fail(id, 'goal should match par');
    if (!(lv.goal2 > lv.goal)) fail(id, 'goal2');
    var sol = solutions[i];
    if (!sol || sol.length !== lv.par) fail(id, 'solution length ' + (sol && sol.length) + ' != par ' + lv.par);
    var replayed = rules.replay(lv.tubes, lv.capacity, sol || []);
    if (!replayed.ok) fail(id, 'solution replay failed at ' + replayed.at);

    if (lv.exact && lv.par !== lower) {
      exactChecked++;
      var bfs = solver.solveBFS(lv.tubes, lv.capacity, 80000);
      if (!bfs.solved || !bfs.moves || bfs.moves.length !== lv.par) {
        fail(id, 'BFS optimal ' + (bfs.moves && bfs.moves.length) + ' != par ' + lv.par + ' nodes=' + bfs.nodes);
      } else if (!rules.replay(lv.tubes, lv.capacity, bfs.moves).ok) {
        fail(id, 'BFS path does not win');
      }
    } else if (lv.exact && lv.par === lower) {
      exactChecked++;
    }
  }

  var regenerated = gen.generateAll({ quiet: true });
  for (var j = 0; j < 200; j++) {
    if (!sameLevel(regenerated.levels[j], levels.levels[j])) fail(j + 1, 'regenerated level drifted');
    if (JSON.stringify(regenerated.solutions[j]) !== JSON.stringify(solutions[j])) {
      fail(j + 1, 'regenerated solution drifted');
    }
  }

  return {
    failures: failures,
    exactChecked: exactChecked,
    levels: levels.levels.length,
  };
}

if (require.main === module) {
  var started = Date.now();
  var report = validate();
  var ms = Date.now() - started;
  if (report.failures.length) {
    console.error(report.failures.slice(0, 30).join('\n'));
    console.error(report.failures.length + ' failure(s) in ' + ms + 'ms');
    process.exit(1);
  }
  console.log(
    'OK ' + report.levels + ' levels, solver-checked ' + report.exactChecked + ' exact pars, ' + ms + 'ms'
  );
}

module.exports = { validate: validate };
