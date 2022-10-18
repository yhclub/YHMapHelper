//
//  YHViewController.m
//  YHMapHelper
//
//  Created by liaojiangtu on 10/18/2022.
//  Copyright (c) 2022 liaojiangtu. All rights reserved.
//

#import "YHViewController.h"
#import "YHMapAppHelper.h"
#import "YHLocationHelper.h"

@interface YHViewController ()

/**
 * The method name.
 */
@property(readonly, nonatomic) NSString* method;

/**
 * The arguments.
 */
@property(readonly, nonatomic, nullable) id arguments;


@property(nonatomic,strong)NSMutableDictionary *awaitFlutterCalls;

@end

@implementation YHViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 44, [UIScreen mainScreen].bounds.size.width, 35)];
    label.text = @"Map Tool";
    label.textAlignment= NSTextAlignmentCenter;
    [self.view addSubview:label];
    
    
    UIButton * testBtn= [UIButton buttonWithType:UIButtonTypeCustom];
    [testBtn setFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-50, [UIScreen mainScreen].bounds.size.width, 30)];
    [testBtn setTitle:@"打开地图" forState:UIControlStateNormal];
    [testBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [testBtn addTarget:self action:@selector(testAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:testBtn];
    
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 90, [UIScreen mainScreen].bounds.size.width, 35)];
    messageLabel.tag = 1;
    messageLabel.text = @"result:.";
    messageLabel.textAlignment= NSTextAlignmentCenter;
    [self.view addSubview:messageLabel];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)result:(NSString *)msg
{
    NSLog(@"result:%@",msg);
    UILabel *messageLabel = [self.view viewWithTag:1];
    if (messageLabel!=nil) {
        messageLabel.text = [NSString stringWithFormat:@"result:%@",msg];
    }
}

- (void)testAction{
    
    if ([@"openMap" isEqualToString:self.method]) {
        
        if (self.arguments && [self.arguments isKindOfClass:[NSDictionary class]]) {
            
            NSDictionary *param = self.arguments;
            if ([param objectForKey:@"lat"] == nil) {
                [self result:@"fail, lat is null!"];
            }else if ([param objectForKey:@"lng"] == nil) {
                [self result:@"fail, lng is null!"];
            }
            CLLocationDegrees latitude = [[param objectForKey:@"lat"] doubleValue];
            CLLocationDegrees longitude = [[param objectForKey:@"lng"] doubleValue];
            CLLocationCoordinate2D desCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
            NSString *address = [param objectForKey:@"address"]?:@"";
            
            UIAlertController *alert = [YHMapAppHelper getInstalledMapAppsActionSheetControllerWithBlock:^(YHAbstractMapAppItem * _Nonnull item) {
                if (item.canOpen) {
                    [item jumpToNavByDesCoordinate:desCoordinate desName:address];
                }
            }];
            UIViewController *rootVC = [[UIApplication sharedApplication] keyWindow].rootViewController;
            if (rootVC) {
                [rootVC presentViewController:alert animated:YES completion:^{
                    [self result:@"success"];
                }];
            }else{
                [self result:@"fail"];
            }
        }
        else{
            [self result:@"fail, arguments is null!"];
        }
    } else if ([@"locationCoordinate" isEqualToString:self.method]) {
        
        //当前坐标
        if ([YHLocationHelper sharedHelper].authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
            [YHLocationHelper sharedHelper].authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
            if ([YHLocationHelper sharedHelper].currentLoaction) {
                return [self getLocationCoordinateWhenAuth];
            }
        }
        [[YHLocationHelper sharedHelper] startUpdatingLocation];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAuthorizationStatus) name:kYHAuthorizeGetLocationNotiKey object:nil];
    }
}

/// 获取当前坐标
- (void)getLocationCoordinateWhenAuth{
    
    YHCoordinateSystem type = YHCoordinateSystem_GCJ;
    if (self.arguments && [self.arguments isKindOfClass:[NSString class]]) {
        
        if ([@"BD" isEqualToString:self.arguments]) {
            type = YHCoordinateSystem_BD;
        }else if ([@"WGS" isEqualToString:self.arguments]) {
            type = YHCoordinateSystem_BD;
        }
    }
    CLLocationCoordinate2D coordinate= [[YHLocationHelper sharedHelper] currentCoordinateBySystem:type];
    NSString *coordinateJsonString = [NSString stringWithFormat:@"{'lat':'%f','lng':'%f'}",coordinate.latitude,coordinate.longitude];
    [self result:[NSString stringWithFormat:@"获取定位：%@",coordinateJsonString]];
    
    //处理完成，清除缓存
    [self.awaitFlutterCalls removeObjectForKey:@"locationCoordinate"];
}

- (void)didChangeAuthorizationStatus{
    [[YHLocationHelper sharedHelper] stopUpdatingLocation];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kYHAuthorizeGetLocationNotiKey object:nil];
    
    if ([YHLocationHelper sharedHelper].authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
        [YHLocationHelper sharedHelper].authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if ([YHLocationHelper sharedHelper].currentLoaction) {
            return [self getLocationCoordinateWhenAuth];
        }
    }
    //获取定位失败
    [self result:@"获取定位失败"];
    //处理完成，清除缓存
    [self.awaitFlutterCalls removeObjectForKey:@"locationCoordinate"];
}

-(NSMutableDictionary *)awaitFlutterCalls{
    
    if (!_awaitFlutterCalls) {
        _awaitFlutterCalls = [NSMutableDictionary dictionary];
    }
    return _awaitFlutterCalls;
}

@end
