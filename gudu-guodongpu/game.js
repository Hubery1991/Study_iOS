'use strict';

/**
 * 咕嘟果冻铺
 * 微信小游戏入口。用微信开发者工具打开本目录即可预览。
 * 字符串形式列出音频和字体，避免上传时被「过滤无依赖文件」裁掉。
 */
var ASSET_MANIFEST = [
  'audio/tap.wav',
  'audio/button.wav',
  'audio/pour.wav',
  'audio/cap.wav',
  'audio/error.wav',
  'audio/win.wav',
  'fonts/ZCOOLKuaiLe-subset.ttf',
  'fonts/OFL.txt',
];

require('./js/main.js');

module.exports = { ASSET_MANIFEST: ASSET_MANIFEST };
