'use strict';

/**
 * 从已分装好的局面反向倒糖，生成确定可解的关卡。
 * 反向步骤的逆序就是一组合法解。同一 seed 每次生成的 200 关完全一致。
 *
 * 用法：node scripts/generate-levels.js
 */

var fs = require('fs');
var path = require('path');
var rules = require('../js/core/rules');
var solver = require('./solver');

var BASE_SEED = 20261112;

var BANDS = [
  { from: 1, to: 8, colors: 2, empty: 2, capacity: 4, minScramble: 3, maxScramble: 7 },
  { from: 9, to: 20, colors: 3, empty: 2, capacity: 4, minScramble: 6, maxScramble: 13 },
  { from: 21, to: 34, colors: 4, empty: 2, capacity: 4, minScramble: 10, maxScramble: 20 },
  { from: 35, to: 48, colors: 5, empty: 2, capacity: 3, minScramble: 10, maxScramble: 20 },
  { from: 49, to: 64, colors: 5, empty: 2, capacity: 4, minScramble: 14, maxScramble: 26 },
  { from: 65, to: 80, colors: 6, empty: 2, capacity: 4, minScramble: 18, maxScramble: 32 },
  { from: 81, to: 96, colors: 7, empty: 2, capacity: 4, minScramble: 20, maxScramble: 36 },
  { from: 97, to: 112, colors: 8, empty: 2, capacity: 4, minScramble: 22, maxScramble: 40 },
  { from: 113, to: 126, colors: 8, empty: 2, capacity: 5, minScramble: 24, maxScramble: 42 },
  { from: 127, to: 142, colors: 9, empty: 2, capacity: 4, minScramble: 26, maxScramble: 46 },
  { from: 143, to: 156, colors: 10, empty: 2, capacity: 4, minScramble: 28, maxScramble: 48 },
  { from: 157, to: 170, colors: 11, empty: 2, capacity: 4, minScramble: 30, maxScramble: 52 },
  { from: 171, to: 184, colors: 11, empty: 1, capacity: 4, minScramble: 26, maxScramble: 46 },
  { from: 185, to: 192, colors: 12, empty: 2, capacity: 4, minScramble: 32, maxScramble: 56 },
  { from: 193, to: 200, colors: 12, empty: 1, capacity: 4, minScramble: 30, maxScramble: 54 },
];

function mulberry32(seed) {
  var a = seed >>> 0;
  return function () {
    a |= 0;
    a = (a + 0x6D2B79F5) | 0;
    var t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function mixSeed(levelId, salt) {
  var x = Math.imul(levelId, 0x9e3779b1) ^ BASE_SEED ^ Math.imul(salt, 0x85ebca6b);
  x = Math.imul(x ^ (x >>> 16), 0x7feb352d);
  x = Math.imul(x ^ (x >>> 15), 0x846ca68b);
  return (x ^ (x >>> 16)) >>> 0;
}

function shuffle(list, rng) {
  for (var i = list.length - 1; i > 0; i--) {
    var j = Math.floor(rng() * (i + 1));
    var tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
  return list;
}

function bandFor(levelId) {
  for (var i = 0; i < BANDS.length; i++) {
    if (levelId >= BANDS[i].from && levelId <= BANDS[i].to) return BANDS[i];
  }
  throw new Error('no band for level ' + levelId);
}

function lerpInt(a, b, t) {
  return Math.round(a + (b - a) * t);
}

function specFor(levelId) {
  var band = bandFor(levelId);
  var span = Math.max(1, band.to - band.from);
  var t = (levelId - band.from) / span;
  return {
    id: levelId,
    colors: band.colors,
    empty: band.empty,
    capacity: band.capacity,
    steps: lerpInt(band.minScramble, band.maxScramble, t),
  };
}

function solvedState(colors, capacity, empty) {
  var tubes = [];
  for (var c = 1; c <= colors; c++) {
    var tube = [];
    for (var i = 0; i < capacity; i++) tube.push(c);
    tubes.push(tube);
  }
  for (var e = 0; e < empty; e++) tubes.push([]);
  return tubes;
}

function applyReverse(tubes, capacity, rng, recent, forceIndex) {
  var n = tubes.length;
  var dstOrder = [];
  for (var i = 0; i < n; i++) dstOrder.push(i);
  if (forceIndex != null) {
    dstOrder = [forceIndex].concat(dstOrder.filter(function (x) { return x !== forceIndex; }));
  } else {
    shuffle(dstOrder, rng);
  }

  for (var d = 0; d < dstOrder.length; d++) {
    var di = dstOrder[d];
    var dst = tubes[di];
    if (!dst.length) continue;
    var color = dst[dst.length - 1];
    var run = rules.topRun(dst);
    var len = dst.length;
    var srcOrder = [];
    for (var s = 0; s < n; s++) if (s !== di) srcOrder.push(s);
    shuffle(srcOrder, rng);

    for (var si = 0; si < srcOrder.length; si++) {
      var sj = srcOrder[si];
      var src = tubes[sj];
      var space = capacity - src.length;
      if (space <= 0) continue;
      if (src.length && src[src.length - 1] === color) continue;
      var maxK = Math.min(run, space);
      var ks = [];
      for (var k = 1; k <= maxK; k++) {
        if (k === capacity) continue;
        if (k < run || k === len) ks.push(k);
      }
      if (!ks.length) continue;
      var kPick = rng() < 0.72 ? ks[ks.length - 1] : ks[Math.floor(rng() * ks.length)];
      var snapshotSrc = src.slice();
      var snapshotDst = dst.slice();
      var moved = dst.splice(dst.length - kPick, kPick);
      for (var m = 0; m < moved.length; m++) src.push(moved[m]);
      var key = rules.canonKey(tubes);
      if (recent.has(key) || rules.isWon(tubes, capacity)) {
        tubes[sj] = snapshotSrc;
        tubes[di] = snapshotDst;
        src = tubes[sj];
        dst = tubes[di];
        continue;
      }
      recent.add(key);
      return [sj, di];
    }
  }
  return null;
}

function scramble(colors, capacity, emptyCount, steps, rng) {
  var tubes = solvedState(colors, capacity, emptyCount);
  var reverseMoves = [];
  var recent = new Set();
  recent.add(rules.canonKey(tubes));
  var guard = 0;
  while (reverseMoves.length < steps && guard < steps * 50) {
    guard++;
    var force = null;
    if (rng() < 0.55) {
      for (var i = 0; i < tubes.length; i++) {
        if (rules.isComplete(tubes[i], capacity)) {
          force = i;
          break;
        }
      }
    }
    var move = applyReverse(tubes, capacity, rng, recent, force);
    if (!move) break;
    reverseMoves.push(move);
  }
  reverseMoves.reverse();
  return { tubes: tubes, solution: reverseMoves };
}

function countComplete(tubes, capacity) {
  var n = 0;
  for (var i = 0; i < tubes.length; i++) if (rules.isComplete(tubes[i], capacity)) n++;
  return n;
}

function buildOnce(spec, salt) {
  var rng = mulberry32(mixSeed(spec.id, salt));
  var mixed = scramble(spec.colors, spec.capacity, spec.empty, spec.steps, rng);
  var extra = 0;
  while (spec.id > 6 && countComplete(mixed.tubes, spec.capacity) > 0 && extra < spec.steps) {
    var rng2 = rng;
    var recent = new Set();
    recent.add(rules.canonKey(mixed.tubes));
    var force = null;
    for (var i = 0; i < mixed.tubes.length; i++) {
      if (rules.isComplete(mixed.tubes[i], spec.capacity)) {
        force = i;
        break;
      }
    }
    var move = applyReverse(mixed.tubes, spec.capacity, rng2, recent, force);
    if (!move) break;
    mixed.solution.unshift(move);
    extra++;
  }
  return mixed;
}

function acceptable(spec, mixed) {
  if (!mixed.solution.length) return false;
  if (rules.isWon(mixed.tubes, spec.capacity)) return false;
  var replayed = rules.replay(mixed.tubes, spec.capacity, mixed.solution);
  if (!replayed.ok) return false;
  if (spec.id > 8 && countComplete(mixed.tubes, spec.capacity) > 0) return false;
  var lower = rules.segmentLowerBound(mixed.tubes);
  var minMix = spec.id <= 8 ? 1 : Math.min(spec.colors, Math.max(2, Math.round(spec.steps * 0.18)));
  if (lower < minMix && spec.steps > 4) return false;
  var counts = rules.colorCounts(mixed.tubes);
  for (var c = 1; c <= spec.colors; c++) {
    if (counts[c] !== spec.capacity) return false;
  }
  return true;
}

function starGoals(par, exact) {
  if (exact) {
    return {
      goal: par,
      goal2: par + Math.max(2, Math.ceil(par * 0.5)),
    };
  }
  return {
    goal: par,
    goal2: par + Math.max(3, Math.ceil(par * 0.3)),
  };
}

function acceptShorter(tubes, capacity, moves, current) {
  if (!moves || moves.length >= current.length) return false;
  return rules.replay(tubes, capacity, moves).ok;
}

function improvePar(tubes, capacity, witness, colors) {
  var lower = rules.segmentLowerBound(tubes);
  var best = witness;
  var method = 'witness';
  var nodes = 0;
  var exact = best.length === lower;

  if (!exact && (colors <= 7 || witness.length <= 18)) {
    var bfs = solver.solveBFS(tubes, capacity, colors <= 5 ? 90000 : 50000);
    nodes += bfs.nodes;
    if (
      bfs.solved &&
      bfs.moves &&
      bfs.moves.length <= best.length &&
      rules.replay(tubes, capacity, bfs.moves).ok
    ) {
      best = bfs.moves;
      method = 'bfs';
      exact = true;
    }
  }

  if (!exact) {
    var beam = solver.solveBeam(tubes, capacity, 20000, colors >= 10 ? 36 : 48);
    nodes += beam.nodes;
    if (beam.solved && acceptShorter(tubes, capacity, beam.moves, best)) {
      best = beam.moves;
      method = 'beam';
      if (best.length === lower) exact = true;
    }
  }

  if (best.length === lower) {
    exact = true;
    if (method === 'witness') method = 'bound';
  }
  return { par: best.length, exact: exact, method: method, nodes: nodes, moves: best };
}

function generateLevel(levelId, withSolver, saltStart) {
  var spec = specFor(levelId);
  var mixed = null;
  var salt = saltStart || 1;
  var saltEnd = salt + 24;
  for (; salt < saltEnd; salt++) {
    var attempt = buildOnce(spec, salt);
    if (acceptable(spec, attempt)) {
      mixed = attempt;
      break;
    }
  }
  if (!mixed) {
    throw new Error('failed to build level ' + levelId + ' after salts ' + (saltStart || 1) + '-' + (salt - 1));
  }
  var parInfo = {
    par: mixed.solution.length,
    exact: false,
    method: 'witness',
    nodes: 0,
    moves: mixed.solution,
  };
  if (withSolver !== false) {
    parInfo = improvePar(mixed.tubes, spec.capacity, mixed.solution, spec.colors);
  }
  var goals = starGoals(parInfo.par, parInfo.exact);
  return {
    level: {
      id: spec.id,
      capacity: spec.capacity,
      colors: spec.colors,
      empty: spec.empty,
      tubes: mixed.tubes,
      par: parInfo.par,
      exact: parInfo.exact,
      goal: goals.goal,
      goal2: goals.goal2,
    },
    solution: parInfo.moves.map(function (m) { return [m[0], m[1]]; }),
    method: parInfo.method,
    nodes: parInfo.nodes,
    witness: mixed.solution.length,
    salt: salt,
  };
}

function generateAll(options) {
  options = options || {};
  var withSolver = options.withSolver !== false;
  var levels = [];
  var solutions = [];
  var seen = new Set();
  for (var id = 1; id <= 200; id++) {
    var built = null;
    var attempt = null;
    var lastErr = null;
    for (var shift = 0; shift < 6; shift++) {
      try {
        attempt = generateLevel(id, withSolver, 1 + shift * 25);
      } catch (err) {
        lastErr = err;
        continue;
      }
      var key = rules.canonKey(attempt.level.tubes) + '#' + attempt.level.capacity;
      if (seen.has(key)) continue;
      seen.add(key);
      built = attempt;
      break;
    }
    if (!built) {
      throw lastErr || new Error('duplicate or failed level ' + id);
    }
    levels.push(built.level);
    solutions.push(built.solution);
    if (!options.quiet && (id === 1 || id % 10 === 0 || id === 200)) {
      var lv = built.level;
      console.log(
        'L' + id +
          ' colors=' + lv.colors +
          ' empty=' + lv.empty +
          ' cap=' + lv.capacity +
          ' par=' + lv.par +
          (lv.exact ? ' exact' : ' upper') +
          ' via ' + built.method +
          ' witness=' + built.witness +
          ' nodes=' + built.nodes
      );
    }
  }
  return { seed: BASE_SEED, levels: levels, solutions: solutions };
}

function serialize(data) {
  var lines = [];
  lines.push("'use strict';");
  lines.push('');
  lines.push('/**');
  lines.push(' * 澄渊实验室 · 200 关固定关卡');
  lines.push(' * 由 scripts/generate-levels.js 生成，请勿手改。');
  lines.push(' * seed = ' + data.seed + '，同一关对所有玩家完全一致，且带可回放的合法解。');
  lines.push(' */');
  lines.push('module.exports = {');
  lines.push('  version: 1,');
  lines.push('  seed: ' + data.seed + ',');
  lines.push('  levels: [');
  data.levels.forEach(function (level, i) {
    var comma = i === data.levels.length - 1 ? '' : ',';
    lines.push('    ' + JSON.stringify(level) + comma);
  });
  lines.push('  ],');
  lines.push('};');
  lines.push('');
  return lines.join('\n');
}

function serializeSolutions(solutions) {
  var lines = [];
  lines.push("'use strict';");
  lines.push('');
  lines.push('/** 开发用参考解，不打进小游戏包。每项为 [from, to] 列表。 */');
  lines.push('module.exports = [');
  solutions.forEach(function (moves, i) {
    var comma = i === solutions.length - 1 ? '' : ',';
    lines.push('  ' + JSON.stringify(moves) + comma);
  });
  lines.push('];');
  lines.push('');
  return lines.join('\n');
}

function writeAll(data) {
  var root = path.join(__dirname, '..');
  fs.writeFileSync(path.join(root, 'data', 'levels.js'), serialize(data));
  fs.writeFileSync(path.join(root, 'data', 'solutions.js'), serializeSolutions(data.solutions));
}

if (require.main === module) {
  var started = Date.now();
  var data = generateAll();
  writeAll(data);
  console.log('wrote 200 levels in ' + ((Date.now() - started) / 1000).toFixed(1) + 's');
}

module.exports = {
  BASE_SEED: BASE_SEED,
  BANDS: BANDS,
  specFor: specFor,
  generateLevel: generateLevel,
  generateAll: generateAll,
  writeAll: writeAll,
  serialize: serialize,
};
