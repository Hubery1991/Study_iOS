'use strict';

var theme = require('./theme');
var rules = require('../core/rules');

function fonts(view) {
  return {
    display: view.displayFont || 'sans-serif',
    body: view.bodyFont || view.displayFont || 'sans-serif',
  };
}

function setFont(ctx, size, family, weight) {
  ctx.font = (weight || 400) + ' ' + size + 'px ' + family;
}

function fitSize(ctx, text, maxWidth, size, family, weight) {
  var next = size;
  while (next > 11) {
    setFont(ctx, next, family, weight);
    if (ctx.measureText(text).width <= maxWidth) return next;
    next -= 1;
  }
  setFont(ctx, next, family, weight);
  return next;
}

function fillCenter(ctx, text, rect, size, family, color, weight) {
  var used = fitSize(ctx, text, rect.w - 16, size, family, weight || 400);
  setFont(ctx, used, family, weight || 400);
  ctx.fillStyle = color;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, rect.x + rect.w / 2, rect.y + rect.h / 2 + 1);
}

function wrapText(ctx, text, maxWidth) {
  var lines = [];
  var line = '';
  for (var i = 0; i < text.length; i++) {
    var ch = text.charAt(i);
    if (ch === '\n') {
      lines.push(line);
      line = '';
      continue;
    }
    var next = line + ch;
    if (line && ctx.measureText(next).width > maxWidth) {
      lines.push(line);
      line = ch;
    } else {
      line = next;
    }
  }
  if (line) lines.push(line);
  return lines;
}

function hit(rect, x, y) {
  return !!rect && x >= rect.x && y >= rect.y && x <= rect.x + rect.w && y <= rect.y + rect.h;
}

function layoutBottles(view, count, selected, locked) {
  var top = view.safeTop + 118;
  var bottomLimit = view.h - Math.max(view.safeBottom, 8) - (view.bannerH || 0) - 118;
  var availW = view.w - 16;
  var availH = Math.max(120, bottomLimit - top);
  var rows = count > 6 ? 2 : 1;
  var cols = Math.ceil(count / rows);
  var gapY = rows > 1 ? 18 : 0;
  var slotW = availW / cols;
  var slotH = (availH - gapY) / rows;
  var bw = Math.min(slotW - (count > 10 ? 6 : 10), 84);
  var bh = Math.min(slotH - 10, bw / 0.36, 248);
  bw = Math.min(bw, bh * 0.4);
  if (bw < 28) {
    bw = 28;
    bh = Math.min(slotH - 8, bw / 0.36);
  }
  var bottles = [];
  var minX = Infinity;
  var minY = Infinity;
  var maxX = 0;
  var maxY = 0;
  var gridTop = top + Math.max(0, (availH - (rows * bh + gapY)) / 2);
  for (var i = 0; i < count; i++) {
    var row = Math.floor(i / cols);
    var col = i % cols;
    var rowCount = Math.min(cols, count - row * cols);
    var rowWidth = rowCount * slotW;
    var rowX = (view.w - rowWidth) / 2;
    var x = rowX + col * slotW + (slotW - bw) / 2;
    var y = gridTop + row * (bh + gapY);
    if (!locked && selected === i) y -= Math.min(14, bh * 0.08);
    bottles.push({ x: x, y: y, w: bw, h: bh, index: i });
    minX = Math.min(minX, x);
    minY = Math.min(minY, y);
    maxX = Math.max(maxX, x + bw);
    maxY = Math.max(maxY, y + bh);
  }
  var tray = {
    x: minX - 12,
    y: minY - 16,
    w: maxX - minX + 24,
    h: maxY - minY + 28,
  };
  return { bottles: bottles, tray: tray };
}

function toolbarRect(view) {
  var h = 74;
  var bottom = view.h - Math.max(view.safeBottom, 8) - (view.bannerH || 0);
  return { x: 12, y: bottom - h - 18, w: view.w - 24, h: h };
}

function layoutPlay(view, state) {
  var count = state.tubes.length;
  var locked = !!(state.anim || state.scene === 'win');
  var grid = layoutBottles(view, count, state.selected, locked);
  var bar = toolbarRect(view);
  var gap = 8;
  var bw = (bar.w - gap * 3) / 4;
  var buttons = [];
  var ids = ['undo', 'restart', 'tube', 'hint'];
  for (var i = 0; i < ids.length; i++) {
    buttons.push({
      id: ids[i],
      x: bar.x + i * (bw + gap),
      y: bar.y,
      w: bw,
      h: bar.h,
    });
  }
  var gear = { id: 'settings', x: view.w - 58, y: view.safeTop + 8, w: 44, h: 44 };
  var skip = {
    id: 'skip',
    x: view.w / 2 - 70,
    y: bar.y + bar.h + 2,
    w: 140,
    h: 22,
  };
  return {
    bottles: grid.bottles,
    tray: grid.tray,
    buttons: buttons,
    gear: gear,
    skip: skip,
  };
}

function layoutHome(view) {
  var w = Math.min(280, view.w - 64);
  var x = (view.w - w) / 2;
  var card = { x: 32, y: view.h * 0.52, w: view.w - 64, h: 72 };
  var y = card.y + card.h + 16;
  return {
    card: card,
    start: { id: 'start', x: x, y: y, w: w, h: 56 },
    select: { id: 'select', x: x, y: y + 66, w: w, h: 48 },
    settings: { id: 'settings', x: x, y: y + 124, w: (w - 12) / 2, h: 42 },
    share: { id: 'share', x: x + (w - 12) / 2 + 12, y: y + 124, w: (w - 12) / 2, h: 42 },
  };
}

function layoutSelect(view, state) {
  var cols = view.w < 360 ? 4 : 5;
  var pad = 16;
  var gap = 8;
  var top = view.safeTop + 64;
  var cellW = (view.w - pad * 2 - gap * (cols - 1)) / cols;
  var cellH = cellW * 1.12;
  var unlocked = state.save.unlocked;
  var cells = [];
  for (var i = 1; i <= 200; i++) {
    var index = i - 1;
    var col = index % cols;
    var row = Math.floor(index / cols);
    cells.push({
      id: 'level',
      levelId: i,
      x: pad + col * (cellW + gap),
      y: top + row * (cellH + gap) - (state.scrollY || 0),
      w: cellW,
      h: cellH,
      locked: i > unlocked,
      stars: (state.save.stars && state.save.stars[i]) || 0,
      current: i === state.save.current,
    });
  }
  var rows = Math.ceil(200 / cols);
  var contentH = top + rows * (cellH + gap) + view.safeBottom + 20;
  return {
    back: { id: 'back', x: 14, y: view.safeTop + 8, w: 44, h: 44 },
    cells: cells,
    maxScroll: Math.max(0, contentH - view.h),
    cols: cols,
  };
}

function layoutModal(view, state) {
  var w = Math.min(320, view.w - 40);
  var h = state.modal && state.modal.kind === 'settings' ? 360 : 280;
  if (state.modal && state.modal.kind === 'privacy') h = 300;
  var rect = { x: (view.w - w) / 2, y: (view.h - h) / 2, w: w, h: h };
  var primary = { id: 'modal-primary', x: rect.x + 22, y: rect.y + rect.h - 112, w: rect.w - 44, h: 48 };
  var secondary = { id: 'modal-secondary', x: rect.x + 22, y: rect.y + rect.h - 56, w: rect.w - 44, h: 40 };
  if (state.modal && state.modal.kind === 'privacy') {
    primary = { id: 'modal-primary', x: rect.x + 22, y: rect.y + rect.h - 70, w: rect.w - 44, h: 48 };
    secondary = null;
  }
  var sound = { id: 'toggle-sound', x: rect.x + rect.w - 86, y: rect.y + 92, w: 64, h: 32 };
  var vibration = { id: 'toggle-vibration', x: rect.x + rect.w - 86, y: rect.y + 140, w: 64, h: 32 };
  var skip = { id: 'modal-skip', x: rect.x + 22, y: rect.y + 196, w: rect.w - 44, h: 44 };
  return { card: rect, primary: primary, secondary: secondary, sound: sound, vibration: vibration, skip: skip };
}

function drawFrame(ctx, view, state) {
  var font = fonts(view);
  theme.drawBackground(ctx, view.w, view.h, view.time || 0);
  if (state.scene === 'home') drawHome(ctx, view, state, font);
  else if (state.scene === 'select') drawSelect(ctx, view, state, font);
  else drawPlay(ctx, view, state, font);
  if (state.scene === 'win') drawWin(ctx, view, state, font);
  if (state.particles && state.particles.length) theme.drawParticles(ctx, state.particles);
  if (state.modal) drawModal(ctx, view, state, font);
  if (state.toast && view.time < state.toast.until) drawToast(ctx, view, state, font);
}

function drawHome(ctx, view, state, font) {
  var title = '咕嘟果冻铺';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.lineJoin = 'round';
  var titleSize = fitSize(ctx, title, view.w - 48, 48, font.display, 400);
  setFont(ctx, titleSize, font.display, 400);
  ctx.lineWidth = 8;
  ctx.strokeStyle = '#FF6B9D';
  ctx.strokeText(title, view.w / 2, view.safeTop + 78);
  ctx.fillStyle = '#FFFDFE';
  ctx.fillText(title, view.w / 2, view.safeTop + 78);

  setFont(ctx, 15, font.body, 400);
  ctx.fillStyle = '#7A4560';
  ctx.fillText('把同色果冻倒进同一个瓶子', view.w / 2, view.safeTop + 118);

  theme.drawMascot(ctx, view.w / 2, view.h * 0.4, 1.15, view.time || 0, 'idle');
  drawMiniBottle(ctx, 42, view.h * 0.36, 46, 128, [3, 3, 3, 3]);
  drawMiniBottle(ctx, view.w - 88, view.h * 0.38, 42, 116, [6, 6, 6, 6]);

  var stars = totalStars(state.save);
  var cleared = clearedCount(state.save);
  var ui = layoutHome(view);
  var card = ui.card;
  paintCard(ctx, card, 20);
  theme.drawStar(ctx, card.x + 36, card.y + 36, 11, '#FFC857', '#FFB703');
  setFont(ctx, 16, font.body, 400);
  ctx.fillStyle = '#8A4B68';
  ctx.textAlign = 'left';
  ctx.textBaseline = 'middle';
  ctx.fillText('已通过 ' + cleared + ' / 200 关', card.x + 58, card.y + 26);
  setFont(ctx, 13, font.body, 400);
  ctx.fillStyle = '#B06B88';
  ctx.fillText('星星 ' + stars + ' / 600', card.x + 58, card.y + 48);

  var continueLabel = homePrimaryLabel(state.save);
  paintButton(ctx, ui.start, continueLabel, 'primary', font, 22);
  paintButton(ctx, ui.select, '选择关卡', 'ghost', font, 18);
  paintButton(ctx, ui.settings, '设置', 'glass', font, 15);
  paintButton(ctx, ui.share, '分享', 'glass', font, 15);

  setFont(ctx, 12, font.body, 400);
  ctx.fillStyle = 'rgba(122, 69, 96, 0.8)';
  ctx.textAlign = 'center';
  ctx.fillText('进度只保存在这台设备上', view.w / 2, view.h - Math.max(view.safeBottom, 8) - 8);
}

function homePrimaryLabel(save) {
  var started = save.unlocked > 1 || (save.stars && save.stars[1]);
  if (!started) return '开始游戏';
  var level = Math.min(save.current || save.unlocked || 1, save.unlocked || 1);
  return '继续第 ' + level + ' 关';
}

function drawMiniBottle(ctx, x, y, w, h, tube) {
  ctx.save();
  ctx.translate(0, Math.sin((x + y) / 40) * 0);
  theme.drawBottle(ctx, { x: x, y: y, w: w, h: h }, tube, tube.length, {});
  ctx.restore();
}

function drawSelect(ctx, view, state, font) {
  var ui = layoutSelect(view, state);
  ctx.save();
  ctx.beginPath();
  ctx.rect(0, view.safeTop + 58, view.w, view.h);
  ctx.clip();
  for (var i = 0; i < ui.cells.length; i++) {
    var cell = ui.cells[i];
    if (cell.y + cell.h < view.safeTop + 50 || cell.y > view.h) continue;
    drawLevelCell(ctx, cell, font);
  }
  ctx.restore();

  var header = ctx.createLinearGradient(0, 0, 0, view.safeTop + 64);
  header.addColorStop(0, 'rgba(143, 214, 255, 0.96)');
  header.addColorStop(1, 'rgba(255, 243, 210, 0.0)');
  ctx.fillStyle = header;
  ctx.fillRect(0, 0, view.w, view.safeTop + 66);

  paintCircleButton(ctx, ui.back, 'back');
  setFont(ctx, 22, font.display, 400);
  ctx.fillStyle = '#7A3050';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('选择关卡', view.w / 2, view.safeTop + 30);
  setFont(ctx, 12, font.body, 400);
  ctx.fillStyle = '#9A5874';
  ctx.textAlign = 'right';
  ctx.fillText(totalStars(state.save) + ' 颗星', view.w - 16, view.safeTop + 30);
}

function drawLevelCell(ctx, cell, font) {
  paintCard(ctx, cell, 14);
  if (cell.current && !cell.locked) {
    ctx.strokeStyle = '#FF6B9D';
    ctx.lineWidth = 3;
    theme.roundRect(ctx, cell.x + 1.5, cell.y + 1.5, cell.w - 3, cell.h - 3, 12);
    ctx.stroke();
  }
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  if (cell.locked) {
    setFont(ctx, 16, font.display, 400);
    ctx.fillStyle = '#C8A8B6';
    ctx.fillText(String(cell.levelId), cell.x + cell.w / 2, cell.y + cell.h * 0.38);
    drawLock(ctx, cell.x + cell.w / 2, cell.y + cell.h * 0.68, 1);
    return;
  }
  setFont(ctx, Math.max(14, cell.w * 0.32), font.display, 400);
  ctx.fillStyle = cell.stars ? '#E24B84' : '#7A4560';
  ctx.fillText(String(cell.levelId), cell.x + cell.w / 2, cell.y + (cell.stars ? cell.h * 0.4 : cell.h * 0.5));
  if (cell.stars > 0) {
    drawStarRow(ctx, cell.x + cell.w / 2, cell.y + cell.h * 0.74, cell.stars, Math.max(4, cell.w * 0.09), true);
  }
}

function drawPlay(ctx, view, state, font) {
  var ui = layoutPlay(view, state);
  var cap = state.level.capacity;
  paintCard(ctx, ui.tray, 28);

  var visual = visualTubes(state);
  var tilt = 0;
  var dir = 1;
  var anim = state.anim;
  if (anim && anim.kind === 'pour') {
    var p = pourProgress(anim.t);
    tilt = Math.sin(Math.min(1, Math.max(0, p)) * Math.PI) * 1.12;
    var fromBox = ui.bottles[anim.from];
    var toBox = ui.bottles[anim.to];
    dir = toBox.x >= fromBox.x ? 1 : -1;
  }

  for (var i = 0; i < ui.bottles.length; i++) {
    if (anim && i === anim.from) continue;
    var hintRole = hintRoleFor(state, view, i);
    var shake = shakeOffset(state, view, i);
    theme.drawBottle(ctx, ui.bottles[i], visual[i], cap, {
      selected: state.selected === i && state.scene !== 'win',
      hint: hintRole,
      shake: shake,
    });
  }

  if (anim && anim.kind === 'pour') {
    var box = ui.bottles[anim.from];
    theme.drawBottle(ctx, box, visual[anim.from], cap, { tilt: dir * tilt });
    drawStream(ctx, ui, state, dir * tilt, visual);
  }

  drawPlayHeader(ctx, view, state, font, ui);
  var labels = ['撤销', '重开', '加瓶', '提示'];
  var icons = ['undo', 'restart', 'tube', 'hint'];
  for (var b = 0; b < ui.buttons.length; b++) {
    var disabled = buttonDisabled(state, ui.buttons[b].id);
    paintTool(ctx, ui.buttons[b], labels[b], icons[b], font, disabled, toolBadge(state, ui.buttons[b].id));
  }
  paintCircleButton(ctx, ui.gear, 'gear');
  if (state.scene === 'play') {
    setFont(ctx, 12, font.body, 400);
    ctx.fillStyle = 'rgba(122, 69, 96, 0.85)';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('看视频跳过本关', ui.skip.x + ui.skip.w / 2, ui.skip.y + 10);
  }
  if (state.coach && state.scene === 'play') drawCoach(ctx, view, font);
}

function visualTubes(state) {
  var anim = state.anim;
  if (!anim || anim.kind !== 'pour') return state.tubes;
  var p = pourProgress(anim.t);
  var out = state.tubes.map(function (tube) { return tube.slice(); });
  var cut = Math.round(anim.count * p);
  var src = anim.before[anim.from].slice(0, anim.before[anim.from].length - cut);
  var dst = anim.before[anim.to].slice();
  for (var i = 0; i < cut; i++) dst.push(anim.color);
  out[anim.from] = src;
  out[anim.to] = dst;
  return out;
}

function pourProgress(t) {
  if (t < 0.14) return 0;
  if (t > 0.86) return 1;
  return (t - 0.14) / 0.72;
}

function drawStream(ctx, ui, state, angle, visual) {
  var anim = state.anim;
  var p = pourProgress(anim.t);
  if (p <= 0.02 || p >= 0.99) return;
  var from = ui.bottles[anim.from];
  var to = ui.bottles[anim.to];
  var dir = angle >= 0 ? 1 : -1;
  var lip = theme.lipPoint(from, dir);
  var start = rotatePoint(lip.x, lip.y, lip.pivotX, lip.pivotY, angle);
  var m = theme.bottleMetrics(to);
  var ratio = Math.min(1, visual[anim.to].length / state.level.capacity);
  var endY = m.inner.bottom - ratio * m.inner.h;
  var end = { x: to.x + to.w / 2, y: Math.max(to.y + 8, endY) };
  var info = theme.colorOf(anim.color);
  ctx.save();
  ctx.strokeStyle = info.base;
  ctx.lineWidth = Math.max(4, from.w * 0.12);
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(start.x, start.y);
  var cx = (start.x + end.x) / 2;
  var cy = Math.max(start.y, end.y) + 10;
  ctx.quadraticCurveTo(cx, cy, end.x, end.y);
  ctx.stroke();
  ctx.fillStyle = info.light;
  for (var i = 0; i < 4; i++) {
    var tt = (0.2 + i * 0.18 + (state.anim.t * 2) % 0.18) % 1;
    var pos = quadPoint(start, { x: cx, y: cy }, end, tt);
    ctx.beginPath();
    ctx.arc(pos.x, pos.y, 2.4, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.restore();
}

function quadPoint(a, c, b, t) {
  var u = 1 - t;
  return {
    x: u * u * a.x + 2 * u * t * c.x + t * t * b.x,
    y: u * u * a.y + 2 * u * t * c.y + t * t * b.y,
  };
}

function rotatePoint(x, y, px, py, angle) {
  var dx = x - px;
  var dy = y - py;
  var cos = Math.cos(angle);
  var sin = Math.sin(angle);
  return { x: px + dx * cos - dy * sin, y: py + dx * sin + dy * cos };
}

function drawPlayHeader(ctx, view, state, font, ui) {
  var levelRect = { x: 14, y: view.safeTop + 10, w: 108, h: 40 };
  paintCard(ctx, levelRect, 20);
  fillCenter(ctx, '第 ' + state.level.id + ' 关', levelRect, 16, font.display, '#7A3050', 400);
  var moveRect = { x: 130, y: view.safeTop + 10, w: view.w - 196, h: 40 };
  paintCard(ctx, moveRect, 20);
  var goal = state.level.goal;
  fillCenter(ctx, state.moves + ' 步 · 目标 ' + goal, moveRect, 14, font.body, '#8A4B68', 400);
  if (ui && ui.gear) {
    /* gear drawn by caller */
  }
}

function drawCoach(ctx, view, font) {
  var rect = { x: 28, y: view.safeTop + 58, w: view.w - 56, h: 48 };
  ctx.fillStyle = 'rgba(255,255,255,0.92)';
  theme.roundRect(ctx, rect.x, rect.y, rect.w, rect.h, 16);
  ctx.fill();
  setFont(ctx, 13, font.body, 400);
  ctx.fillStyle = '#8A4B68';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  var lines = wrapText(ctx, '点一个瓶子，再点另一个。同色或空瓶才能倒入。', rect.w - 20);
  for (var i = 0; i < lines.length; i++) {
    ctx.fillText(lines[i], view.w / 2, rect.y + 16 + i * 16);
  }
}

function drawWin(ctx, view, state, font) {
  ctx.fillStyle = 'rgba(90, 40, 70, 0.28)';
  ctx.fillRect(0, 0, view.w, view.h);
  var card = { x: 28, y: view.h * 0.18, w: view.w - 56, h: view.h * 0.6 };
  paintCard(ctx, card, 28);
  theme.drawMascot(ctx, card.x + card.w / 2, card.y + 78, 0.72, view.time || 0, 'happy');
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  setFont(ctx, 28, font.display, 400);
  ctx.fillStyle = '#E24B84';
  theme.drawStar(ctx, card.x + 42, card.y + 158, 7, '#FFD56A', '#FFB703');
  theme.drawStar(ctx, card.x + card.w - 42, card.y + 172, 6, '#FF8FB8', '#FF6B9D');
  theme.drawStar(ctx, card.x + 58, card.y + 206, 4, '#8EDEFF', '#5EBEFF');
  ctx.fillStyle = '#E24B84';
  ctx.fillText(state.skipped ? '先去下一关吧' : '分装完成！', card.x + card.w / 2, card.y + 168);
  var shown = shownStars(state, view);
  drawStarRow(ctx, card.x + card.w / 2, card.y + 214, shown, 16, true);
  setFont(ctx, 15, font.body, 400);
  ctx.fillStyle = '#8A4B68';
  var line = state.skipped
    ? '已跳过第 ' + state.level.id + ' 关，获得 1 星'
    : '第 ' + state.level.id + ' 关  ·  用了 ' + state.moves + ' 步';
  ctx.fillText(line, card.x + card.w / 2, card.y + 258);
  ctx.fillStyle = '#B06B88';
  setFont(ctx, 13, font.body, 400);
  ctx.fillText('三星目标 ' + state.level.goal + ' 步', card.x + card.w / 2, card.y + 282);

  var ui = layoutWin(view, card, state);
  paintButton(ctx, ui.next, state.level.id >= 200 ? '回到首页' : '下一关', 'primary', font, 20);
  paintButton(ctx, ui.replay, '再玩一次', 'ghost', font, 16);
  paintButton(ctx, ui.levels, '选关', 'glass', font, 16);
  paintButton(ctx, ui.share, '分享', 'glass', font, 16);
}

function shownStars(state, view) {
  if (state.skipped) return 1;
  var age = (view.time || 0) - (state.winAt || 0);
  var stars = state.winStars || 1;
  if (age > 700) return stars;
  if (age > 460) return Math.min(stars, 2);
  if (age > 240) return Math.min(stars, 1);
  return 0;
}

function layoutWin(view, card, state) {
  var y = card.y + card.h - 168;
  var gap = 10;
  var half = (card.w - 36 - gap) / 2;
  return {
    next: { id: 'win-next', x: card.x + 18, y: y, w: card.w - 36, h: 50 },
    replay: { id: 'win-replay', x: card.x + 18, y: y + 60, w: half, h: 44 },
    levels: { id: 'win-levels', x: card.x + 18 + half + gap, y: y + 60, w: half, h: 44 },
    share: { id: 'share', x: card.x + 18, y: y + 112, w: card.w - 36, h: 36 },
  };
}

function drawModal(ctx, view, state, font) {
  var modal = state.modal;
  var ui = layoutModal(view, state);
  ctx.fillStyle = 'rgba(70, 30, 60, 0.35)';
  ctx.fillRect(0, 0, view.w, view.h);
  paintCard(ctx, ui.card, 24);
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  if (modal.kind === 'privacy') {
    setFont(ctx, 22, font.display, 400);
    ctx.fillStyle = '#E24B84';
    ctx.fillText('温馨提示', ui.card.x + ui.card.w / 2, ui.card.y + 48);
    setFont(ctx, 15, font.body, 400);
    ctx.fillStyle = '#7A4560';
    var lines = wrapText(ctx, '关卡进度、音效和震动开关只保存在这台设备上，不会上传个人信息。', ui.card.w - 48);
    for (var i = 0; i < lines.length; i++) {
      ctx.fillText(lines[i], ui.card.x + ui.card.w / 2, ui.card.y + 100 + i * 24);
    }
    paintButton(ctx, ui.primary, '知道啦', 'primary', font, 18);
    return;
  }
  if (modal.kind === 'settings') {
    setFont(ctx, 22, font.display, 400);
    ctx.fillStyle = '#E24B84';
    ctx.fillText('设置', ui.card.x + ui.card.w / 2, ui.card.y + 42);
    drawToggleRow(ctx, ui, '音效', state.save.sound, ui.sound, font);
    drawToggleRow(ctx, ui, '震动', state.save.vibration, ui.vibration, font);
    if (state.scene === 'play') paintButton(ctx, ui.skip, '看视频跳过本关', 'ghost', font, 15);
    paintButton(ctx, ui.secondary, '关闭', 'primary', font, 16);
    return;
  }
  if (modal.kind === 'restart') {
    setFont(ctx, 22, font.display, 400);
    ctx.fillStyle = '#E24B84';
    ctx.fillText('重开本关？', ui.card.x + ui.card.w / 2, ui.card.y + 64);
    setFont(ctx, 15, font.body, 400);
    ctx.fillStyle = '#7A4560';
    var restartLines = wrapText(ctx, '当前步数会清空，加过的空瓶也会收回。', ui.card.w - 48);
    for (var r = 0; r < restartLines.length; r++) {
      ctx.fillText(restartLines[r], ui.card.x + ui.card.w / 2, ui.card.y + 112 + r * 24);
    }
    paintButton(ctx, ui.primary, '确定重开', 'primary', font, 18);
    paintButton(ctx, ui.secondary, '取消', 'ghost', font, 16);
    return;
  }
  if (modal.kind === 'ad') {
    setFont(ctx, 22, font.display, 400);
    ctx.fillStyle = '#E24B84';
    ctx.fillText('看个小视频', ui.card.x + ui.card.w / 2, ui.card.y + 58);
    setFont(ctx, 15, font.body, 400);
    ctx.fillStyle = '#7A4560';
    var copy = adCopy(modal.reward);
    var adLines = wrapText(ctx, copy, ui.card.w - 48);
    for (var a = 0; a < adLines.length; a++) {
      ctx.fillText(adLines[a], ui.card.x + ui.card.w / 2, ui.card.y + 110 + a * 24);
    }
    paintButton(ctx, ui.primary, '观看视频', 'primary', font, 18);
    paintButton(ctx, ui.secondary, '先不了', 'ghost', font, 16);
  }
}

function adCopy(reward) {
  if (reward === 'tube') return '看完后，本关多一个空瓶，用来周转果冻。';
  if (reward === 'undo') return '看完后，增加 5 次撤销。';
  if (reward === 'hint') return '看完后，获得 1 次提示。';
  if (reward === 'skip') return '看完后跳过本关，按 1 星结算并解锁下一关。';
  return '看完视频即可获得奖励。';
}

function drawToggleRow(ctx, ui, label, on, rect, font) {
  setFont(ctx, 16, font.body, 400);
  ctx.fillStyle = '#7A4560';
  ctx.textAlign = 'left';
  ctx.textBaseline = 'middle';
  ctx.fillText(label, ui.card.x + 28, rect.y + rect.h / 2);
  ctx.textAlign = 'center';
  theme.roundRect(ctx, rect.x, rect.y, rect.w, rect.h, 16);
  ctx.fillStyle = on ? '#FF6B9D' : '#E7D5DE';
  ctx.fill();
  ctx.fillStyle = '#fff';
  ctx.beginPath();
  ctx.arc(on ? rect.x + rect.w - 16 : rect.x + 16, rect.y + rect.h / 2, 11, 0, Math.PI * 2);
  ctx.fill();
}

function drawToast(ctx, view, state, font) {
  var text = state.toast.text;
  setFont(ctx, 14, font.body, 400);
  var width = Math.min(view.w - 48, ctx.measureText(text).width + 36);
  var rect = { x: (view.w - width) / 2, y: view.h * 0.46, w: width, h: 40 };
  ctx.fillStyle = 'rgba(90, 40, 70, 0.88)';
  theme.roundRect(ctx, rect.x, rect.y, rect.w, rect.h, 20);
  ctx.fill();
  ctx.fillStyle = '#fff';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, view.w / 2, rect.y + 21);
}

function paintCard(ctx, rect, radius) {
  ctx.save();
  ctx.shadowColor = 'rgba(140, 70, 110, 0.16)';
  ctx.shadowBlur = 18;
  ctx.shadowOffsetY = 8;
  ctx.fillStyle = 'rgba(255,255,255,0.94)';
  theme.roundRect(ctx, rect.x, rect.y, rect.w, rect.h, radius);
  ctx.fill();
  ctx.shadowColor = 'transparent';
  ctx.shadowBlur = 0;
  ctx.strokeStyle = 'rgba(255,255,255,0.98)';
  ctx.lineWidth = 2;
  theme.roundRect(ctx, rect.x, rect.y, rect.w, rect.h, radius);
  ctx.stroke();
  ctx.restore();
}

function paintButton(ctx, rect, text, kind, font, size) {
  ctx.save();
  theme.roundRect(ctx, rect.x, rect.y, rect.w, rect.h, rect.h / 2);
  if (kind === 'primary') {
    var g = ctx.createLinearGradient(rect.x, rect.y, rect.x, rect.y + rect.h);
    g.addColorStop(0, '#FF8FB8');
    g.addColorStop(1, '#FF5C93');
    ctx.fillStyle = g;
    ctx.fill();
    fillCenter(ctx, text, rect, size, font.display, '#fff', 400);
  } else if (kind === 'ghost') {
    ctx.fillStyle = 'rgba(255,255,255,0.92)';
    ctx.fill();
    ctx.strokeStyle = '#FF8FB8';
    ctx.lineWidth = 2;
    ctx.stroke();
    fillCenter(ctx, text, rect, size, font.body, '#E24B84', 400);
  } else {
    ctx.fillStyle = 'rgba(255,255,255,0.88)';
    ctx.fill();
    fillCenter(ctx, text, rect, size, font.body, '#A14B70', 400);
  }
  ctx.restore();
}

function paintCircleButton(ctx, rect, glyph) {
  ctx.save();
  ctx.fillStyle = 'rgba(255,255,255,0.92)';
  ctx.beginPath();
  var cx = rect.x + rect.w / 2;
  var cy = rect.y + rect.h / 2;
  ctx.arc(cx, cy, rect.w / 2, 0, Math.PI * 2);
  ctx.fill();
  ctx.strokeStyle = '#E24B84';
  ctx.fillStyle = '#E24B84';
  ctx.lineWidth = 2.4;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  if (glyph === 'back') {
    ctx.beginPath();
    ctx.moveTo(cx + 6, cy - 7);
    ctx.lineTo(cx - 5, cy);
    ctx.lineTo(cx + 6, cy + 7);
    ctx.stroke();
  } else if (glyph === 'gear') {
    for (var i = 0; i < 3; i++) {
      var gy = cy - 7 + i * 7;
      ctx.beginPath();
      ctx.moveTo(cx - 9, gy);
      ctx.lineTo(cx + 9, gy);
      ctx.stroke();
      var knob = i === 1 ? cx - 3 : cx + 4;
      ctx.beginPath();
      ctx.arc(knob, gy, 2.4, 0, Math.PI * 2);
      ctx.fill();
    }
  }
  ctx.restore();
}

function paintTool(ctx, rect, label, icon, font, disabled, badge) {
  ctx.save();
  theme.roundRect(ctx, rect.x, rect.y, rect.w, rect.h, 18);
  ctx.fillStyle = disabled ? 'rgba(255,255,255,0.55)' : 'rgba(255,255,255,0.94)';
  ctx.fill();
  ctx.strokeStyle = disabled ? 'rgba(255,255,255,0.4)' : 'rgba(255,255,255,1)';
  ctx.lineWidth = 2;
  ctx.stroke();
  drawIcon(ctx, icon, rect.x + rect.w / 2, rect.y + 24, disabled ? '#CDB0BE' : '#E24B84');
  setFont(ctx, 12, font.body, 400);
  ctx.fillStyle = disabled ? '#CDB0BE' : '#8A4B68';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(label, rect.x + rect.w / 2, rect.y + 52);
  if (badge) {
    ctx.fillStyle = '#FF6B9D';
    ctx.beginPath();
    ctx.arc(rect.x + rect.w - 12, rect.y + 12, 9, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#fff';
    ctx.font = '10px sans-serif';
    ctx.fillText(badge, rect.x + rect.w - 12, rect.y + 13);
  }
  ctx.restore();
}

function drawIcon(ctx, icon, x, y, color) {
  ctx.save();
  ctx.strokeStyle = color;
  ctx.fillStyle = color;
  ctx.lineWidth = 2.2;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.translate(x, y);
  if (icon === 'undo') {
    ctx.beginPath();
    ctx.arc(1, 2, 8, Math.PI * 0.9, Math.PI * 2.1);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(-8, 0);
    ctx.lineTo(-4, -5);
    ctx.lineTo(-2, 2);
    ctx.stroke();
  } else if (icon === 'restart') {
    ctx.beginPath();
    ctx.arc(0, 0, 8, 0.4, Math.PI * 1.7);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(6, -7);
    ctx.lineTo(9, -2);
    ctx.lineTo(3, -2);
    ctx.closePath();
    ctx.fill();
  } else if (icon === 'tube') {
    theme.roundRect(ctx, -6, -8, 12, 18, 4);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(8, -2);
    ctx.lineTo(14, -2);
    ctx.moveTo(11, -5);
    ctx.lineTo(11, 1);
    ctx.stroke();
  } else if (icon === 'hint') {
    ctx.beginPath();
    ctx.arc(0, -2, 6, Math.PI * 1.05, Math.PI * 1.95);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(-3, 4);
    ctx.lineTo(3, 4);
    ctx.moveTo(-2, 7);
    ctx.lineTo(2, 7);
    ctx.stroke();
  }
  ctx.restore();
}

function drawLock(ctx, x, y, s) {
  ctx.save();
  ctx.translate(x, y);
  ctx.strokeStyle = '#C9A8B8';
  ctx.fillStyle = '#F3E4EC';
  ctx.lineWidth = 2;
  theme.roundRect(ctx, -8 * s, -2 * s, 16 * s, 12 * s, 3);
  ctx.fill();
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(0, -3 * s, 5 * s, Math.PI, 0);
  ctx.stroke();
  ctx.restore();
}

function drawStarRow(ctx, cx, cy, filled, radius, placeholders) {
  var count = placeholders ? 3 : Math.max(filled, 0);
  if (!placeholders && filled <= 0) {
    setFontSafe(ctx, cx, cy);
    return;
  }
  var gap = radius * 2.3;
  var start = cx - ((count - 1) * gap) / 2;
  for (var i = 0; i < count; i++) {
    var on = i < filled;
    theme.drawStar(ctx, start + i * gap, cy, radius, on ? '#FFC857' : '#F3D5E2', on ? '#FFB703' : '#E7C3D2');
  }
}

function setFontSafe() {}

function hintRoleFor(state, view, index) {
  if (!state.hint) return null;
  if ((view.time || 0) - state.hint.born > 1600) return null;
  if (state.hint.from === index) return 'from';
  if (state.hint.to === index) return 'to';
  return null;
}

function shakeOffset(state, view, index) {
  if (!state.shake || state.shake.index !== index) return 0;
  var left = state.shake.until - (view.time || 0);
  if (left <= 0) return 0;
  return Math.sin(left * 0.12) * 4;
}

function buttonDisabled(state, id) {
  if (state.scene === 'win') return true;
  if (id === 'undo') return state.undo.length === 0;
  if (id === 'tube') return !!state.added;
  return false;
}

function toolBadge(state, id) {
  if (id === 'undo' && state.undosLeft >= 0) return String(state.undosLeft);
  if (id === 'hint' && state.hintsLeft > 0) return String(state.hintsLeft);
  return '';
}

function totalStars(save) {
  var sum = 0;
  var stars = (save && save.stars) || {};
  for (var key in stars) {
    if (Object.prototype.hasOwnProperty.call(stars, key)) sum += stars[key] || 0;
  }
  return sum;
}

function clearedCount(save) {
  return Math.max(0, ((save && save.unlocked) || 1) - 1);
}

function pick(view, state, x, y) {
  if (state.modal) {
    var modal = layoutModal(view, state);
    if (state.modal.kind === 'settings') {
      if (hit(modal.sound, x, y)) return { id: 'toggle-sound' };
      if (hit(modal.vibration, x, y)) return { id: 'toggle-vibration' };
      if (state.scene === 'play' && hit(modal.skip, x, y)) return { id: 'modal-skip' };
      if (modal.secondary && hit(modal.secondary, x, y)) return { id: 'modal-secondary' };
      if (!hit(modal.card, x, y)) return { id: 'modal-dismiss' };
      return { id: 'modal-block' };
    }
    if (hit(modal.primary, x, y)) return { id: 'modal-primary' };
    if (modal.secondary && hit(modal.secondary, x, y)) return { id: 'modal-secondary' };
    if (!hit(modal.card, x, y) && state.modal.kind !== 'privacy') return { id: 'modal-dismiss' };
    return { id: 'modal-block' };
  }
  if (state.scene === 'home') {
    var home = layoutHome(view);
    if (hit(home.start, x, y)) return home.start;
    if (hit(home.select, x, y)) return home.select;
    if (hit(home.settings, x, y)) return home.settings;
    if (hit(home.share, x, y)) return home.share;
    return null;
  }
  if (state.scene === 'select') {
    var select = layoutSelect(view, state);
    if (hit(select.back, x, y)) return select.back;
    if (y < view.safeTop + 58) return null;
    for (var i = select.cells.length - 1; i >= 0; i--) {
      if (hit(select.cells[i], x, y)) return select.cells[i];
    }
    return { id: 'scroll-area', maxScroll: select.maxScroll };
  }
  if (state.scene === 'win') {
    var fakeCard = { x: 28, y: view.h * 0.18, w: view.w - 56, h: view.h * 0.6 };
    var win = layoutWin(view, fakeCard, state);
    if (hit(win.next, x, y)) return win.next;
    if (hit(win.replay, x, y)) return win.replay;
    if (hit(win.levels, x, y)) return win.levels;
    if (hit(win.share, x, y)) return win.share;
    return { id: 'win-block' };
  }
  var play = layoutPlay(view, state);
  if (hit(play.gear, x, y)) return play.gear;
  if (hit(play.skip, x, y)) return play.skip;
  for (var b = 0; b < play.buttons.length; b++) {
    if (hit(play.buttons[b], x, y)) return play.buttons[b];
  }
  for (var n = play.bottles.length - 1; n >= 0; n--) {
    var bottle = play.bottles[n];
    if (hit(bottle, x, y - 8)) return { id: 'bottle', index: bottle.index };
  }
  return null;
}

function maxScroll(view, state) {
  return layoutSelect(view, state).maxScroll;
}

module.exports = {
  drawFrame: drawFrame,
  pick: pick,
  maxScroll: maxScroll,
  layoutPlay: layoutPlay,
  layoutSelect: layoutSelect,
  homePrimaryLabel: homePrimaryLabel,
};
