//
//  WeChatNetWorkManager.m
//  WeChatStudy
//
//  Created by Hubery on 2018/5/20.
//  Copyright © 2018年 Shenzhen Youxun Information Technology Co., Ltd. All rights reserved.
//

#import "WeChatNetWorkManager.h"

@implementation WeChatNetWorkManager

+ (instancetype)sharedWeChatNetWorkManager{
    static WeChatNetWorkManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseURL = [NSURL URLWithString:WeChat_Host];
        instance = [[self alloc] initWithBaseURL:baseURL];
        instance.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                                                   @"text/json",
                                                                                   @"text/javascript",
                                                                                   @"text/html",
                                                                                   @"text/plain",nil];

    });
    return instance;
}

-(void)GETWithURLString:(NSString *)URLString parameters:(id)parameters success:(void (^)(id))successBlock failure:(void (^)(NSError *))failureBlock{
    [self GET:URLString parameters:parameters
     progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (successBlock != nil) {
            successBlock(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (failureBlock != nil) {
            failureBlock(error);
        }
    }];
}

@end
