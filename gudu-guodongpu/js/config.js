'use strict';

/**
 * 广告位与变现开关。
 * 上线前只改这个文件：换成真实 AppID 对应的广告位 ID。
 */
module.exports = {
  appName: '咕嘟果冻铺',

  /**
   * 正式 AppID 写在 project.config.json 的 appid 字段。
   * 开发阶段保持 touristappid 即可。
   */
  appIdNote: 'touristappid',

  ads: {
    // ▼▼▼ 在微信公众平台创建广告位后，替换下面三个占位 ID ▼▼▼
    rewardedVideoAdUnitId: 'adunit-placeholder-rewarded',
    interstitialAdUnitId: 'adunit-placeholder-interstitial',
    bannerAdUnitId: 'adunit-placeholder-banner',
    // ▲▲▲ 占位符，正式发布前必须替换，否则广告请求会失败 ▲▲▲
  },

  /** 总开关。false 时不创建任何广告。 */
  adsEnabled: true,

  /**
   * 激励视频创建失败、拉取失败，或开发者工具没有广告模块时，是否直接发放奖励。
   * 方便真机以外的调试。正式运营若不想白送奖励，改为 false。
   */
  grantRewardWhenAdUnavailable: true,

  /** 因广告不可用而直接发奖时，是否提示玩家。 */
  devRewardToast: true,

  /** 底部横幅。默认关闭，避免挡住操作栏；接好广告位后可改成 true。 */
  bannerEnabled: false,

  /** 第 interstitialMinLevel 关之后，每完成 interstitialEvery 关插一次屏。 */
  interstitialEvery: 4,
  interstitialMinLevel: 10,

  shareTitle: '咕嘟果冻铺：帮我把彩虹果冻分装好！',
};
