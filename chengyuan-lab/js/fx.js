'use strict';

var CONFETTI_COLORS = ['#3B82F6', '#1FC2DB', '#34D399', '#E6BC13', '#FB923C', '#F87171', '#A78BFA', '#F472B6'];

function spawnConfetti(x, y, rng, count) {
  rng = rng || Math.random;
  count = count || 70;
  var list = [];
  for (var i = 0; i < count; i++) {
    var angle = rng() * Math.PI * 2;
    var speed = 0.08 + rng() * 0.34;
    list.push({
      x: x + (rng() - 0.5) * 40,
      y: y + (rng() - 0.5) * 16,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed - 0.22,
      life: 1400 + rng() * 900,
      max: 2000,
      rot: rng() * Math.PI,
      spin: (rng() - 0.5) * 0.012,
      w: 6 + rng() * 7,
      h: 8 + rng() * 8,
      color: CONFETTI_COLORS[Math.floor(rng() * CONFETTI_COLORS.length)],
      shape: rng() < 0.5 ? 'rect' : 'circle',
    });
  }
  return list;
}

function spawnSplash(x, y, color, rng) {
  rng = rng || Math.random;
  var list = [];
  for (var i = 0; i < 10; i++) {
    var angle = -Math.PI * 0.15 - rng() * Math.PI * 0.7;
    var speed = 0.06 + rng() * 0.16;
    list.push({
      x: x,
      y: y,
      vx: Math.cos(angle) * speed * (rng() < 0.5 ? -1 : 1),
      vy: -Math.abs(Math.sin(angle) * speed) - 0.04,
      life: 360 + rng() * 200,
      max: 560,
      rot: 0,
      spin: 0,
      w: 3 + rng() * 3,
      h: 3 + rng() * 3,
      color: color,
      shape: 'circle',
    });
  }
  return list;
}

function stepParticles(list, dt) {
  var step = dt > 40 ? 40 : dt;
  for (var i = list.length - 1; i >= 0; i--) {
    var p = list[i];
    p.vy += 0.00055 * step;
    p.x += p.vx * step;
    p.y += p.vy * step;
    p.rot += p.spin * step;
    p.life -= step;
    if (p.life <= 0) list.splice(i, 1);
  }
}

module.exports = {
  spawnConfetti: spawnConfetti,
  spawnSplash: spawnSplash,
  stepParticles: stepParticles,
};
