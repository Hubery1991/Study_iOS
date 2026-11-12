'use strict';

var KEY = 'gudu_guodongpu_v1';

function defaults() {
  return {
    v: 1,
    unlocked: 1,
    current: 1,
    stars: {},
    best: {},
    sound: true,
    vibration: true,
    privacy: false,
    clearsSinceAd: 0,
  };
}

function normalize(raw) {
  var save = defaults();
  if (!raw || typeof raw !== 'object') return save;
  save.unlocked = clampInt(raw.unlocked, 1, 200);
  save.current = clampInt(raw.current, 1, save.unlocked);
  save.sound = raw.sound !== false;
  save.vibration = raw.vibration !== false;
  save.privacy = !!raw.privacy;
  save.clearsSinceAd = clampInt(raw.clearsSinceAd, 0, 99);
  save.stars = normalizeMap(raw.stars, 0, 3);
  save.best = normalizeMap(raw.best, 0, 999);
  return save;
}

function normalizeMap(map, min, max) {
  var out = {};
  if (!map || typeof map !== 'object') return out;
  for (var key in map) {
    if (!Object.prototype.hasOwnProperty.call(map, key)) continue;
    var id = parseInt(key, 10);
    var value = parseInt(map[key], 10);
    if (!id || id < 1 || id > 200 || isNaN(value)) continue;
    out[String(id)] = Math.max(min, Math.min(max, value));
  }
  return out;
}

function clampInt(value, min, max) {
  var n = parseInt(value, 10);
  if (isNaN(n)) return min;
  return Math.max(min, Math.min(max, n));
}

function loadSave() {
  try {
    var raw = wx.getStorageSync(KEY);
    if (!raw) return defaults();
    if (typeof raw === 'string') raw = JSON.parse(raw);
    return normalize(raw);
  } catch (err) {
    return defaults();
  }
}

function writeSave(save) {
  try {
    wx.setStorageSync(KEY, save);
  } catch (err) {}
}

module.exports = {
  KEY: KEY,
  defaults: defaults,
  normalize: normalize,
  loadSave: loadSave,
  writeSave: writeSave,
};
