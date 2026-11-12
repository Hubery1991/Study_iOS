'use strict';

var fs = require('fs');
var path = require('path');
var canvasLib = require('@napi-rs/canvas');
var draw = require('../js/render/draw');
var rules = require('../js/core/rules');
var fx = require('../js/fx');
var levels = require('../data/levels');
var solutions = require('../data/solutions');

var root = path.join(__dirname, '..');
canvasLib.GlobalFonts.registerFromPath(path.join(root, 'fonts', 'ZCOOLKuaiLe-subset.ttf'), 'ZCOOL KuaiLe');

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

function render(state, filename) {
  var scale = 3;
  var logicalW = 390;
  var logicalH = 844;
  var canvas = canvasLib.createCanvas(logicalW * scale, logicalH * scale);
  var ctx = canvas.getContext('2d');
  ctx.scale(scale, scale);
  draw.drawFrame(ctx, {
    w: logicalW,
    h: logicalH,
    safeTop: 54,
    safeBottom: 34,
    bannerH: 0,
    time: state.clock || 1280,
    displayFont: '"ZCOOL KuaiLe"',
    bodyFont: '"ZCOOL KuaiLe"',
  }, state);
  var file = path.join(root, 'screenshots', filename);
  fs.writeFileSync(file, canvas.toBuffer('image/png'));
  console.log(filename, canvas.width + 'x' + canvas.height);
}

function baseSave(extra) {
  var save = {
    v: 1,
    unlocked: 1,
    current: 1,
    stars: {},
    best: {},
    sound: true,
    vibration: true,
    privacy: true,
    clearsSinceAd: 0,
  };
  if (extra) {
    for (var key in extra) save[key] = extra[key];
  }
  return save;
}

function playState(levelId, extra) {
  var level = levels.levels[levelId - 1];
  var state = {
    scene: 'play',
    save: baseSave({ unlocked: levelId, current: levelId }),
    modal: null,
    toast: null,
    clock: 1280,
    particles: [],
    tubes: rules.cloneTubes(level.tubes),
    selected: -1,
    moves: 0,
    undo: [],
    undosLeft: levelId <= 20 ? -1 : 8,
    hintsLeft: 1,
    added: false,
    hint: null,
    anim: null,
    shake: null,
    coach: false,
    skipped: false,
    level: level,
    levelId: levelId,
    scrollY: 0,
    bannerH: 0,
  };
  if (extra) {
    for (var key in extra) state[key] = extra[key];
  }
  return state;
}

var progressed = baseSave({
  unlocked: 16,
  current: 16,
  stars: { 1: 3, 2: 3, 3: 2, 4: 3, 5: 1, 6: 3, 7: 2, 8: 3, 9: 2, 10: 3, 11: 1, 12: 2, 13: 3, 14: 2, 15: 3 },
});

render({
  scene: 'home',
  save: progressed,
  modal: null,
  toast: null,
  clock: 1600,
  particles: [],
  tubes: [],
}, '01-home.png');

render({
  scene: 'select',
  save: progressed,
  modal: null,
  toast: null,
  clock: 900,
  particles: [],
  scrollY: 0,
}, '02-levels.png');

render(playState(3, { selected: 1, moves: 1, undo: [[]] }), '03-early-level.png');
render(playState(200, { moves: 6, undosLeft: 8, hintsLeft: 1 }), '04-hard-level.png');

var winLevel = levels.levels[3];
var solved = rules.replay(winLevel.tubes, winLevel.capacity, solutions[3]);
if (!solved.ok) throw new Error('level 4 solution did not win');
var rng = mulberry32(7);
var particles = fx.spawnConfetti(195, 80, rng, 54);
for (var i = 0; i < particles.length; i++) {
  var slot = i % 3;
  if (slot === 0) {
    particles[i].x = 8 + (i % 4) * 7;
    particles[i].y = 64 + (i * 47) % 720;
  } else if (slot === 1) {
    particles[i].x = 362 + (i % 4) * 7;
    particles[i].y = 72 + (i * 53) % 700;
  } else {
    particles[i].x = 36 + (i * 29) % 318;
    particles[i].y = 16 + (i % 5) * 16;
  }
  particles[i].life = particles[i].max * 0.92;
  particles[i].rot = i * 0.4;
}
render({
  scene: 'win',
  save: progressed,
  modal: null,
  toast: null,
  clock: 2100,
  winAt: 1200,
  winStars: 3,
  skipped: false,
  moves: winLevel.goal,
  particles: particles,
  tubes: solved.tubes,
  level: winLevel,
  levelId: 4,
  selected: -1,
  anim: null,
  hint: null,
  shake: null,
  coach: false,
  added: false,
  undosLeft: -1,
  hintsLeft: 1,
  undo: [],
}, '05-win.png');
