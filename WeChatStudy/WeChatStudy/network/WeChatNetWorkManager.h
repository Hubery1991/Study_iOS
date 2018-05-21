//
//  WeChatNetWorkManager.h
//  WeChatStudy
//
//  Created by Hubery on 2018/5/20.
//  Copyright © 2018年 Shenzhen Youxun Information Technology Co., Ltd. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface WeChatNetWorkManager : AFHTTPSessionManager

+ (instancetype)sharedWeChatNetWorkManager;

/**
 *  发送GET请求,获取JSON数据
 *
 *  @param URLString JSON数据地址
 *  @param success   成功的回调,回调AFN反序列之后结果
 *  @param failed    失败的回调,回调AFN获取的错误信息
 */
- (void)GETWithURLString:(NSString *)URLString
              parameters:(id)parameters
                 success:(void(^)(id responseObject))successBlock
                 failure:(void(^)(NSError *error))failureBlock;
@end
