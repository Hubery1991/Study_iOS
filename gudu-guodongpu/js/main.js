'use strict';

var config = require('./config');
var rules = require('./core/rules');
var hinting = require('./core/hint');
var levels = require('../data/levels');
var storage = require('./storage');
var audioApi = require('./audio');
var adsApi = require('./ads');
var fx = require('./fx');
var draw = require('./render/draw');

var FREE_UNDO_UNTIL = 20;
var FREE_UNDOS = 8;

function boot() {
  var canvas = wx.createCanvas();
  var ctx = canvas.getContext('2d');
  var save = storage.loadSave();
  var ads = adsApi.createAds(config);
  var audio = audioApi.createAudio(function () { return save.sound; });
  var displayFont = 'sans-serif';
  var bodyFont = 'sans-serif';
  try {
    if (wx.loadFont) {
      var loaded = wx.loadFont('fonts/ZCOOLKuaiLe-subset.ttf');
      if (loaded) {
        displayFont = loaded;
        bodyFont = loaded;
      }
    }
  } catch (err) {}

  var metrics = measure();
  var state = {
    scene: 'home',
    save: save,
    modal: save.privacy ? null : { kind: 'privacy' },
    toast: null,
    clock: 0,
    particles: [],
    tubes: [],
    selected: -1,
    moves: 0,
    undo: [],
    undosLeft: -1,
    hintsLeft: 1,
    added: false,
    hint: null,
    anim: null,
    shake: null,
    coach: false,
    skipped: false,
    level: levels.levels[0],
    levelId: 1,
    winStars: 0,
    winAt: 0,
    scrollY: 0,
    bannerH: 0,
  };

  var touch = null;
  var scrollVelocity = 0;

  function view() {
    return {
      w: metrics.w,
      h: metrics.h,
      safeTop: metrics.safeTop,
      safeBottom: metrics.safeBottom,
      bannerH: state.bannerH,
      time: state.clock,
      displayFont: displayFont,
      bodyFont: bodyFont,
    };
  }

  function measure() {
    var sys = wx.getSystemInfoSync();
    var dpr = sys.pixelRatio || 2;
    var w = sys.screenWidth || sys.windowWidth || 390;
    var h = sys.screenHeight || sys.windowHeight || 844;
    canvas.width = Math.floor(w * dpr);
    canvas.height = Math.floor(h * dpr);
    var safeTop = 24;
    var safeBottom = 12;
    if (sys.safeArea) {
      safeTop = sys.safeArea.top || sys.statusBarHeight || safeTop;
      if (sys.safeArea.bottom) safeBottom = Math.max(0, h - sys.safeArea.bottom);
    } else if (sys.statusBarHeight) {
      safeTop = sys.statusBarHeight;
    }
    metrics = { w: w, h: h, dpr: dpr, safeTop: safeTop, safeBottom: safeBottom };
    return metrics;
  }

  function persist() {
    storage.writeSave(save);
  }

  function toast(text) {
    state.toast = { text: text, until: state.clock + 1700 };
  }

  function vibrate(kind) {
    if (!save.vibration) return;
    audio.vibrate(kind || 'light');
  }

  function openLevel(id) {
    id = Math.max(1, Math.min(200, id));
    if (id > save.unlocked) {
      toast('请先完成上一关');
      return;
    }
    var level = levels.levels[id - 1];
    state.scene = 'play';
    state.level = level;
    state.levelId = id;
    state.tubes = rules.cloneTubes(level.tubes);
    state.initial = rules.cloneTubes(level.tubes);
    state.selected = -1;
    state.moves = 0;
    state.undo = [];
    state.undosLeft = id <= FREE_UNDO_UNTIL ? -1 : FREE_UNDOS;
    state.hintsLeft = 1;
    state.added = false;
    state.hint = null;
    state.anim = null;
    state.shake = null;
    state.coach = id === 1;
    state.skipped = false;
    state.particles = [];
    state.modal = null;
    save.current = id;
    persist();
    audio.play('button');
  }

  function finishLevel(stars, skipped) {
    var id = state.levelId;
    var prev = save.stars[String(id)] || 0;
    if (stars > prev) save.stars[String(id)] = stars;
    if (!skipped) {
      var best = save.best[String(id)];
      if (best == null || state.moves < best) save.best[String(id)] = state.moves;
    }
    if (id >= save.unlocked && id < 200) save.unlocked = id + 1;
    if (id < 200) save.current = id + 1;
    state.skipped = !!skipped;
    state.winStars = stars;
    state.winAt = state.clock;
    state.scene = 'win';
    state.selected = -1;
    state.anim = null;
    state.modal = null;
    state.particles = fx.spawnConfetti(metrics.w / 2, metrics.h * 0.28, Math.random, 72);
    audio.play('win');
    vibrate('medium');
    persist();
  }

  function starsFor(moves) {
    if (moves <= state.level.goal) return 3;
    if (moves <= state.level.goal2) return 2;
    return 1;
  }

  function selectBottle(index) {
    var tube = state.tubes[index];
    if (!tube) return;
    if (!tube.length) {
      toast('这是空瓶');
      audio.play('error');
      return;
    }
    if (rules.isComplete(tube, state.level.capacity)) {
      toast('这瓶已经封好啦');
      audio.play('tap');
      return;
    }
    state.selected = index;
    state.coach = false;
    audio.play('tap');
    vibrate('light');
  }

  function pour(to) {
    var from = state.selected;
    if (from < 0) {
      selectBottle(to);
      return;
    }
    if (from === to) {
      state.selected = -1;
      audio.play('tap');
      return;
    }
    var before = rules.cloneTubes(state.tubes);
    var applied = rules.applyPour(state.tubes, state.level.capacity, from, to);
    if (!applied) {
      if (state.tubes[to].length && !rules.isComplete(state.tubes[to], state.level.capacity)) {
        selectBottle(to);
        return;
      }
      state.shake = { index: to, until: state.clock + 280 };
      audio.play('error');
      vibrate('medium');
      toast('只能倒进同色果冻，或倒进空瓶');
      return;
    }
    state.undo.push(before);
    if (state.undo.length > 80) state.undo.shift();
    state.tubes = applied.tubes;
    state.moves += 1;
    state.selected = -1;
    state.coach = false;
    state.hint = null;
    state.anim = {
      kind: 'pour',
      from: from,
      to: to,
      color: applied.color,
      count: applied.count,
      t: 0,
      dur: 560,
      before: before,
      capped: rules.isComplete(applied.tubes[to], state.level.capacity),
    };
    audio.play('pour');
    vibrate('light');
  }

  function undo() {
    if (state.anim) return;
    if (!state.undo.length) {
      toast('没有可撤销的步骤');
      return;
    }
    if (state.undosLeft === 0) {
      state.modal = { kind: 'ad', reward: 'undo' };
      return;
    }
    state.tubes = state.undo.pop();
    state.moves = Math.max(0, state.moves - 1);
    state.selected = -1;
    state.hint = null;
    if (state.undosLeft > 0) state.undosLeft -= 1;
    audio.play('button');
  }

  function restart() {
    if (state.anim) return;
    if (state.moves > 0 || state.added) {
      state.modal = { kind: 'restart' };
      return;
    }
    openLevel(state.levelId);
  }

  function askTube() {
    if (state.added) {
      toast('本关已经加过瓶子啦');
      return;
    }
    state.modal = { kind: 'ad', reward: 'tube' };
  }

  function askHint() {
    if (state.hintsLeft <= 0) {
      state.modal = { kind: 'ad', reward: 'hint' };
      return;
    }
    var move = hinting.hint(state.tubes, state.level.capacity);
    if (!move) {
      toast('现在没有合适的倒法');
      audio.play('error');
      return;
    }
    state.hintsLeft -= 1;
    state.hint = { from: move.from, to: move.to, born: state.clock };
    state.selected = move.from;
    toast('先倒亮起来的瓶子');
    audio.play('tap');
  }

  function askSkip() {
    if (state.scene !== 'play') return;
    state.modal = { kind: 'ad', reward: 'skip' };
  }

  function grant(reward, viaDev) {
    if (viaDev && config.devRewardToast) toast('广告暂不可用，奖励已发放');
    if (reward === 'undo') {
      if (state.undosLeft < 0) return;
      state.undosLeft += 5;
      if (!(viaDev && config.devRewardToast)) toast('获得 5 次撤销');
      return;
    }
    if (reward === 'tube') {
      if (state.added) return;
      state.tubes.push([]);
      state.added = true;
      state.selected = -1;
      if (!(viaDev && config.devRewardToast)) toast('得到一个空瓶');
      audio.play('cap');
      return;
    }
    if (reward === 'hint') {
      state.hintsLeft += 1;
      if (!(viaDev && config.devRewardToast)) toast('获得 1 次提示');
      askHint();
      return;
    }
    if (reward === 'skip') {
      finishLevel(Math.max(1, save.stars[String(state.levelId)] || 0) > 1 ? save.stars[String(state.levelId)] : 1, true);
    }
  }

  function watchAd(reward) {
    state.modal = null;
    ads.showRewarded().then(function (result) {
      if (!result) {
        toast('没有看完视频，奖励未发放');
        return;
      }
      grant(reward, result === 'dev');
    });
  }

  function goNext() {
    var finished = state.levelId;
    if (finished >= config.interstitialMinLevel) {
      save.clearsSinceAd += 1;
      if (save.clearsSinceAd >= config.interstitialEvery) {
        save.clearsSinceAd = 0;
        ads.showInterstitial();
      }
      persist();
    }
    if (finished >= 200) {
      state.scene = 'home';
      state.particles = [];
      return;
    }
    openLevel(finished + 1);
  }

  function share() {
    var levelId = state.levelId || save.current || 1;
    var title = '我在咕嘟果冻铺闯到第 ' + levelId + ' 关，来一起分装彩虹果冻！';
    try {
      wx.shareAppMessage({
        title: title,
        query: 'from=share&level=' + levelId,
      });
    } catch (err) {
      toast('当前环境不能分享');
    }
  }

  function onTap(x, y) {
    var target = draw.pick(view(), state, x, y);
    if (!target) return;
    if (target.id === 'modal-block' || target.id === 'win-block' || target.id === 'scroll-area') return;
    if (target.id === 'modal-dismiss') {
      state.modal = null;
      return;
    }
    if (target.id === 'modal-primary') {
      var kind = state.modal && state.modal.kind;
      if (kind === 'privacy') {
        save.privacy = true;
        state.modal = null;
        persist();
        audio.play('button');
        return;
      }
      if (kind === 'restart') {
        state.modal = null;
        openLevel(state.levelId);
        return;
      }
      if (kind === 'ad') {
        var reward = state.modal.reward;
        watchAd(reward);
        return;
      }
    }
    if (target.id === 'modal-secondary') {
      state.modal = null;
      audio.play('button');
      return;
    }
    if (target.id === 'toggle-sound') {
      save.sound = !save.sound;
      persist();
      if (save.sound) audio.play('button');
      return;
    }
    if (target.id === 'toggle-vibration') {
      save.vibration = !save.vibration;
      persist();
      vibrate('light');
      return;
    }
    if (target.id === 'modal-skip' || target.id === 'skip') {
      askSkip();
      return;
    }
    if (target.id === 'start') {
      var level = Math.min(save.current || 1, save.unlocked || 1);
      openLevel(level);
      return;
    }
    if (target.id === 'select' || target.id === 'win-levels') {
      state.scene = 'select';
      state.modal = null;
      state.particles = [];
      var focus = Math.max(0, (save.current || 1) - 1);
      var max = draw.maxScroll(view(), state);
      state.scrollY = Math.max(0, Math.min(max, Math.floor(focus / 5) * 78 - 40));
      audio.play('button');
      return;
    }
    if (target.id === 'back') {
      state.scene = 'home';
      audio.play('button');
      return;
    }
    if (target.id === 'settings') {
      state.modal = { kind: 'settings' };
      audio.play('button');
      return;
    }
    if (target.id === 'share') {
      share();
      return;
    }
    if (target.id === 'level') {
      openLevel(target.levelId);
      return;
    }
    if (state.scene === 'win') {
      if (target.id === 'win-next') {
        goNext();
        return;
      }
      if (target.id === 'win-replay') {
        openLevel(state.levelId);
        return;
      }
    }
    if (state.scene !== 'play' || state.anim) return;
    if (target.id === 'undo') undo();
    else if (target.id === 'restart') restart();
    else if (target.id === 'tube') askTube();
    else if (target.id === 'hint') askHint();
    else if (target.id === 'bottle') pour(target.index);
  }

  wx.onTouchStart(function (event) {
    var point = event.touches && event.touches[0];
    if (!point) return;
    touch = {
      x: point.clientX,
      y: point.clientY,
      sx: point.clientX,
      sy: point.clientY,
      scroll: state.scrollY,
      moved: false,
      lastY: point.clientY,
      lastT: Date.now(),
    };
    scrollVelocity = 0;
  });

  wx.onTouchMove(function (event) {
    if (!touch) return;
    var point = event.touches && event.touches[0];
    if (!point) return;
    if (Math.abs(point.clientX - touch.sx) + Math.abs(point.clientY - touch.sy) > 10) touch.moved = true;
    if (state.scene === 'select' && !state.modal) {
      var max = draw.maxScroll(view(), state);
      state.scrollY = Math.max(0, Math.min(max, touch.scroll - (point.clientY - touch.sy)));
      var now = Date.now();
      var dt = Math.max(1, now - touch.lastT);
      scrollVelocity = (touch.lastY - point.clientY) / dt;
      touch.lastY = point.clientY;
      touch.lastT = now;
    }
  });

  wx.onTouchEnd(function () {
    if (!touch) return;
    if (!touch.moved) onTap(touch.x, touch.y);
    touch = null;
  });

  wx.onTouchCancel && wx.onTouchCancel(function () { touch = null; });

  if (wx.onWindowResize) {
    wx.onWindowResize(function () { measure(); });
  }

  try {
    wx.showShareMenu && wx.showShareMenu({ withShareTicket: false, menus: ['shareAppMessage'] });
    wx.onShareAppMessage && wx.onShareAppMessage(function () {
      var levelId = state.levelId || save.current || 1;
      return {
        title: '我在咕嘟果冻铺闯到第 ' + levelId + ' 关，来一起分装彩虹果冻！',
        query: 'from=share&level=' + levelId,
      };
    });
  } catch (err) {}

  if (config.bannerEnabled) {
    var shown = ads.showBanner(metrics.w, metrics.h - 100);
    if (shown) state.bannerH = 90;
  }

  try {
    var launch = wx.getLaunchOptionsSync ? wx.getLaunchOptionsSync() : null;
    var query = launch && launch.query;
    if (query && query.level && save.privacy) {
      var sharedLevel = parseInt(query.level, 10);
      if (sharedLevel >= 1 && sharedLevel <= save.unlocked) openLevel(sharedLevel);
    }
  } catch (err) {}

  var last = Date.now();
  function frame() {
    var now = Date.now();
    var dt = Math.min(34, now - last);
    last = now;
    state.clock += dt;
    if (state.anim) {
      state.anim.t += dt / state.anim.dur;
      if (state.anim.t >= 1) {
        var anim = state.anim;
        state.anim = null;
        if (anim.capped) {
          audio.play('cap');
          var box = draw.layoutPlay(view(), state).bottles[anim.to];
          if (box) {
            var splash = fx.spawnSplash(box.x + box.w / 2, box.y + 12, themeColor(anim.color), Math.random);
            state.particles = state.particles.concat(splash);
          }
        }
        if (rules.isWon(state.tubes, state.level.capacity)) finishLevel(starsFor(state.moves), false);
      }
    }
    if (state.scene === 'select' && !touch && scrollVelocity) {
      var maxScroll = draw.maxScroll(view(), state);
      state.scrollY = Math.max(0, Math.min(maxScroll, state.scrollY + scrollVelocity * dt));
      scrollVelocity *= 0.92;
      if (Math.abs(scrollVelocity) < 0.01) scrollVelocity = 0;
    }
    fx.stepParticles(state.particles, dt);
    ctx.setTransform(metrics.dpr, 0, 0, metrics.dpr, 0, 0);
    draw.drawFrame(ctx, view(), state);
    if (canvas.requestAnimationFrame) canvas.requestAnimationFrame(frame);
    else if (typeof requestAnimationFrame === 'function') requestAnimationFrame(frame);
    else setTimeout(frame, 16);
  }
  frame();
}

function themeColor(id) {
  var palette = ['#FF4B6A', '#FF8C1A', '#FFD000', '#37C94A', '#12CFC4', '#3B86FF', '#7B59FF', '#FF59B4', '#C4843C', '#2E3C9A', '#B6D63A', '#D83BD0'];
  return palette[(id - 1) % palette.length];
}

if (typeof wx !== 'undefined' && wx.createCanvas) boot();
