'use strict';

var rules = require('./rules');

/**
 * 轻量提示：对所有合法倒法做两步前瞻，优先降低「色段数」。
 * 纯搬移（把一整段单色倒进空瓶、底下没有别的颜色）只在没有更好选择时才用。
 */
function uselessRelocate(tubes, move) {
  var src = tubes[move.from];
  var dst = tubes[move.to];
  if (dst.length !== 0) return false;
  return rules.topRun(src) === src.length;
}

function scoreState(tubes) {
  return rules.segmentLowerBound(tubes);
}

function hint(tubes, capacity) {
  var moves = rules.legalMoves(tubes, capacity);
  if (!moves.length) return null;
  var best = null;
  var bestScore = Infinity;
  var bestUseless = true;

  for (var i = 0; i < moves.length; i++) {
    var move = moves[i];
    var applied = rules.applyPour(tubes, capacity, move.from, move.to);
    if (!applied) continue;
    var useless = uselessRelocate(tubes, move);
    var score = scoreState(applied.tubes);
    if (rules.isWon(applied.tubes, capacity)) score = -100;

    var follow = rules.legalMoves(applied.tubes, capacity);
    var followBest = score;
    for (var j = 0; j < follow.length; j++) {
      var m2 = follow[j];
      if (uselessRelocate(applied.tubes, m2)) continue;
      var a2 = rules.applyPour(applied.tubes, capacity, m2.from, m2.to);
      if (!a2) continue;
      var s2 = rules.isWon(a2.tubes, capacity) ? -100 : scoreState(a2.tubes);
      if (s2 < followBest) followBest = s2;
    }
    score = followBest;

    var better =
      score < bestScore ||
      (score === bestScore && bestUseless && !useless) ||
      (score === bestScore &&
        useless === bestUseless &&
        best &&
        move.count > best.count);
    if (better) {
      bestScore = score;
      bestUseless = useless;
      best = move;
    }
  }
  return best;
}

module.exports = { hint: hint, uselessRelocate: uselessRelocate };
