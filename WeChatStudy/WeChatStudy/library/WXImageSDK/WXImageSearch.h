//
//  WXImageSearch.h
//  WXImageSearch
//
//  Copyright (c) 2013年 Tencent Research. All rights reserved.
//

/*
 需要引入：
 CoreTelephony.framework
 SystemConfiguration.framework
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


//--------------------------------错误码------------------------
//公用
#ifndef __WX_Error_Code_Base__
#define __WX_Error_Code_Base__

#define WXErrorOfSuccess            0       //没错误0
#define WXErrorOfNoNetWork          -201    //没有网络
#define WXErrorOfTimeOut            -202    //网络超时错误
#define WXErrorOfQuotaExhaust       -203    //配额用完
#define WXErrorOfAppIDError         -204    //AppId 不存在或失效
#define WXErrorOfTextNull           -402    //文本为空（在语音识别中指的是，Grammar文本）
#define WXErrorOfTextOverlength     -403    //文本过长

#endif

//图像识别
#define WXImgErrorOfNotImage        -501      //没有图像
#define WXImgErrorOfTooLarge        -502      //图像过大
#define WXImgErrorOfNoFeatures      -503        //没有特征值
#define WXImgErrorOfExtractfeatures -504    //提取图片信息失败，通常是图片数据格式不对
#define WXImgErrorOfUserIDNotExist  -505    //图库里不存在此APPID
/*其它错误
 //网络错误
 [-104,-100]网络底层错误
 [1,1000]系统错误码（通常也是由网络问题引起的）及[201, 505]HTTP错误码
 
 //服务错误
 [1000,++]服务器错误，
 */


@interface WXImageSearchResult : NSObject
@property (nonatomic, retain) NSString *md5;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *picDesc;
@end

@protocol WXImageSearchDelegate <NSObject>

- (void)imageSearchResultArray:(NSArray *)resultArray;  //如果流程成功，但没有识别到符合的结果，则resultArray为nil
- (void)imageSearchMakeError:(NSInteger)error;

- (void)imageSearchDidCancel;

@end

@interface WXImageSearch : NSObject

@property (nonatomic,assign)id<WXImageSearchDelegate>delegate;

+ (WXImageSearch *)sharedImageSearch;
+ (void)releaseImageSearch;

- (void)setAppID:(NSString *)appid;

//一次只能进行一次识别，需要等之前的 错误码，取消完成 或 识别结果 的回调后才可以进行下一次识别
- (BOOL)startWithImage:(UIImage *)image;    //大图会被缩放到160000像素
- (BOOL)startWithJPGImageData:(NSData *)imageData;  //限制为300 000字节

- (void)cancel; //注意，不是立刻就能取消的，需要等取消后的回调

@end
