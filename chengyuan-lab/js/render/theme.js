'use strict';

/**
 * 澄渊实验室配色。
 * 背景和面板压暗，水层用高饱和色。第 9–12 色靠纹理和符号与前 8 色区分。
 * 青、黄在深色底上过亮，这里各压暗约 8%。
 */

var INK = '#0B1220';
var PANEL = '#16243A';
var PANEL_2 = '#1E2F4A';
var TEXT = '#E6F1FF';
var TEXT_DIM = '#94A3B8';
var GLASS = 'rgba(230,241,255,0.10)';
var GLASS_LINE = 'rgba(230,241,255,0.35)';
var PRIMARY = '#38BDF8';
var PRIMARY_DOWN = '#0EA5E9';
var ACCENT = '#FB7185';
var SUCCESS = '#22C55E';
var FAILURE = '#EF4444';
var WARNING = '#FBBF24';

var WATERS = [
  null,
  { base: '#3B82F6', texture: 'dots', symbol: 'circle' },
  { base: '#1FC2DB', texture: 'wave', symbol: 'wave' },
  { base: '#34D399', texture: 'diag', symbol: 'triangle' },
  { base: '#E6BC13', texture: 'spark', symbol: 'star' },
  { base: '#FB923C', texture: 'ring', symbol: 'sun' },
  { base: '#F87171', texture: 'vert', symbol: 'square' },
  { base: '#A78BFA', texture: 'diamond', symbol: 'diamond' },
  { base: '#F472B6', texture: 'soft', symbol: 'heart' },
  { base: '#1E40AF', texture: 'cross', symbol: 'plus' },
  { base: '#0E7490', texture: 'horiz', symbol: 'drop' },
  { base: '#6D28D9', texture: 'dash', symbol: 'moon' },
  { base: '#BE185D', texture: 'chevron', symbol: 'hex' },
];

function hexRgb(hex) {
  var n = parseInt(hex.slice(1), 16);
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
}

function rgbHex(r, g, b) {
  function h(v) {
    var s = Math.max(0, Math.min(255, Math.round(v))).toString(16);
    return s.length === 1 ? '0' + s : s;
  }
  return '#' + h(r) + h(g) + h(b);
}

function mix(hex, toward, t) {
  var a = hexRgb(hex);
  var b = hexRgb(toward);
  return rgbHex(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t);
}

for (var wi = 1; wi < WATERS.length; wi++) {
  WATERS[wi].light = mix(WATERS[wi].base, '#FFFFFF', 0.42);
  WATERS[wi].dark = mix(WATERS[wi].base, '#061018', 0.34);
}

function colorOf(id) {
  return WATERS[id] || WATERS[1];
}

function roundRect(ctx, x, y, w, h, r) {
  var radius = Math.max(0, Math.min(r, w / 2, h / 2));
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.arcTo(x + w, y, x + w, y + h, radius);
  ctx.arcTo(x + w, y + h, x, y + h, radius);
  ctx.arcTo(x, y + h, x, y, radius);
  ctx.arcTo(x, y, x + w, y, radius);
  ctx.closePath();
}

function bottleMetrics(b) {
  var neckH = Math.max(12, b.h * 0.12);
  var bodyY = b.y + neckH * 0.72;
  var bodyH = b.h - neckH * 0.72;
  var inset = Math.max(3, b.w * 0.1);
  var inner = {
    x: b.x + inset,
    y: bodyY + b.w * 0.08,
    w: b.w - inset * 2,
    h: Math.max(16, bodyH - b.w * 0.18),
  };
  inner.cx = inner.x + inner.w / 2;
  inner.bottom = inner.y + inner.h;
  return {
    neckH: neckH,
    bodyY: bodyY,
    bodyH: bodyH,
    inner: inner,
    neckW: b.w * 0.46,
    radius: Math.min(b.w * 0.28, 16),
  };
}

function drawTexture(ctx, id, area, assist) {
  var strong = id >= 9;
  var alpha = assist ? (strong ? 0.42 : 0.28) : strong ? 0.34 : 0.16;
  ctx.save();
  ctx.beginPath();
  ctx.rect(area.x, area.y, area.w, area.h + 1);
  ctx.clip();
  ctx.strokeStyle = 'rgba(255,255,255,' + alpha + ')';
  ctx.fillStyle = 'rgba(255,255,255,' + alpha + ')';
  ctx.lineWidth = 1;
  var kind = WATERS[id] ? WATERS[id].texture : 'dots';
  if (kind === 'dots' || kind === 'soft') {
    var step = kind === 'soft' ? 9 : 6;
    for (var y = area.y + 3; y < area.bottom; y += step) {
      for (var x = area.x + 3; x < area.x + area.w; x += step) {
        ctx.beginPath();
        ctx.arc(x, y, kind === 'soft' ? 1.3 : 0.9, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  } else if (kind === 'wave') {
    var mid = area.y + area.h * 0.55;
    ctx.beginPath();
    ctx.moveTo(area.x, mid);
    for (var wx = area.x; wx <= area.x + area.w; wx += 3) {
      ctx.lineTo(wx, mid + Math.sin((wx + area.y) * 0.55) * 1.8);
    }
    ctx.stroke();
  } else if (kind === 'diag' || kind === 'chevron') {
    var gap = kind === 'chevron' ? 5 : 6;
    for (var d = -area.h; d < area.w + area.h; d += gap) {
      ctx.beginPath();
      ctx.moveTo(area.x + d, area.y);
      ctx.lineTo(area.x + d - area.h * (kind === 'chevron' ? 0.6 : 1), area.bottom);
      ctx.stroke();
    }
  } else if (kind === 'spark') {
    for (var sy = area.y + 4; sy < area.bottom; sy += 8) {
      for (var sx = area.x + 4; sx < area.x + area.w; sx += 8) {
        ctx.fillRect(sx, sy, 1.4, 1.4);
      }
    }
  } else if (kind === 'ring') {
    ctx.beginPath();
    ctx.arc(area.cx, area.y + area.h * 0.5, Math.min(area.w, area.h) * 0.28, 0, Math.PI * 2);
    ctx.stroke();
  } else if (kind === 'vert' || kind === 'dash') {
    for (var vx = area.x + 3; vx < area.x + area.w; vx += kind === 'dash' ? 5 : 5) {
      ctx.beginPath();
      if (kind === 'dash') {
        ctx.moveTo(vx, area.y + 2);
        ctx.lineTo(vx, area.y + area.h * 0.4);
        ctx.moveTo(vx, area.y + area.h * 0.6);
        ctx.lineTo(vx, area.bottom - 2);
      } else {
        ctx.moveTo(vx, area.y);
        ctx.lineTo(vx, area.bottom);
      }
      ctx.stroke();
    }
  } else if (kind === 'diamond') {
    ctx.beginPath();
    ctx.moveTo(area.cx, area.y + 2);
    ctx.lineTo(area.x + area.w - 3, area.y + area.h * 0.5);
    ctx.lineTo(area.cx, area.bottom - 2);
    ctx.lineTo(area.x + 3, area.y + area.h * 0.5);
    ctx.closePath();
    ctx.stroke();
  } else if (kind === 'cross') {
    for (var cx = area.x - area.h; cx < area.x + area.w; cx += 6) {
      ctx.beginPath();
      ctx.moveTo(cx, area.y);
      ctx.lineTo(cx + area.h, area.bottom);
      ctx.moveTo(cx + area.h, area.y);
      ctx.lineTo(cx, area.bottom);
      ctx.stroke();
    }
  } else if (kind === 'horiz') {
    for (var hy = area.y + 3; hy < area.bottom; hy += 4) {
      ctx.beginPath();
      ctx.moveTo(area.x + 1, hy);
      ctx.lineTo(area.x + area.w - 1, hy);
      ctx.stroke();
    }
  }
  ctx.restore();
}

function paintSymbol(ctx, id, r) {
  var kind = WATERS[id] ? WATERS[id].symbol : 'circle';
  ctx.beginPath();
  if (kind === 'circle') {
    ctx.arc(0, 0, r * 0.62, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
    return;
  }
  if (kind === 'wave') {
    ctx.moveTo(-r, r * 0.15);
    ctx.quadraticCurveTo(-r * 0.5, -r * 0.55, 0, r * 0.15);
    ctx.quadraticCurveTo(r * 0.5, r * 0.85, r, r * 0.15);
    ctx.stroke();
    return;
  }
  if (kind === 'triangle') {
    ctx.moveTo(0, -r * 0.72);
    ctx.lineTo(r * 0.68, r * 0.58);
    ctx.lineTo(-r * 0.68, r * 0.58);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    return;
  }
  if (kind === 'star') {
    starPath(ctx, 0, 0, r * 0.78, r * 0.34);
    ctx.fill();
    ctx.stroke();
    return;
  }
  if (kind === 'sun') {
    ctx.arc(0, 0, r * 0.38, 0, Math.PI * 2);
    ctx.fill();
    for (var i = 0; i < 8; i++) {
      var a = (i / 8) * Math.PI * 2;
      ctx.moveTo(Math.cos(a) * r * 0.52, Math.sin(a) * r * 0.52);
      ctx.lineTo(Math.cos(a) * r * 0.86, Math.sin(a) * r * 0.86);
    }
    ctx.stroke();
    return;
  }
  if (kind === 'square') {
    ctx.rect(-r * 0.5, -r * 0.5, r, r);
    ctx.fill();
    ctx.stroke();
    return;
  }
  if (kind === 'diamond') {
    ctx.moveTo(0, -r * 0.78);
    ctx.lineTo(r * 0.62, 0);
    ctx.lineTo(0, r * 0.78);
    ctx.lineTo(-r * 0.62, 0);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    return;
  }
  if (kind === 'heart') {
    ctx.moveTo(0, r * 0.55);
    ctx.bezierCurveTo(-r, r * 0.05, -r * 0.55, -r * 0.75, 0, -r * 0.28);
    ctx.bezierCurveTo(r * 0.55, -r * 0.75, r, r * 0.05, 0, r * 0.55);
    ctx.fill();
    ctx.stroke();
    return;
  }
  if (kind === 'plus') {
    ctx.moveTo(-r * 0.72, 0);
    ctx.lineTo(r * 0.72, 0);
    ctx.moveTo(0, -r * 0.72);
    ctx.lineTo(0, r * 0.72);
    ctx.stroke();
    return;
  }
  if (kind === 'drop') {
    ctx.moveTo(0, -r * 0.8);
    ctx.bezierCurveTo(r * 0.7, -r * 0.1, r * 0.55, r * 0.55, 0, r * 0.75);
    ctx.bezierCurveTo(-r * 0.55, r * 0.55, -r * 0.7, -r * 0.1, 0, -r * 0.8);
    ctx.fill();
    ctx.stroke();
    return;
  }
  if (kind === 'moon') {
    ctx.arc(-r * 0.08, 0, r * 0.62, 0.6, Math.PI * 2 - 0.2);
    ctx.arc(r * 0.28, -r * 0.05, r * 0.48, Math.PI * 2 - 0.5, 0.9, true);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    return;
  }
  for (var k = 0; k < 6; k++) {
    var ang = -Math.PI / 2 + (k / 6) * Math.PI * 2;
    var px = Math.cos(ang) * r * 0.7;
    var py = Math.sin(ang) * r * 0.7;
    if (k === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  }
  ctx.closePath();
  ctx.fill();
  ctx.stroke();
}

function drawSymbol(ctx, id, x, y, r) {
  ctx.save();
  ctx.translate(x, y);
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';
  ctx.lineWidth = Math.max(1.5, r * 0.18);
  ctx.strokeStyle = 'rgba(255,255,255,0.95)';
  ctx.fillStyle = 'rgba(255,255,255,0.92)';
  paintSymbol(ctx, id, r);
  ctx.lineWidth = Math.max(1, r * 0.1);
  ctx.strokeStyle = 'rgba(11,18,32,0.8)';
  ctx.fillStyle = 'rgba(11,18,32,0.28)';
  paintSymbol(ctx, id, r * 0.82);
  ctx.restore();
}

function starPath(ctx, x, y, outer, inner) {
  ctx.beginPath();
  for (var i = 0; i < 10; i++) {
    var radius = i % 2 === 0 ? outer : inner;
    var a = -Math.PI / 2 + (i * Math.PI) / 5;
    var px = x + Math.cos(a) * radius;
    var py = y + Math.sin(a) * radius;
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  }
  ctx.closePath();
}

function drawStar(ctx, x, y, r, fill, stroke) {
  starPath(ctx, x, y, r, r * 0.46);
  ctx.fillStyle = fill;
  ctx.fill();
  if (stroke) {
    ctx.strokeStyle = stroke;
    ctx.lineWidth = Math.max(1, r * 0.08);
    ctx.stroke();
  }
}

function drawBackground(ctx, w, h, time) {
  var sky = ctx.createLinearGradient(0, 0, 0, h);
  sky.addColorStop(0, '#0B1220');
  sky.addColorStop(1, '#111D33');
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, w, h);

  ctx.save();
  ctx.strokeStyle = 'rgba(230,241,255,0.045)';
  ctx.lineWidth = 1;
  var step = 32;
  for (var x = 0; x <= w; x += step) {
    ctx.beginPath();
    ctx.moveTo(x + 0.5, 0);
    ctx.lineTo(x + 0.5, h);
    ctx.stroke();
  }
  for (var y = 0; y <= h; y += step) {
    ctx.beginPath();
    ctx.moveTo(0, y + 0.5);
    ctx.lineTo(w, y + 0.5);
    ctx.stroke();
  }
  ctx.restore();

  ctx.save();
  ctx.globalAlpha = 0.55;
  var caustic = ctx.createLinearGradient(0, h * 0.15, w, h * 0.85);
  caustic.addColorStop(0, 'rgba(56,189,248,0)');
  caustic.addColorStop(0.45, 'rgba(56,189,248,0.07)');
  caustic.addColorStop(1, 'rgba(56,189,248,0)');
  ctx.fillStyle = caustic;
  ctx.beginPath();
  ctx.moveTo(0, h * 0.22);
  for (var cx = 0; cx <= w; cx += 8) {
    var wave = Math.sin(cx * 0.02 + time / 900) * 16 + Math.sin(cx * 0.045 - time / 1400) * 8;
    ctx.lineTo(cx, h * 0.38 + wave);
  }
  ctx.lineTo(w, h * 0.7);
  ctx.lineTo(0, h * 0.62);
  ctx.closePath();
  ctx.fill();
  ctx.restore();

  var bubbles = 14;
  for (var i = 0; i < bubbles; i++) {
    var bx = ((i * 97) % 100) / 100 * w;
    var baseY = h - ((time * (0.012 + (i % 5) * 0.004) + i * 80) % (h + 40));
    var br = 1.5 + (i % 4);
    ctx.beginPath();
    ctx.strokeStyle = 'rgba(230,241,255,' + (0.08 + (i % 3) * 0.04) + ')';
    ctx.lineWidth = 1;
    ctx.arc(bx, baseY, br, 0, Math.PI * 2);
    ctx.stroke();
  }

  var vignette = ctx.createRadialGradient(w / 2, h * 0.45, w * 0.2, w / 2, h * 0.5, w * 0.85);
  vignette.addColorStop(0, 'rgba(0,0,0,0)');
  vignette.addColorStop(1, 'rgba(0,0,0,0.28)');
  ctx.fillStyle = vignette;
  ctx.fillRect(0, 0, w, h);
}

function drawBottle(ctx, b, tube, capacity, opts) {
  opts = opts || {};
  var m = bottleMetrics(b);
  var tilt = opts.tilt || 0;
  var assist = !!opts.assist;
  ctx.save();
  if (tilt) {
    var pivotX = tilt > 0 ? b.x + b.w * 0.72 : b.x + b.w * 0.28;
    var pivotY = b.y + m.neckH * 0.35;
    ctx.translate(pivotX, pivotY);
    ctx.rotate(tilt);
    ctx.translate(-pivotX, -pivotY);
  }
  if (opts.shake) ctx.translate(opts.shake, 0);
  if (opts.selected) {
    var scx = b.x + b.w / 2;
    var scy = b.y + b.h * 0.55;
    ctx.translate(scx, scy);
    ctx.scale(1.05, 1.05);
    ctx.translate(-scx, -scy);
  }

  var bodyAlpha = opts.invalid ? 0.35 : 1;
  ctx.save();
  ctx.globalAlpha = bodyAlpha;

  if (opts.selected) {
    ctx.save();
    ctx.shadowColor = PRIMARY;
    ctx.shadowBlur = 22;
    ctx.strokeStyle = 'rgba(56,189,248,0.95)';
    ctx.lineWidth = 6;
    roundRect(ctx, b.x - 3, m.bodyY - 3, b.w + 6, m.bodyH + 6, m.radius + 2);
    ctx.stroke();
    ctx.restore();
  }

  var neckW = m.neckW;
  var neckX = b.x + (b.w - neckW) / 2;
  roundRect(ctx, b.x, m.bodyY, b.w, m.bodyH, m.radius);
  ctx.fillStyle = GLASS;
  ctx.fill();
  roundRect(ctx, neckX, b.y, neckW, m.neckH + 8, Math.min(7, neckW * 0.3));
  ctx.fillStyle = 'rgba(230,241,255,0.08)';
  ctx.fill();

  var layers = tube || [];
  var inner = m.inner;
  var layerH = inner.h / capacity;
  ctx.save();
  roundRect(ctx, inner.x, inner.y, inner.w, inner.h, Math.max(4, m.radius * 0.55));
  ctx.clip();
  var cursor = 0;
  while (cursor < layers.length) {
    var colorId = layers[cursor];
    var runStart = cursor;
    cursor += 1;
    while (cursor < layers.length && layers[cursor] === colorId) cursor += 1;
    var run = cursor - runStart;
    var info = colorOf(colorId);
    var y = inner.bottom - cursor * layerH;
    var blockH = run * layerH;
    var grad = ctx.createLinearGradient(inner.x, y, inner.x + inner.w, y);
    grad.addColorStop(0, info.dark);
    grad.addColorStop(0.5, info.base);
    grad.addColorStop(1, info.light);
    ctx.fillStyle = grad;
    ctx.fillRect(inner.x - 1, y - 0.5, inner.w + 2, blockH + 1);
    drawTexture(ctx, colorId, {
      x: inner.x,
      y: y,
      w: inner.w,
      h: blockH,
      bottom: y + blockH,
      cx: inner.cx,
    }, assist);
    if (assist && layerH >= 10) {
      for (var unit = 0; unit < run; unit++) {
        drawSymbol(
          ctx,
          colorId,
          inner.cx,
          inner.bottom - (runStart + unit + 0.5) * layerH,
          Math.min(layerH * 0.34, inner.w * 0.28)
        );
      }
    }
    if (cursor < layers.length) {
      ctx.fillStyle = 'rgba(6, 12, 22, 0.45)';
      ctx.fillRect(inner.x, y, inner.w, 1.5);
    }
  }
  if (layers.length) {
    var topY = inner.bottom - layers.length * layerH;
    var topInfo = colorOf(layers[layers.length - 1]);
    ctx.fillStyle = topInfo.light;
    ctx.globalAlpha = bodyAlpha * 0.95;
    ctx.beginPath();
    ctx.ellipse(inner.cx, topY + 1, inner.w * 0.46, Math.max(2.4, Math.min(8, layerH * 0.22)), 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = bodyAlpha;
    ctx.fillStyle = 'rgba(255,255,255,0.45)';
    ctx.beginPath();
    ctx.ellipse(inner.cx - inner.w * 0.12, topY, inner.w * 0.18, Math.max(1.2, Math.min(3.5, layerH * 0.08)), 0, 0, Math.PI * 2);
    ctx.fill();
  } else {
    ctx.fillStyle = 'rgba(230,241,255,0.05)';
    ctx.fillRect(inner.x, inner.y, inner.w, inner.h);
  }
  ctx.restore();

  ctx.fillStyle = 'rgba(255,255,255,0.2)';
  roundRect(ctx, b.x + b.w * 0.18, m.bodyY + 12, Math.max(3, b.w * 0.08), Math.min(40, m.bodyH * 0.16), 5);
  ctx.fill();

  var rim = GLASS_LINE;
  var rimWidth = Math.max(1.4, b.w * 0.035);
  if (opts.flash === 'ok') {
    rim = SUCCESS;
    rimWidth = 2.5;
  } else if (opts.flash === 'bad') {
    rim = FAILURE;
    rimWidth = 2.5;
  } else if (opts.hint === 'from') {
    rim = PRIMARY;
    rimWidth = 2.2;
  } else if (opts.hint === 'to') {
    rim = WARNING;
    rimWidth = 2.2;
  }
  ctx.strokeStyle = rim;
  ctx.lineWidth = rimWidth;
  roundRect(ctx, neckX, b.y, neckW, m.neckH + 8, Math.min(7, neckW * 0.3));
  ctx.stroke();
  roundRect(ctx, b.x, m.bodyY, b.w, m.bodyH, m.radius);
  ctx.stroke();

  ctx.strokeStyle = 'rgba(255,255,255,0.34)';
  ctx.lineWidth = 1.25;
  ctx.beginPath();
  ctx.moveTo(b.x + b.w * 0.24, m.bodyY + b.w * 0.18);
  ctx.lineTo(b.x + b.w * 0.24, m.bodyY + Math.min(m.bodyH * 0.22, 36));
  ctx.stroke();

  ctx.fillStyle = 'rgba(230,241,255,0.55)';
  ctx.beginPath();
  ctx.ellipse(neckX + neckW / 2, b.y + 2, neckW * 0.36, 2.2, 0, 0, Math.PI * 2);
  ctx.fill();

  var done = tube && tube.length === capacity && tube.every(function (c) { return c === tube[0]; });
  if (done) drawStopper(ctx, b, m, opts.flash === 'ok');
  ctx.restore();

  if (opts.flash === 'ok' || opts.flash === 'bad') {
    ctx.save();
    ctx.strokeStyle = opts.flash === 'ok' ? SUCCESS : FAILURE;
    ctx.lineWidth = 2.6;
    roundRect(ctx, b.x - 2, m.bodyY - 2, b.w + 4, m.bodyH + 4, m.radius + 1);
    ctx.stroke();
    ctx.restore();
  }
  if (opts.invalid) drawLockGlyph(ctx, b.x + b.w / 2, b.y + b.h * 0.45, Math.max(0.8, b.w / 46));
  if (opts.flash === 'ok') drawCheck(ctx, b.x + b.w - 4, b.y + 6, 7);
  ctx.restore();
}

function drawStopper(ctx, b, m) {
  var lidW = b.w * 0.58;
  var lidH = Math.max(8, m.neckH * 0.7);
  var x = b.x + (b.w - lidW) / 2;
  var y = b.y - lidH * 0.45;
  roundRect(ctx, x, y, lidW, lidH, 4);
  ctx.fillStyle = 'rgba(230,241,255,0.18)';
  ctx.fill();
  ctx.strokeStyle = 'rgba(230,241,255,0.55)';
  ctx.lineWidth = 1.2;
  ctx.stroke();
}

function drawCheck(ctx, x, y, r) {
  ctx.save();
  ctx.translate(x, y);
  ctx.strokeStyle = SUCCESS;
  ctx.fillStyle = 'rgba(34,197,94,0.2)';
  ctx.lineWidth = 1.6;
  ctx.beginPath();
  ctx.arc(0, 0, r, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(-r * 0.4, 0);
  ctx.lineTo(-r * 0.05, r * 0.35);
  ctx.lineTo(r * 0.45, -r * 0.35);
  ctx.stroke();
  ctx.restore();
}

function drawLockGlyph(ctx, x, y, s) {
  ctx.save();
  ctx.translate(x, y);
  ctx.strokeStyle = TEXT;
  ctx.fillStyle = PANEL;
  ctx.lineWidth = 1.6 * s;
  roundRect(ctx, -7 * s, -1 * s, 14 * s, 11 * s, 2);
  ctx.fill();
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(0, -2 * s, 4.5 * s, Math.PI, 0);
  ctx.stroke();
  ctx.restore();
}

function lipPoint(b, dir) {
  var m = bottleMetrics(b);
  return {
    x: dir >= 0 ? b.x + b.w * 0.72 : b.x + b.w * 0.28,
    y: b.y + 2,
    pivotX: dir >= 0 ? b.x + b.w * 0.72 : b.x + b.w * 0.28,
    pivotY: b.y + m.neckH * 0.35,
  };
}

function drawParticles(ctx, list) {
  for (var i = 0; i < list.length; i++) {
    var p = list[i];
    var alpha = Math.max(0, Math.min(1, p.life / (p.max || 800)));
    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.translate(p.x, p.y);
    ctx.rotate(p.rot || 0);
    ctx.fillStyle = p.color;
    if (p.shape === 'circle') {
      ctx.beginPath();
      ctx.arc(0, 0, (p.w || 4) / 2, 0, Math.PI * 2);
      ctx.fill();
    } else {
      roundRect(ctx, -(p.w || 6) / 2, -(p.h || 8) / 2, p.w || 6, p.h || 8, 1.5);
      ctx.fill();
    }
    ctx.restore();
  }
}

function drawSeal(ctx, x, y, r) {
  ctx.save();
  ctx.translate(x, y);
  ctx.fillStyle = 'rgba(34,197,94,0.12)';
  ctx.strokeStyle = SUCCESS;
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.arc(0, 0, r, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.beginPath();
  ctx.moveTo(-r * 0.38, r * 0.02);
  ctx.lineTo(-r * 0.08, r * 0.32);
  ctx.lineTo(r * 0.42, -r * 0.28);
  ctx.stroke();
  ctx.restore();
}

module.exports = {
  INK: INK,
  PANEL: PANEL,
  PANEL_2: PANEL_2,
  TEXT: TEXT,
  TEXT_DIM: TEXT_DIM,
  GLASS: GLASS,
  GLASS_LINE: GLASS_LINE,
  PRIMARY: PRIMARY,
  PRIMARY_DOWN: PRIMARY_DOWN,
  ACCENT: ACCENT,
  SUCCESS: SUCCESS,
  FAILURE: FAILURE,
  WARNING: WARNING,
  WATERS: WATERS,
  colorOf: colorOf,
  roundRect: roundRect,
  bottleMetrics: bottleMetrics,
  drawBottle: drawBottle,
  drawStar: drawStar,
  drawBackground: drawBackground,
  drawParticles: drawParticles,
  drawSeal: drawSeal,
  lipPoint: lipPoint,
};
