'use strict';

var fs = require('fs');
var path = require('path');

var RATE = 22050;

function env(t, attack, release, duration) {
  if (t < attack) return t / attack;
  var left = duration - t;
  if (left < release) return Math.max(0, left / release);
  return 1;
}

function sampleTone(freq, duration, volume, slide) {
  var n = Math.floor(RATE * duration);
  var out = new Array(n);
  for (var i = 0; i < n; i++) {
    var t = i / RATE;
    var f = freq * Math.pow(slide || 1, t / Math.max(duration, 0.001));
    var wave = Math.sin(2 * Math.PI * f * t);
    out[i] = wave * volume * env(t, 0.01, duration * 0.35, duration);
  }
  return out;
}

function mix(into, extra, offset) {
  var start = Math.floor((offset || 0) * RATE);
  for (var i = 0; i < extra.length; i++) {
    var idx = start + i;
    if (!into[idx]) into[idx] = 0;
    into[idx] += extra[i];
  }
}

function noise(duration, volume) {
  var n = Math.floor(RATE * duration);
  var out = new Array(n);
  var last = 0;
  for (var i = 0; i < n; i++) {
    var white = Math.random() * 2 - 1;
    last = last * 0.86 + white * 0.14;
    var t = i / RATE;
    out[i] = last * volume * env(t, 0.02, duration * 0.45, duration);
  }
  return out;
}

function encode(samples) {
  var n = samples.length;
  var buffer = Buffer.alloc(44 + n * 2);
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + n * 2, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(RATE, 24);
  buffer.writeUInt32LE(RATE * 2, 28);
  buffer.writeUInt16LE(2, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(n * 2, 40);
  for (var i = 0; i < n; i++) {
    var value = Math.max(-1, Math.min(1, samples[i] || 0));
    buffer.writeInt16LE((value * 32767) | 0, 44 + i * 2);
  }
  return buffer;
}

function write(name, samples) {
  var file = path.join(__dirname, '..', 'audio', name + '.wav');
  fs.writeFileSync(file, encode(samples));
  console.log(name, samples.length);
}

var tap = sampleTone(780, 0.07, 0.45, 0.55);
write('tap', tap);
write('button', sampleTone(620, 0.06, 0.4, 0.7));

var pour = noise(0.32, 0.35);
mix(pour, sampleTone(520, 0.3, 0.18, 0.45));
write('pour', pour);

var cap = [];
mix(cap, sampleTone(880, 0.12, 0.35, 1));
mix(cap, sampleTone(1320, 0.16, 0.3, 1), 0.08);
write('cap', cap);

write('error', sampleTone(196, 0.14, 0.35, 0.8));

var win = [];
mix(win, sampleTone(523, 0.16, 0.32, 1));
mix(win, sampleTone(659, 0.16, 0.32, 1), 0.12);
mix(win, sampleTone(784, 0.16, 0.32, 1), 0.24);
mix(win, sampleTone(1046, 0.28, 0.34, 1), 0.36);
write('win', win);
