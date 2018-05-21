//
//  ImageSearchViewController.m
//  WeChatStudy
//
//  Created by Hubery on 2018/5/21.
//  Copyright © 2018年 Shenzhen Youxun Information Technology Co., Ltd. All rights reserved.
//

#import "ImageSearchViewController.h"
#import "WXImageSearch.h"

/** 真没搞懂这是个什么玩意儿 腾讯整这个东西有啥🐦用 */
@interface ImageSearchViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate,WXImageSearchDelegate>
- (IBAction)clickTakePhotoButton:(id)sender;

- (IBAction)clickChoseImageButton:(id)sender;
@end

@implementation ImageSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"图像识别";
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)clickTakePhotoButton:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.allowsEditing = YES;
    } else {
        return;
    }
    
    [self.navigationController presentViewController:picker animated:YES completion:^{
       
    }];
}

- (IBAction)clickChoseImageButton:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.allowsEditing = YES;
    } else {
        return;
    }
    [self.navigationController presentViewController:picker animated:YES completion:^{
        
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = nil;
    if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeImage]) {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
        if (!image) {
            //旋转的原图
            image = [info objectForKey:UIImagePickerControllerOriginalImage];
        }
    }
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [[WXImageSearch  sharedImageSearch] setAppID:WeChat_AppID];
        [[WXImageSearch sharedImageSearch] setDelegate:self];
        [[WXImageSearch sharedImageSearch] startWithImage:image];
    }];
    
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
    
}

#pragma mark - WXImageSearchDelegate
- (void)imageSearchResultArray:(NSArray *)resultArray{
    NSLog(@"===%@===",resultArray);
} //如果流程成功，但没有识别到符合的结果，则resultArray为nil

- (void)imageSearchMakeError:(NSInteger)error{
    NSLog(@"===%ld===",error);
}

- (void)imageSearchDidCancel{
    NSLog(@"取消啦！");
}

@end
