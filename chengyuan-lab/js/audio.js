'use strict';

function createAudio(isOn) {
  function play(name) {
    if (!isOn()) return;
    if (typeof wx === 'undefined' || !wx.createInnerAudioContext) return;
    try {
      var audio = wx.createInnerAudioContext();
      audio.src = 'audio/' + name + '.wav';
      audio.volume = name === 'win' ? 0.95 : 0.8;
      audio.obeyMuteSwitch = true;
      var release = function () {
        try {
          if (audio.destroy) audio.destroy();
        } catch (err) {}
      };
      if (audio.onEnded) audio.onEnded(release);
      if (audio.onError) audio.onError(release);
      audio.play();
    } catch (err) {}
  }

  function vibrate(kind) {
    if (typeof wx === 'undefined' || !wx.vibrateShort) return;
    try {
      wx.vibrateShort({ type: kind || 'light' });
    } catch (err) {
      try {
        wx.vibrateShort();
      } catch (err2) {}
    }
  }

  return { play: play, vibrate: vibrate };
}

module.exports = { createAudio: createAudio };
