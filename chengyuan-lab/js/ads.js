'use strict';

function createAds(config) {
  var rewarded = null;
  var pending = null;
  var interstitial = null;
  var banner = null;

  function canUse(factoryName) {
    return config.adsEnabled && typeof wx !== 'undefined' && typeof wx[factoryName] === 'function';
  }

  function ensureRewarded() {
    if (rewarded || !canUse('createRewardedVideoAd')) return;
    try {
      rewarded = wx.createRewardedVideoAd({ adUnitId: config.ads.rewardedVideoAdUnitId });
      rewarded.onError(function () {});
      rewarded.onClose(function (res) {
        var ended = !res || res.isEnded !== false;
        var callback = pending;
        pending = null;
        if (callback) callback(ended ? true : false);
      });
    } catch (err) {
      rewarded = null;
    }
  }

  function showRewarded() {
    return new Promise(function (resolve) {
      ensureRewarded();
      if (!rewarded) {
        resolve(config.grantRewardWhenAdUnavailable ? 'dev' : false);
        return;
      }
      if (pending) {
        resolve(false);
        return;
      }
      pending = resolve;
      var failed = function () {
        pending = null;
        resolve(config.grantRewardWhenAdUnavailable ? 'dev' : false);
      };
      try {
        var shown = rewarded.show();
        if (shown && shown.then) {
          shown.catch(function () {
            var loaded = rewarded.load && rewarded.load();
            if (loaded && loaded.then) {
              loaded.then(function () { return rewarded.show(); }).catch(failed);
            } else failed();
          });
        }
      } catch (err) {
        failed();
      }
    });
  }

  function showInterstitial() {
    if (!canUse('createInterstitialAd')) return;
    try {
      if (!interstitial) {
        interstitial = wx.createInterstitialAd({ adUnitId: config.ads.interstitialAdUnitId });
        if (interstitial.onError) interstitial.onError(function () {});
      }
      var shown = interstitial.show();
      if (shown && shown.catch) {
        shown.catch(function () {
          if (interstitial.load) {
            interstitial.load().then(function () { return interstitial.show(); }).catch(function () {});
          }
        });
      }
    } catch (err) {}
  }

  function showBanner(width, top) {
    if (!config.bannerEnabled || !canUse('createBannerAd')) return false;
    try {
      if (!banner) {
        banner = wx.createBannerAd({
          adUnitId: config.ads.bannerAdUnitId,
          style: { left: 0, top: top || 0, width: width || 300 },
        });
        if (banner.onError) banner.onError(function () {});
        if (banner.onResize) {
          banner.onResize(function (size) {
            if (size && typeof wx.getSystemInfoSync === 'function') {
              var sys = wx.getSystemInfoSync();
              banner.style.top = sys.screenHeight - size.height;
              banner.style.left = (sys.screenWidth - size.width) / 2;
            }
          });
        }
      }
      banner.show && banner.show();
      return true;
    } catch (err) {
      return false;
    }
  }

  return {
    showRewarded: showRewarded,
    showInterstitial: showInterstitial,
    showBanner: showBanner,
  };
}

module.exports = { createAds: createAds };
