//
//  ViewController.m
//  WeChatStudy
//
//  Created by Hubery on 2018/5/20.
//  Copyright © 2018年 Shenzhen Youxun Information Technology Co., Ltd. All rights reserved.
//

#import "ViewController.h"
#import "WXMediaMessage+messageConstruct.h"
#import "SendMessageToWXReq+requestWithTextOrMediaMessage.h"


@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,WXApiManagerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.title = @"WeChatStudy";
    self.dataArray = @[@"微信登录",@"拉起小程序",@"小程序类型分享"];
    [WXApiManager sharedManager].delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.dataArray?1:0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray?self.dataArray.count:0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"wechatcell_identifier"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"wechatcell_identifier"];
    }
    cell.textLabel.text = self.dataArray[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            {
                [self sendAuthLoginRequest];
            }
            break;
        case 1:
            {
                [self sendMiniProgramRequest];
            }
            break;
        case 2:
        {
            [self sendMiniProgramShareRequest];
        }
            break;
        default:
            break;
    }
}

/** 微信授权登录 */
- (void)sendAuthLoginRequest{
    SendAuthReq *req = [[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo";
    req.state = @"wechatstudy";
    [WXApi sendReq:req];
}

/** 拉起小程序 */
- (void)sendMiniProgramRequest{
    WXLaunchMiniProgramReq *launchMiniProgramReq = [WXLaunchMiniProgramReq object];
    launchMiniProgramReq.userName = @"gh_d0298d31342f";  //拉起的小程序的username
    launchMiniProgramReq.path = @"pages/home/index";    //拉起小程序页面的可带参路径，不填默认拉起小程序首页
    launchMiniProgramReq.miniProgramType = WXMiniProgramTypeRelease; //拉起小程序的类型
    [WXApi sendReq:launchMiniProgramReq];
}

/** 小程序类型分享 */
- (void)sendMiniProgramShareRequest{
    NSData *thumbData = UIImageJPEGRepresentation([UIImage imageNamed:@"IMG_3390.JPG"], 0.7);
    WXMiniProgramObject *ext = [WXMiniProgramObject object];
    ext.webpageUrl = @"https://www.sifangti.club";
    ext.userName = @"gh_d0298d31342f";
    ext.path = @"pages/home/index";
    ext.hdImageData = thumbData;
    ext.withShareTicket = YES;
    ext.miniProgramType = WXMiniProgramTypeRelease;
    
    WXMediaMessage *message = [WXMediaMessage messageWithTitle:@"积分云商小程序"
                                                   Description:@"深圳市优讯信息技术有限公司"
                                                        Object:ext
                                                    MessageExt:nil
                                                 MessageAction:nil
                                                    ThumbImage:[UIImage imageNamed:@"IMG_3390.JPG"]
                                                      MediaTag:nil];
    
    SendMessageToWXReq* req = [SendMessageToWXReq requestWithText:nil
                                                   OrMediaMessage:message
                                                            bText:NO
                                                          InScene:WXSceneSession];
    
   [WXApi sendReq:req];
}

#pragma mark - WXApiManagerDelegate
- (void)managerDidRecvAuthResponse:(SendAuthResp *)response{
    /** 获取Access_Token 网络请求 */
    //code 的超时时间为10分钟 一个code只能成功换取一次access_token即失效
    NSDictionary *parameters = @{@"appid":WeChat_AppID,
                                 @"secret":WeChat_AppSecert,
                                 @"code":response.code,
                                 @"grant_type":@"authorization_code"};
    [[WeChatNetWorkManager sharedWeChatNetWorkManager] GETWithURLString:WeChat_Access_token
                                                             parameters:parameters
                                                                success:^(id responseObject) {
                                                                    NSLog(@"%@",responseObject);
                                                                    [self getWeChatUserInfo:responseObject[@"access_token"]
                                                                                  andOpenID:responseObject[@"openid"]];
    } failure:^(NSError *error) {
        NSLog(@"%@",error);
    }];
}

- (void)managerDidRecvLaunchMiniProgram:(WXLaunchMiniProgramResp *)response{
    NSLog(@"%@",response.extMsg);
}


/** access_token超时 重新获取 */
- (void)reloadAccessToken{
    //注意 access_token 有效期为两小时  refresh_token 有效期为30天
    NSDictionary *parameters = @{@"appid":WeChat_AppID,
                                 @"grant_type":@"refresh_token",
                                 @"refresh_token":@"REFRESH_TOKEN"
                                 };
    [[WeChatNetWorkManager sharedWeChatNetWorkManager] GETWithURLString:WeChat_refresh_token
                                                             parameters:parameters
                                                                success:^(id responseObject) {
                                                                   
    } failure:^(NSError *error) {
        
    }];
}

/** 获取微信用户信息 */
- (void)getWeChatUserInfo:(NSString *)access_token andOpenID:(NSString *)openid{
    NSDictionary *parameters = @{@"access_token":access_token,
                                 @"openid":openid,
                                 @"lang":@"zh_CN" //国家地区语言版本，zh_CN 简体，zh_TW 繁体，en 英语，默认为zh-CN
                                 };
    [[WeChatNetWorkManager sharedWeChatNetWorkManager] GETWithURLString:WeChat_userinfo
                                                             parameters:parameters
                                                                success:^(id responseObject) {
                                                                        NSLog(@"%@",responseObject);
                                                                
    } failure:^(NSError *error) {
        
    }];
}

@end



















