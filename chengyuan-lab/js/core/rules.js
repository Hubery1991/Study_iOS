'use strict';

/**
 * 倒水 / 分装规则（纯函数，不依赖微信运行时）。
 * 试管用数组表示，下标 0 是瓶底，末尾是瓶口。
 * 一次倒出「瓶口连续同色」里装得下的全部，不能只倒一部分。
 * 装满且单色的瓶子会封口，不能再倒出。
 */

function cloneTubes(tubes) {
  return tubes.map(function (tube) {
    return tube.slice();
  });
}

function topColor(tube) {
  return tube.length ? tube[tube.length - 1] : 0;
}

function topRun(tube) {
  if (!tube.length) return 0;
  var color = tube[tube.length - 1];
  var n = 0;
  for (var i = tube.length - 1; i >= 0; i--) {
    if (tube[i] !== color) break;
    n++;
  }
  return n;
}

function isUniform(tube) {
  if (!tube.length) return true;
  var color = tube[0];
  for (var i = 1; i < tube.length; i++) {
    if (tube[i] !== color) return false;
  }
  return true;
}

function isComplete(tube, capacity) {
  return tube.length === capacity && isUniform(tube);
}

function isWon(tubes, capacity) {
  for (var i = 0; i < tubes.length; i++) {
    var tube = tubes[i];
    if (tube.length === 0) continue;
    if (!isComplete(tube, capacity)) return false;
  }
  return true;
}

function pourAmount(tubes, capacity, from, to) {
  if (from === to) return 0;
  if (from < 0 || to < 0 || from >= tubes.length || to >= tubes.length) return 0;
  var src = tubes[from];
  var dst = tubes[to];
  if (!src.length) return 0;
  if (isComplete(src, capacity)) return 0;
  if (dst.length >= capacity) return 0;
  var color = src[src.length - 1];
  if (dst.length && dst[dst.length - 1] !== color) return 0;
  var run = topRun(src);
  var space = capacity - dst.length;
  if (run <= 0 || space <= 0) return 0;
  return Math.min(run, space);
}

function applyPour(tubes, capacity, from, to) {
  var count = pourAmount(tubes, capacity, from, to);
  if (!count) return null;
  var next = cloneTubes(tubes);
  var color = next[from][next[from].length - 1];
  next[from].splice(next[from].length - count, count);
  for (var i = 0; i < count; i++) next[to].push(color);
  return { tubes: next, from: from, to: to, color: color, count: count };
}

function legalMoves(tubes, capacity) {
  var moves = [];
  for (var i = 0; i < tubes.length; i++) {
    if (!tubes[i].length || isComplete(tubes[i], capacity)) continue;
    for (var j = 0; j < tubes.length; j++) {
      if (i === j) continue;
      var count = pourAmount(tubes, capacity, i, j);
      if (count > 0) {
        moves.push({
          from: i,
          to: j,
          count: count,
          color: tubes[i][tubes[i].length - 1],
        });
      }
    }
  }
  return moves;
}

function colorCounts(tubes) {
  var counts = Object.create(null);
  for (var i = 0; i < tubes.length; i++) {
    for (var k = 0; k < tubes[i].length; k++) {
      var c = tubes[i][k];
      counts[c] = (counts[c] || 0) + 1;
    }
  }
  return counts;
}

/** 至少还要多少次「合并」才可能分装完成。每种颜色恰好 capacity 份时，0 等价于已过关。 */
function segmentLowerBound(tubes) {
  var segments = 0;
  var seen = Object.create(null);
  var colors = 0;
  for (var i = 0; i < tubes.length; i++) {
    var tube = tubes[i];
    var prev = 0;
    for (var k = 0; k < tube.length; k++) {
      var c = tube[k];
      if (!seen[c]) {
        seen[c] = true;
        colors++;
      }
      if (c !== prev) {
        segments++;
        prev = c;
      }
    }
  }
  return segments - colors;
}

function canonKey(tubes) {
  var parts = new Array(tubes.length);
  for (var i = 0; i < tubes.length; i++) parts[i] = tubes[i].join(',');
  parts.sort();
  return parts.join('|');
}

function replay(tubes, capacity, moves) {
  var state = cloneTubes(tubes);
  for (var i = 0; i < moves.length; i++) {
    var move = moves[i];
    var from = Array.isArray(move) ? move[0] : move.from;
    var to = Array.isArray(move) ? move[1] : move.to;
    var applied = applyPour(state, capacity, from, to);
    if (!applied) return { ok: false, at: i, tubes: state };
    state = applied.tubes;
  }
  return { ok: isWon(state, capacity), tubes: state, at: moves.length };
}

module.exports = {
  cloneTubes: cloneTubes,
  topColor: topColor,
  topRun: topRun,
  isUniform: isUniform,
  isComplete: isComplete,
  isWon: isWon,
  pourAmount: pourAmount,
  applyPour: applyPour,
  legalMoves: legalMoves,
  colorCounts: colorCounts,
  segmentLowerBound: segmentLowerBound,
  canonKey: canonKey,
  replay: replay,
};
