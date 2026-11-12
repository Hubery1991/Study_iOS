'use strict';

var rules = require('../js/core/rules');

/**
 * BFS（可证明最短）+ 启发式定向搜索。
 * 状态按试管内容排序后去重：瓶子本身没有左右之分。
 */

function solveBFS(tubes, capacity, maxNodes) {
  if (rules.isWon(tubes, capacity)) {
    return { moves: [], nodes: 1, optimal: true, method: 'bfs', solved: true };
  }
  var startTubes = rules.cloneTubes(tubes);
  var queue = [{ tubes: startTubes, parent: -1, move: null }];
  var seen = new Set();
  seen.add(rules.canonKey(startTubes));
  var nodes = 0;
  var head = 0;

  while (head < queue.length) {
    if (nodes >= maxNodes) {
      return { moves: null, nodes: nodes, optimal: false, method: 'bfs', solved: false, limited: true };
    }
    var cur = queue[head++];
    nodes++;
    var moves = rules.legalMoves(cur.tubes, capacity);
    for (var i = 0; i < moves.length; i++) {
      var move = moves[i];
      var applied = rules.applyPour(cur.tubes, capacity, move.from, move.to);
      if (!applied) continue;
      var key = rules.canonKey(applied.tubes);
      if (seen.has(key)) continue;
      seen.add(key);
      var node = {
        tubes: applied.tubes,
        parent: head - 1,
        move: [move.from, move.to],
      };
      if (rules.isWon(applied.tubes, capacity)) {
        return {
          moves: reconstruct(queue, node),
          nodes: nodes,
          optimal: true,
          method: 'bfs',
          solved: true,
        };
      }
      queue.push(node);
    }
  }
  return { moves: null, nodes: nodes, optimal: true, method: 'bfs', solved: false, exhausted: true };
}

function reconstruct(queue, node) {
  var moves = [];
  var cur = node;
  while (cur && cur.move) {
    moves.push(cur.move);
    cur = cur.parent >= 0 ? queue[cur.parent] : null;
  }
  moves.reverse();
  return moves;
}

function disorder(tubes) {
  return rules.segmentLowerBound(tubes);
}

/**
 * 束搜索：按「步数 + 色段启发」保留最有希望的局面。不保证最短，但能在大关卡里找到解。
 */
function solveBeam(tubes, capacity, maxNodes, width) {
  if (rules.isWon(tubes, capacity)) {
    return { moves: [], nodes: 1, optimal: false, method: 'beam', solved: true };
  }
  width = width || 64;
  var beam = [{ tubes: rules.cloneTubes(tubes), moves: [] }];
  var seen = new Set();
  seen.add(rules.canonKey(tubes));
  var nodes = 0;

  for (var depth = 0; depth < 96; depth++) {
    var next = [];
    for (var b = 0; b < beam.length; b++) {
      var cur = beam[b];
      var moves = rankMoves(cur.tubes, capacity);
      for (var i = 0; i < moves.length; i++) {
        if (nodes >= maxNodes) {
          return { moves: null, nodes: nodes, optimal: false, method: 'beam', solved: false, limited: true };
        }
        var move = moves[i];
        var applied = rules.applyPour(cur.tubes, capacity, move.from, move.to);
        if (!applied) continue;
        nodes++;
        var key = rules.canonKey(applied.tubes);
        if (seen.has(key)) continue;
        seen.add(key);
        var path = cur.moves.concat([[move.from, move.to]]);
        if (rules.isWon(applied.tubes, capacity)) {
          return { moves: path, nodes: nodes, optimal: false, method: 'beam', solved: true };
        }
        var h = disorder(applied.tubes);
        next.push({ tubes: applied.tubes, moves: path, f: path.length + h * 3 + move.rank });
      }
    }
    if (!next.length) break;
    next.sort(function (a, b) {
      return a.f - b.f;
    });
    beam = next.slice(0, width);
  }
  return { moves: null, nodes: nodes, optimal: false, method: 'beam', solved: false };
}

function rankMoves(tubes, capacity) {
  var moves = rules.legalMoves(tubes, capacity);
  for (var i = 0; i < moves.length; i++) {
    var move = moves[i];
    var src = tubes[move.from];
    var dst = tubes[move.to];
    var rank = 0;
    var color = src[src.length - 1];
    var dstUniform = !dst.length || dst.every(function (c) { return c === color; });
    if (dst.length && dstUniform && dst.length + move.count === capacity && rules.topRun(src) === move.count) {
      rank -= 8;
    } else if (dst.length && dst[dst.length - 1] === color) {
      rank -= 3;
    }
    if (!dst.length && rules.topRun(src) === src.length) rank += 6;
    else if (!dst.length) rank += 1;
    move.rank = rank;
  }
  moves.sort(function (a, b) {
    if (a.rank !== b.rank) return a.rank - b.rank;
    if (a.from !== b.from) return a.from - b.from;
    return a.to - b.to;
  });
  return moves;
}

/**
 * 在已知解的相邻局面之间做短程 BFS，把明显绕路的片段换成更短的倒法。
 */
function shortenWitness(tubes, capacity, witness, maxNodes) {
  var check = rules.replay(tubes, capacity, witness);
  if (!check.ok) return witness.slice();
  var best = witness.slice();
  var budget = maxNodes;
  var guard = 0;
  while (guard < 8 && budget > 2000) {
    guard++;
    var improved = false;
    var state = rules.cloneTubes(tubes);
    var states = [rules.cloneTubes(state)];
    for (var i = 0; i < best.length; i++) {
      var applied = rules.applyPour(state, capacity, best[i][0], best[i][1]);
      state = applied.tubes;
      states.push(rules.cloneTubes(state));
    }
    var span = best.length > 24 ? 8 : 12;
    for (var a = 0; a < states.length && budget > 1000; a++) {
      var bMax = Math.min(states.length - 1, a + span);
      for (var b = bMax; b >= a + 2; b--) {
        var sliceLen = b - a;
        var sub = solveBFS(states[a], capacity, Math.min(8000, budget));
        budget -= sub.nodes || 0;
        if (sub.solved && sub.moves && sub.moves.length < sliceLen) {
          var endKey = rules.canonKey(states[b]);
          var replayed = rules.replay(states[a], capacity, sub.moves);
          if (replayed.ok || rules.canonKey(replayed.tubes) === endKey || rules.isWon(replayed.tubes, capacity)) {
            if (rules.canonKey(replayed.tubes) === endKey || (replayed.ok && rules.isWon(states[b], capacity))) {
              best = best.slice(0, a).concat(sub.moves).concat(best.slice(b));
              improved = true;
              break;
            }
          }
        }
        if (improved) break;
      }
      if (improved) break;
    }
    if (!improved) break;
    var again = rules.replay(tubes, capacity, best);
    if (!again.ok) return witness.slice();
  }
  return best;
}

function solve(tubes, capacity, options) {
  options = options || {};
  var maxNodes = options.maxNodes || 20000;
  var witness = options.witness || null;
  var colors = options.colors || 12;
  var result = null;

  var tryBFS = colors <= 5 || (witness && witness.length <= 14);
  if (tryBFS) {
    result = solveBFS(tubes, capacity, Math.min(maxNodes, witness && witness.length <= 10 ? maxNodes : 60000));
    if (result.solved) return result;
  }

  var beam = solveBeam(tubes, capacity, Math.min(maxNodes, 40000), colors >= 10 ? 48 : 72);
  if (beam.solved) {
    if (witness && witness.length < beam.moves.length) {
      return {
        moves: witness,
        nodes: beam.nodes,
        optimal: false,
        method: 'witness',
        solved: true,
      };
    }
    return beam;
  }

  if (witness && witness.length) {
    var replayed = rules.replay(tubes, capacity, witness);
    if (replayed.ok) {
      return {
        moves: witness,
        nodes: (result ? result.nodes : 0) + beam.nodes,
        optimal: false,
        method: 'witness',
        solved: true,
      };
    }
  }
  return beam.solved ? beam : { moves: null, nodes: beam.nodes, optimal: false, method: 'beam', solved: false };
}

module.exports = {
  solveBFS: solveBFS,
  solveBeam: solveBeam,
  solve: solve,
  shortenWitness: shortenWitness,
  disorder: disorder,
};
