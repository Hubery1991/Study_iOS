'use strict';

/** 十二色软糖。明度、色相和瓶身花纹都分开，方便辨色。 */
var PALETTE = [
  null,
  { base: '#FF4B6A', light: '#FFD5DE', dark: '#D81B45', ink: '#7A1830' },
  { base: '#FF8C1A', light: '#FFE3C4', dark: '#E06A00', ink: '#8A3E00' },
  { base: '#FFD000', light: '#FFF4C2', dark: '#E0AE00', ink: '#7A5C00' },
  { base: '#37C94A', light: '#D9FFD0', dark: '#149432', ink: '#0E5C22' },
  { base: '#12CFC4', light: '#D2FFFA', dark: '#0B9E96', ink: '#086660' },
  { base: '#3B86FF', light: '#D7E7FF', dark: '#1A5FD0', ink: '#12367A' },
  { base: '#7B59FF', light: '#E4DEFF', dark: '#5A32E0', ink: '#321A84' },
  { base: '#FF59B4', light: '#FFD4EF', dark: '#E03090', ink: '#8A1858' },
  { base: '#C4843C', light: '#FFE3C4', dark: '#8E5418', ink: '#5C320C' },
  { base: '#2E3C9A', light: '#D9DEF8', dark: '#1A2570', ink: '#101848' },
  { base: '#B6D63A', light: '#F2FFC8', dark: '#7C9A14', ink: '#4A5E08' },
  { base: '#D83BD0', light: '#FFD2FB', dark: '#A01498', ink: '#680C60' },
];

function colorOf(id) {
  return PALETTE[id] || PALETTE[1];
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
  var neckH = Math.max(10, b.h * 0.14);
  var bodyY = b.y + neckH * 0.78;
  var bodyH = b.h - neckH * 0.78;
  var inset = Math.max(3.5, b.w * 0.11);
  var inner = {
    x: b.x + inset,
    y: bodyY + b.w * 0.06,
    w: b.w - inset * 2,
    h: bodyH - b.w * 0.16,
  };
  if (inner.h < 12) inner.h = 12;
  inner.cx = inner.x + inner.w / 2;
  inner.bottom = inner.y + inner.h;
  return {
    neckH: neckH,
    bodyY: bodyY,
    bodyH: bodyH,
    inner: inner,
    neckW: b.w * 0.5,
    radius: Math.min(b.w * 0.34, bodyH * 0.28),
  };
}

function drawMotif(ctx, id, x, y, r) {
  ctx.save();
  ctx.translate(x, y);
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';
  ctx.strokeStyle = 'rgba(255,255,255,0.92)';
  ctx.fillStyle = 'rgba(255,255,255,0.92)';
  ctx.lineWidth = Math.max(1.4, r * 0.28);
  paintMotif(ctx, id, r);
  ctx.strokeStyle = 'rgba(70, 28, 48, 0.78)';
  ctx.fillStyle = 'rgba(70, 28, 48, 0.62)';
  ctx.lineWidth = Math.max(1, r * 0.16);
  paintMotif(ctx, id, r * 0.92);
  ctx.restore();
}

function paintMotif(ctx, id, r) {
  ctx.beginPath();
  if (id === 1) {
    ctx.moveTo(0, r * 0.35);
    ctx.bezierCurveTo(-r, -r * 0.15, -r * 0.35, -r, 0, -r * 0.35);
    ctx.bezierCurveTo(r * 0.35, -r, r, -r * 0.15, 0, r * 0.35);
    ctx.fill();
    return;
  }
  if (id === 2) {
    ctx.arc(0, 0, r * 0.42, 0, Math.PI * 2);
    ctx.fill();
    for (var i = 0; i < 8; i++) {
      var a = (i / 8) * Math.PI * 2;
      ctx.moveTo(Math.cos(a) * r * 0.58, Math.sin(a) * r * 0.58);
      ctx.lineTo(Math.cos(a) * r, Math.sin(a) * r);
    }
    ctx.stroke();
    return;
  }
  if (id === 3) {
    starPath(ctx, 0, 0, r, r * 0.45);
    ctx.fill();
    return;
  }
  if (id === 4) {
    ctx.ellipse(0, 0, r * 0.42, r * 0.85, -0.6, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(0, r * 0.7);
    ctx.lineTo(0, -r * 0.7);
    ctx.stroke();
    return;
  }
  if (id === 5) {
    ctx.moveTo(0, -r);
    ctx.bezierCurveTo(r * 0.9, -r * 0.2, r * 0.7, r * 0.7, 0, r);
    ctx.bezierCurveTo(-r * 0.7, r * 0.7, -r * 0.9, -r * 0.2, 0, -r);
    ctx.fill();
    return;
  }
  if (id === 6) {
    ctx.arc(-r * 0.35, r * 0.1, r * 0.38, 0, Math.PI * 2);
    ctx.arc(r * 0.28, r * 0.12, r * 0.32, 0, Math.PI * 2);
    ctx.arc(0, -r * 0.18, r * 0.42, 0, Math.PI * 2);
    ctx.fill();
    return;
  }
  if (id === 7) {
    ctx.moveTo(0, -r);
    ctx.lineTo(r * 0.72, 0);
    ctx.lineTo(0, r);
    ctx.lineTo(-r * 0.72, 0);
    ctx.closePath();
    ctx.fill();
    return;
  }
  if (id === 8) {
    for (var p = 0; p < 5; p++) {
      var ang = (p / 5) * Math.PI * 2 - Math.PI / 2;
      ctx.moveTo(Math.cos(ang) * r * 0.55, Math.sin(ang) * r * 0.55);
      ctx.arc(Math.cos(ang) * r * 0.55, Math.sin(ang) * r * 0.55, r * 0.32, 0, Math.PI * 2);
    }
    ctx.fill();
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.22, 0, Math.PI * 2);
    ctx.fill();
    return;
  }
  if (id === 9) {
    ctx.arc(0, 0, r * 0.78, 0, Math.PI * 2);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(-r * 0.28, -r * 0.2, r * 0.12, 0, Math.PI * 2);
    ctx.arc(r * 0.22, r * 0.16, r * 0.12, 0, Math.PI * 2);
    ctx.arc(r * 0.18, -r * 0.28, r * 0.1, 0, Math.PI * 2);
    ctx.fill();
    return;
  }
  if (id === 10) {
    ctx.arc(-r * 0.05, 0, r * 0.78, 0.7, Math.PI * 2 - 0.15);
    ctx.arc(r * 0.28, -r * 0.08, r * 0.62, Math.PI * 2 - 0.45, 0.85, true);
    ctx.closePath();
    ctx.fill();
    return;
  }
  if (id === 11) {
    ctx.moveTo(0, -r);
    ctx.lineTo(r * 0.86, r * 0.78);
    ctx.lineTo(-r * 0.86, r * 0.78);
    ctx.closePath();
    ctx.fill();
    return;
  }
  ctx.moveTo(-r * 0.7, r * 0.15);
  ctx.lineTo(-r * 0.35, -r * 0.55);
  ctx.lineTo(0, r * 0.05);
  ctx.lineTo(r * 0.35, -r * 0.55);
  ctx.lineTo(r * 0.7, r * 0.15);
  ctx.lineTo(-r * 0.7, r * 0.15);
  ctx.closePath();
  ctx.fill();
  ctx.beginPath();
  ctx.moveTo(-r * 0.78, r * 0.45);
  ctx.lineTo(r * 0.78, r * 0.45);
  ctx.lineWidth = Math.max(ctx.lineWidth, r * 0.22);
  ctx.stroke();
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

function drawPattern(ctx, id, area) {
  ctx.save();
  ctx.beginPath();
  ctx.rect(area.x, area.y, area.w, area.h);
  ctx.clip();
  ctx.strokeStyle = 'rgba(255,255,255,0.28)';
  ctx.fillStyle = 'rgba(255,255,255,0.22)';
  ctx.lineWidth = 1.25;
  var kind = (id - 1) % 6;
  if (kind === 0) {
    for (var y = area.y + 4; y < area.bottom; y += 7) {
      for (var x = area.x + ((Math.floor(y) % 2) ? 3 : 6); x < area.x + area.w; x += 8) {
        ctx.beginPath();
        ctx.arc(x, y, 1.1, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  } else if (kind === 1) {
    for (var sx = area.x + 3; sx < area.x + area.w; sx += 6) {
      ctx.beginPath();
      ctx.moveTo(sx, area.y);
      ctx.lineTo(sx, area.bottom);
      ctx.stroke();
    }
  } else if (kind === 2) {
    for (var d = -area.h; d < area.w + area.h; d += 7) {
      ctx.beginPath();
      ctx.moveTo(area.x + d, area.y);
      ctx.lineTo(area.x + d - area.h, area.bottom);
      ctx.stroke();
    }
  } else if (kind === 3) {
    ctx.beginPath();
    var mid = area.y + area.h * 0.5;
    ctx.moveTo(area.x, mid);
    for (var wx = area.x; wx <= area.x + area.w; wx += 4) {
      ctx.lineTo(wx, mid + Math.sin(wx * 0.8) * 1.6);
    }
    ctx.stroke();
  } else if (kind === 4) {
    ctx.beginPath();
    ctx.arc(area.cx, area.y + area.h * 0.5, Math.min(area.w, area.h) * 0.28, 0, Math.PI * 2);
    ctx.stroke();
  } else {
    for (var hy = area.y + 4; hy < area.bottom; hy += 6) {
      ctx.beginPath();
      ctx.moveTo(area.x + 2, hy);
      ctx.lineTo(area.x + area.w - 2, hy);
      ctx.stroke();
    }
  }
  ctx.restore();
}

function drawBottle(ctx, b, tube, capacity, opts) {
  opts = opts || {};
  var m = bottleMetrics(b);
  var tilt = opts.tilt || 0;
  ctx.save();
  if (opts.alpha != null) ctx.globalAlpha = opts.alpha;
  if (tilt) {
    var pivotX = tilt > 0 ? b.x + b.w * 0.7 : b.x + b.w * 0.3;
    var pivotY = b.y + m.neckH * 0.45;
    ctx.translate(pivotX, pivotY);
    ctx.rotate(tilt);
    ctx.translate(-pivotX, -pivotY);
  }
  if (opts.shake) ctx.translate(opts.shake, 0);

  ctx.fillStyle = 'rgba(120, 70, 120, 0.16)';
  ctx.beginPath();
  ctx.ellipse(b.x + b.w / 2, b.y + b.h + 5, b.w * 0.36, 5.5, 0, 0, Math.PI * 2);
  ctx.fill();

  if (opts.selected || opts.hint) {
    ctx.fillStyle = opts.hint === 'to' ? 'rgba(120, 230, 190, 0.35)' : 'rgba(255, 196, 92, 0.42)';
    ctx.beginPath();
    ctx.ellipse(b.x + b.w / 2, b.y + b.h + 6, b.w * 0.46, 8, 0, 0, Math.PI * 2);
    ctx.fill();
  }

  var neckW = m.neckW;
  var neckX = b.x + (b.w - neckW) / 2;
  roundRect(ctx, b.x, m.bodyY, b.w, m.bodyH, m.radius);
  var shell = ctx.createLinearGradient(b.x, m.bodyY, b.x + b.w, m.bodyY + m.bodyH);
  shell.addColorStop(0, '#FFFFFF');
  shell.addColorStop(0.45, '#E7F3FF');
  shell.addColorStop(1, '#FFE9F5');
  ctx.fillStyle = shell;
  ctx.fill();
  roundRect(ctx, neckX, b.y, neckW, m.neckH + 10, Math.min(8, neckW * 0.35));
  ctx.fillStyle = '#F4FAFF';
  ctx.fill();

  var layers = tube || [];
  var inner = m.inner;
  var layerH = inner.h / capacity;
  ctx.save();
  roundRect(ctx, inner.x, inner.y, inner.w, inner.h, Math.max(6, m.radius * 0.65));
  ctx.clip();
  if (!layers.length) {
    ctx.fillStyle = 'rgba(255,255,255,0.95)';
    ctx.beginPath();
    ctx.arc(inner.cx - inner.w * 0.16, inner.y + inner.h * 0.28, Math.max(3, inner.w * 0.12), 0, Math.PI * 2);
    ctx.arc(inner.cx + inner.w * 0.18, inner.y + inner.h * 0.48, Math.max(2.5, inner.w * 0.09), 0, Math.PI * 2);
    ctx.arc(inner.cx, inner.y + inner.h * 0.7, Math.max(2, inner.w * 0.07), 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = 'rgba(255, 170, 205, 0.35)';
    ctx.beginPath();
    ctx.ellipse(inner.cx, inner.bottom - 8, inner.w * 0.32, 4.5, 0, 0, Math.PI * 2);
    ctx.fill();
  }
  for (var i = 0; i < layers.length; i++) {
    var info = colorOf(layers[i]);
    var y = inner.bottom - (i + 1) * layerH;
    var grad = ctx.createLinearGradient(inner.x, y, inner.x + inner.w, y);
    grad.addColorStop(0, info.dark);
    grad.addColorStop(0.42, info.base);
    grad.addColorStop(1, info.light);
    ctx.fillStyle = grad;
    ctx.fillRect(inner.x - 1, y - 0.5, inner.w + 2, layerH + 1.5);
    drawPattern(ctx, layers[i], {
      x: inner.x,
      y: y,
      w: inner.w,
      h: layerH,
      bottom: y + layerH,
      cx: inner.cx,
    });
    if (layerH >= 14) drawMotif(ctx, layers[i], inner.cx, y + layerH * 0.55, Math.min(layerH * 0.28, inner.w * 0.22));
  }
  if (layers.length) {
    var topY = inner.bottom - layers.length * layerH;
    var topInfo = colorOf(layers[layers.length - 1]);
    ctx.fillStyle = topInfo.light;
    ctx.globalAlpha = 0.9;
    ctx.beginPath();
    ctx.ellipse(inner.cx, topY + 1, inner.w * 0.46, Math.max(2.5, layerH * 0.16), 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;
    ctx.fillStyle = 'rgba(255,255,255,0.45)';
    ctx.beginPath();
    ctx.ellipse(inner.cx - inner.w * 0.12, topY + 1, inner.w * 0.16, Math.max(1.5, layerH * 0.08), 0, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.restore();

  var rim = opts.selected ? '#FFB703' : opts.hint === 'from' ? '#FF9F1C' : opts.hint === 'to' ? '#2EC4B6' : '#F29BC4';
  ctx.strokeStyle = rim;
  ctx.lineWidth = opts.selected || opts.hint ? Math.max(3.2, b.w * 0.075) : Math.max(2.4, b.w * 0.055);
  roundRect(ctx, neckX, b.y, neckW, m.neckH + 10, Math.min(8, neckW * 0.35));
  ctx.stroke();
  roundRect(ctx, b.x, m.bodyY, b.w, m.bodyH, m.radius);
  ctx.stroke();

  ctx.fillStyle = 'rgba(255,255,255,0.55)';
  roundRect(ctx, b.x + b.w * 0.14, m.bodyY + m.bodyH * 0.08, Math.max(4, b.w * 0.14), m.bodyH * 0.42, 8);
  ctx.fill();

  ctx.fillStyle = 'rgba(255,255,255,0.8)';
  ctx.beginPath();
  ctx.ellipse(neckX + neckW * 0.5, b.y + 2.5, neckW * 0.42, 3.2, 0, 0, Math.PI * 2);
  ctx.fill();

  var done = tube && tube.length === capacity && tube.every(function (c, idx, arr) { return c === arr[0]; });
  if (done) drawLid(ctx, b, m, colorOf(tube[0]));
  ctx.restore();
}

function drawLid(ctx, b, m, info) {
  var lidW = b.w * 0.66;
  var lidH = Math.max(12, m.neckH * 0.92);
  var x = b.x + (b.w - lidW) / 2;
  var y = b.y - lidH * 0.35;
  var g = ctx.createLinearGradient(x, y, x, y + lidH);
  g.addColorStop(0, '#FFF6E8');
  g.addColorStop(0.35, info.light);
  g.addColorStop(1, info.dark);
  roundRect(ctx, x, y, lidW, lidH, 7);
  ctx.fillStyle = g;
  ctx.fill();
  ctx.strokeStyle = 'rgba(255,255,255,0.9)';
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.fillStyle = info.base;
  ctx.beginPath();
  ctx.arc(x + lidW / 2, y + 1, lidW * 0.16, 0, Math.PI * 2);
  ctx.fill();
  drawStar(ctx, x + lidW / 2, y + lidH * 0.58, Math.min(6, lidH * 0.28), '#fff', null);
}

function lipPoint(b, dir) {
  var m = bottleMetrics(b);
  return {
    x: dir >= 0 ? b.x + b.w * 0.74 : b.x + b.w * 0.26,
    y: b.y + 2,
    pivotX: dir >= 0 ? b.x + b.w * 0.7 : b.x + b.w * 0.3,
    pivotY: b.y + m.neckH * 0.45,
  };
}

function drawCloud(ctx, x, y, s, alpha) {
  ctx.save();
  ctx.fillStyle = 'rgba(255,255,255,' + (alpha == null ? 0.94 : alpha) + ')';
  ctx.beginPath();
  ctx.ellipse(x, y, 26 * s, 16 * s, 0, 0, Math.PI * 2);
  ctx.ellipse(x + 22 * s, y + 6 * s, 20 * s, 14 * s, 0, 0, Math.PI * 2);
  ctx.ellipse(x - 22 * s, y + 7 * s, 18 * s, 13 * s, 0, 0, Math.PI * 2);
  ctx.ellipse(x + 4 * s, y - 8 * s, 16 * s, 12 * s, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}

function drawMascot(ctx, x, y, s, time, mood) {
  var bob = Math.sin(time / 320) * 4 * s;
  var wave = mood === 'happy' ? Math.sin(time / 160) * 0.4 : Math.sin(time / 500) * 0.08;
  ctx.save();
  ctx.translate(x, y + bob);

  ctx.fillStyle = 'rgba(190, 90, 140, 0.18)';
  ctx.beginPath();
  ctx.ellipse(0, 62 * s, 48 * s, 10 * s, 0, 0, Math.PI * 2);
  ctx.fill();

  ctx.fillStyle = '#FF8EBE';
  blob(ctx, -46 * s, 6 * s, 16 * s, 12 * s, -0.9);
  ctx.save();
  ctx.translate(48 * s, 2 * s);
  ctx.rotate(-0.5 + wave);
  blob(ctx, 10 * s, 0, 16 * s, 12 * s, 0.2);
  ctx.restore();

  var body = ctx.createRadialGradient(-16 * s, -24 * s, 8 * s, 4 * s, 6 * s, 70 * s);
  body.addColorStop(0, '#FFF7FB');
  body.addColorStop(0.38, '#FF9BC8');
  body.addColorStop(1, '#FF5C9A');
  ctx.fillStyle = body;
  ctx.beginPath();
  ctx.ellipse(0, 4 * s, 56 * s, 50 * s, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.lineWidth = 3 * s;
  ctx.strokeStyle = 'rgba(255,255,255,0.88)';
  ctx.stroke();

  ctx.fillStyle = 'rgba(255,255,255,0.66)';
  ctx.beginPath();
  ctx.ellipse(2 * s, 20 * s, 30 * s, 22 * s, 0, 0, Math.PI * 2);
  ctx.fill();

  ctx.fillStyle = '#FF7AA8';
  ctx.beginPath();
  ctx.ellipse(-18 * s, 52 * s, 14 * s, 8 * s, 0, 0, Math.PI * 2);
  ctx.ellipse(20 * s, 52 * s, 14 * s, 8 * s, 0, 0, Math.PI * 2);
  ctx.fill();

  ctx.fillStyle = 'rgba(255, 255, 255, 0.75)';
  ctx.beginPath();
  ctx.ellipse(-22 * s, -16 * s, 14 * s, 8 * s, -0.7, 0, Math.PI * 2);
  ctx.fill();

  ctx.fillStyle = 'rgba(255, 90, 140, 0.4)';
  ctx.beginPath();
  ctx.ellipse(-24 * s, 12 * s, 8 * s, 5 * s, 0, 0, Math.PI * 2);
  ctx.ellipse(26 * s, 12 * s, 8 * s, 5 * s, 0, 0, Math.PI * 2);
  ctx.fill();

  if (mood === 'happy') {
    ctx.strokeStyle = '#5C2740';
    ctx.lineWidth = 3 * s;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.arc(-16 * s, -2 * s, 8 * s, Math.PI * 1.15, Math.PI * 1.9);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(18 * s, -2 * s, 8 * s, Math.PI * 1.25, Math.PI * 1.95);
    ctx.stroke();
  } else {
    eye(ctx, -16 * s, -4 * s, s);
    eye(ctx, 18 * s, -4 * s, s, time);
  }

  ctx.strokeStyle = '#5C2740';
  ctx.lineWidth = 2.4 * s;
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.arc(2 * s, 8 * s, mood === 'happy' ? 12 * s : 10 * s, 0.18 * Math.PI, 0.82 * Math.PI);
  ctx.stroke();
  if (mood === 'happy') {
    ctx.fillStyle = '#FF8FAB';
    ctx.beginPath();
    ctx.ellipse(2 * s, 16 * s, 5 * s, 3.5 * s, 0, 0, Math.PI);
    ctx.fill();
  }

  ctx.fillStyle = '#63D64A';
  ctx.beginPath();
  ctx.ellipse(-4 * s, -48 * s, 8 * s, 13 * s, -0.5, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#8BE06A';
  ctx.beginPath();
  ctx.ellipse(8 * s, -50 * s, 7 * s, 12 * s, 0.45, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#3AAA32';
  ctx.beginPath();
  ctx.ellipse(1 * s, -44 * s, 3 * s, 3 * s, 0, 0, Math.PI * 2);
  ctx.fill();

  ctx.restore();
}

function blob(ctx, x, y, rx, ry, rot) {
  ctx.beginPath();
  ctx.ellipse(x, y, rx, ry, rot, 0, Math.PI * 2);
  ctx.fill();
}

function eye(ctx, x, y, s, time) {
  ctx.fillStyle = '#fff';
  ctx.beginPath();
  ctx.ellipse(x, y, 8.5 * s, 9.5 * s, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#3A2434';
  var look = time ? Math.sin(time / 700) * 1.4 * s : 0;
  ctx.beginPath();
  ctx.arc(x + look, y + 1 * s, 4.3 * s, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#fff';
  ctx.beginPath();
  ctx.arc(x + 2 * s + look, y - 2 * s, 1.7 * s, 0, Math.PI * 2);
  ctx.fill();
}

function drawBackground(ctx, w, h, time) {
  var sky = ctx.createLinearGradient(0, 0, 0, h);
  sky.addColorStop(0, '#8FD6FF');
  sky.addColorStop(0.38, '#FFF3D2');
  sky.addColorStop(0.72, '#FFD0E6');
  sky.addColorStop(1, '#C9B6FF');
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, w, h);

  var sun = ctx.createRadialGradient(w * 0.78, h * 0.16, 8, w * 0.78, h * 0.16, 90);
  sun.addColorStop(0, 'rgba(255,255,245,0.95)');
  sun.addColorStop(0.4, 'rgba(255,214,120,0.55)');
  sun.addColorStop(1, 'rgba(255,214,120,0)');
  ctx.fillStyle = sun;
  ctx.beginPath();
  ctx.arc(w * 0.78, h * 0.16, 90, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#FFE38A';
  ctx.beginPath();
  ctx.arc(w * 0.78, h * 0.16, 28, 0, Math.PI * 2);
  ctx.fill();

  ctx.save();
  ctx.globalAlpha = 0.55;
  ctx.lineWidth = 7;
  ctx.lineCap = 'round';
  var colors = ['#FF8FA8', '#FFD56A', '#B8F28A', '#8EDEFF', '#C7B0FF'];
  for (var i = 0; i < colors.length; i++) {
    ctx.strokeStyle = colors[i];
    ctx.beginPath();
    ctx.arc(w * 0.5, h * 0.34, 150 + i * 8, Math.PI * 1.08, Math.PI * 1.92);
    ctx.stroke();
  }
  ctx.restore();

  drawCloud(ctx, w * 0.18, h * 0.12, 1.15);
  drawCloud(ctx, w * 0.62, h * 0.08, 0.8, 0.85);
  drawCloud(ctx, w * 0.4, h * 0.2, 0.7, 0.8);
  drawCloud(ctx, -10, h * 0.28, 0.9, 0.75);

  var twinkle = 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(time / 280));
  var stars = [
    [w * 0.12, h * 0.22],
    [w * 0.3, h * 0.1],
    [w * 0.88, h * 0.28],
    [w * 0.72, h * 0.22],
    [w * 0.5, h * 0.06],
  ];
  for (var s = 0; s < stars.length; s++) {
    var alpha = s % 2 === 0 ? twinkle : 1.15 - twinkle;
    drawStar(ctx, stars[s][0], stars[s][1], 6, 'rgba(255,255,255,' + (0.45 + alpha * 0.5) + ')', null);
  }

  ctx.fillStyle = '#F7C6E4';
  ctx.beginPath();
  ctx.moveTo(0, h * 0.86);
  ctx.quadraticCurveTo(w * 0.25, h * 0.78, w * 0.5, h * 0.88);
  ctx.quadraticCurveTo(w * 0.75, h * 0.98, w, h * 0.84);
  ctx.lineTo(w, h);
  ctx.lineTo(0, h);
  ctx.fill();
  ctx.fillStyle = '#FFE7F4';
  ctx.beginPath();
  ctx.moveTo(0, h * 0.92);
  ctx.quadraticCurveTo(w * 0.3, h * 0.84, w * 0.62, h * 0.94);
  ctx.quadraticCurveTo(w * 0.84, h * 1.01, w, h * 0.9);
  ctx.lineTo(w, h);
  ctx.lineTo(0, h);
  ctx.fill();
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
      roundRect(ctx, -(p.w || 6) / 2, -(p.h || 8) / 2, p.w || 6, p.h || 8, 2);
      ctx.fill();
    }
    ctx.restore();
  }
}

module.exports = {
  PALETTE: PALETTE,
  colorOf: colorOf,
  roundRect: roundRect,
  bottleMetrics: bottleMetrics,
  drawBottle: drawBottle,
  drawStar: drawStar,
  drawCloud: drawCloud,
  drawMascot: drawMascot,
  drawBackground: drawBackground,
  drawParticles: drawParticles,
  lipPoint: lipPoint,
  drawMotif: drawMotif,
};
