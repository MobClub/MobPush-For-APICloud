//
//  MobPushPlus.m
//  MobPushPlus
//
//  Created by LeeJay on 2019/5/7.
//  Copyright © 2019 YouZu. All rights reserved.
//

#import "MobPushPlus.h"
#import <MobPush/MobPush.h>
#import <MobPush/MobPush+Test.h>
#import <MOBFoundation/MOBFoundation.h>
#import "UZAppDelegate.h"
#import <MOBFoundation/MobSDK+Privacy.h>

static NSString *const mobPushModuleName = @"mobPushPlus";

@interface MobPushPlus ()

@property (nonatomic, copy) void (^receiverHandler) (MPushMessage *message);
@property (nonatomic, assign) BOOL isPro;

@end

@implementation MobPushPlus

#pragma mark - Override

static NSMutableArray *cachedNotications;

+ (void)onAppLaunch:(NSDictionary *)launchOptions
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMessage:) name:MobPushDidReceiveMessageNotification object:nil];
    // 方法在应用启动时被调用
    NSDictionary *config = [[UZAppDelegate appDelegate] getFeatureByName:mobPushModuleName];
    NSString *MOBAppKey = config[@"MOBAppKey"];
    NSString *MOBAppSecret = config[@"MOBAppSecret"];
    if ([MOBAppKey length] > 0 && [MOBAppSecret length] > 0)
    {
        [MobSDK registerAppKey:MOBAppKey appSecret:MOBAppSecret];
    }
    
    [self setup];
}

+ (void)didReceiveMessage:(NSNotification *)notification {
    if (!cachedNotications)
    {
        cachedNotications = [NSMutableArray array];
    }
    if (notification)
    {
        [cachedNotications addObject:notification];
    }
}

- (id)initWithUZWebView:(UZWebView *)webView
{
    if (self = [super initWithUZWebView:webView])
    {
        // 初始化方法
    }
    return self;
}

- (void)dispose
{
    // 方法在模块销毁之前被调用
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)setup
{
    MPushNotificationConfiguration *config = [MPushNotificationConfiguration new];
    config.types = MPushAuthorizationOptionsBadge | MPushAuthorizationOptionsSound | MPushAuthorizationOptionsAlert;
    [MobPush setupNotification:config];
}

#pragma mark - setAPNsForProduction
JS_METHOD(setAPNsForProduction:(UZModuleMethodContext *)context)
{
    NSDictionary *params = context.param;
    _isPro = [params[@"isPro"] boolValue];
    [MobPush setAPNsForProduction:_isPro];
}


#pragma mark - Privacy Protocol

JS_METHOD(uploadPrivacyPermissionStatus:(UZModuleMethodContext *)context)
{
    NSDictionary *params = context.param;
    [MobSDK uploadPrivacyPermissionStatus:[params[@"agree"] boolValue] onResult:^(BOOL success) {
        NSLog(@"-------------->上传结果：%d",success);
    }];
}


JS_METHOD(getPrivacyPolicy:(UZModuleMethodContext *)context)
{
    NSDictionary *params = context.param;
    NSString *type = params[@"type"]?[NSString stringWithFormat:@"%@", params[@"type"]]:@"";
    [MobSDK getPrivacyPolicy:type language:params[@"language"] compeletion:^(NSDictionary * _Nullable data, NSError * _Nullable error) {
        NSMutableDictionary *responseDict = [self _handlerError:error];
        [responseDict addEntriesFromDictionary:data];
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
}

#pragma mark - addLocalNotification

JS_METHOD(addLocalNotification:(UZModuleMethodContext *)context)
{
    NSDictionary *params = context.param;
    NSDictionary *localParams = nil;
    if ([params isKindOfClass:[NSDictionary class]])
    {
        localParams = params[@"localParams"];
    }
    
//    MPushMessage *message = [[MPushMessage alloc] init];
//    message.messageType = MPushMessageTypeLocal;
    
    MPushNotificationRequest *request = [MPushNotificationRequest new];
    NSString *identifier = nil;
    if (localParams[@"identifier"] && ![localParams[@"identifier"] isKindOfClass:[NSNull class]])
    {
        identifier = localParams[@"identifier"];
    }
    request.requestIdentifier = identifier;
    
    MPushNotification *content = [[MPushNotification alloc] init];
    content.body = localParams[@"content"];
    content.title = localParams[@"title"];
    content.subTitle = localParams[@"subTitle"];
    content.sound = localParams[@"sound"];
    if (localParams[@"badge"])
    {
        content.badge = [localParams[@"badge"] integerValue];
    }
    else
    {
        content.badge = ([UIApplication sharedApplication].applicationIconBadgeNumber < 0 ? 0 : [UIApplication sharedApplication].applicationIconBadgeNumber) + 1;
    }
    
    if ([localParams[@"extra"] isKindOfClass:[NSDictionary class]])
    {
        content.userInfo = localParams[@"extra"];
    }
    if ([localParams[@"userInfo"] isKindOfClass:[NSDictionary class]])
    {
        content.userInfo = localParams[@"userInfo"];
    }
    
    request.content = content;
    
    
    // 推送通知触发条件
    MPushNotificationTrigger *trigger = [MPushNotificationTrigger new];
    
    long timeStamp = [localParams[@"timeStamp"] longValue];
    
    if (timeStamp > 0)
    {
        // 设置几分钟后发起本地推送
        NSDate *currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval nowtime = [currentDate timeIntervalSince1970] * 1000;
        NSTimeInterval tasktimeInterval = nowtime + timeStamp*1000;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0)
        {
            trigger.timeInterval = timeStamp;
        }
        else
        {
            trigger.fireDate = [NSDate dateWithTimeIntervalSince1970:tasktimeInterval];
        }
    }
    
    request.trigger = trigger;
    
    [MobPush addLocalNotification:request result:^(id result, NSError *error) {
        NSMutableDictionary *responseDict = [self _handlerError:error];
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
}

#pragma mark - addpushReceiver

JS_METHOD(addpushReceiver:(UZModuleMethodContext *)context)
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMessage:) name:MobPushDidReceiveMessageNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:MobPushPlus.class];
    __weak typeof(self) weakSelf = self;
    self.receiverHandler = ^(MPushMessage *message) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf _coventMessage:message context:context];
    };
    
    if (cachedNotications.count)
    {
        for (NSNotification *notification in cachedNotications)
        {
            self.receiverHandler(notification.object);
        }
        
        cachedNotications = nil;
    }
}

// 收到通知回调
- (void)didReceiveMessage:(NSNotification *)notification
{
    MPushMessage *message = notification.object;
    
    if (self.receiverHandler)
    {
        self.receiverHandler(message);
    }
}

#pragma mark - getTags

JS_METHOD(getTags:(UZModuleMethodContext *)context)
{
    [MobPush getTagsWithResult:^(NSArray *tags, NSError *error) {
        NSMutableDictionary *responseDict = [self _handlerError:error];
        responseDict[@"tags"] = tags;
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
}

#pragma mark - addTags

JS_METHOD(addTags:(UZModuleMethodContext *)context)
{
    NSDictionary *params = context.param;
    NSArray *tags = params[@"tags"];
    [MobPush addTags:tags result:^(NSError *error) {
        NSMutableDictionary *responseDict = [self _handlerError:error];
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
}

#pragma mark - deleteTags

JS_METHOD(deleteTags:(UZModuleMethodContext *)context)
{
    NSDictionary *params = context.param;
    NSArray *tags = params[@"tags"];
    [MobPush deleteTags:tags result:^(NSError *error) {
        NSMutableDictionary *responseDict = [self _handlerError:error];
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
}

#pragma mark - cleanAllTags

JS_METHOD(cleanAllTags:(UZModuleMethodContext *)context)
{
    [MobPush cleanAllTags:^(NSError *error) {
        NSMutableDictionary *responseDict = [self _handlerError:error];
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
}

#pragma mark - getRegistrationID

JS_METHOD(getRegistrationID:(UZModuleMethodContext *)context)
{
    [MobPush getRegistrationID:^(NSString *registrationID, NSError *error) {
        NSMutableDictionary *responseDict = [NSMutableDictionary dictionary];
        responseDict[@"regId"] = registrationID;
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
}

#pragma mark - setAlias

JS_METHOD(setAlias:(UZModuleMethodContext *)context)
{
    NSDictionary *params = context.param;
    NSString *alias = params[@"alias"];
    [MobPush setAlias:alias result:^(NSError *error) {
        NSMutableDictionary *responseDict = [self _handlerError:error];
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
}

#pragma mark - deleteAlias

JS_METHOD(deleteAlias:(UZModuleMethodContext *)context)
{
    [MobPush deleteAlias:^(NSError *error) {
        NSMutableDictionary *responseDict = [self _handlerError:error];
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
}

#pragma mark - getAlias

JS_METHOD(getAlias:(UZModuleMethodContext *)context)
{
    [MobPush getAliasWithResult:^(NSString *alias, NSError *error) {
        NSMutableDictionary *responseDict = [self _handlerError:error];
        responseDict[@"alias"] = alias;
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
}

#pragma mark - bindPhoneNum

JS_METHOD(bindPhoneNum:(UZModuleMethodContext *)context)
{
    NSDictionary *params = context.param;
    NSString *phoneNum = params[@"phoneNum"];
    [MobPush bindPhoneNum:phoneNum result:^(NSError *error) {
        NSMutableDictionary *responseDict = [self _handlerError:error];
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
}

#pragma mark - sendMessage

JS_METHOD(sendMessage:(UZModuleMethodContext *)context)
{
    NSDictionary *params = context.param;
    NSInteger msgType = [params[@"msgType"] integerValue];
    NSString *content = params[@"content"];
    NSNumber *space = params[@"space"];
    NSDictionary *extras = params[@"extras"];
    NSString *sound = params[@"sound"]?:@"default";
    NSString *coverId = params[@"coverId"];
    [MobPush sendMessageWithMessageType:msgType
                                content:content
                                  space:space
                                  sound:sound
                isProductionEnvironment:_isPro
                                 extras:extras
                             linkScheme:nil
                               linkData:nil
                                coverId:coverId
                                 result:^(NSString *workId, NSError *error) {
        NSMutableDictionary *responseDict = [self _handlerError:error];
        if (workId)
        {
            responseDict[@"workId"] = workId;
        }
        [context callbackWithRet:responseDict err:nil delete:YES];
    }];
//    [MobPush sendMessageWithMessageType:msgType
//                                content:content
//                                  space:space
//                isProductionEnvironment:_isPro
//                                 extras:extras
//                             linkScheme:nil
//                               linkData:nil
//                                 result:^(NSError *error) {
//                                     NSMutableDictionary *responseDict = [self _handlerError:error];
//                                     [context callbackWithRet:responseDict err:nil delete:YES];
//                                 }];
}

#pragma mark - Privates

- (NSMutableDictionary *)_handlerError:(NSError *)error
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (error)
    {
        dict[@"errorCode"] = @(0);
    }
    else
    {
        dict[@"errorCode"] = @(1);
    }
    return dict;
}

- (void)_coventMessage:(MPushMessage *)message context:(UZModuleMethodContext *)context
{
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *reslut = [NSMutableDictionary dictionary];
    if (![message isKindOfClass:[MPushMessage class]])
    {
        return;
    }
    
    switch (message.messageType)
    {
        case MPushMessageTypeCustom:
        {// 自定义消息
            [resultDict setObject:@0 forKey:@"action"];
            
            if (message.notification.userInfo)
            {
                [reslut setObject:message.notification.userInfo forKey:@"extra"];
            }
            
            if (message.notification.body)
            {
                [reslut setObject:message.notification.body forKey:@"content"];
            }
            
            if (message.messageID)
            {
                [reslut setObject:message.messageID forKey:@"messageId"];
            }
            
            [reslut addEntriesFromDictionary:message.notification.convertDictionary];
        }
            break;
        case MPushMessageTypeAPNs:
        {// APNs 回调
            [resultDict setObject:@1 forKey:@"action"];
            
            if (message.notification.userInfo)
            {
                [reslut setObject:message.notification.userInfo forKey:@"extra"];
            }
            if (message.notification.body)
            {
                [reslut setObject:message.notification.body forKey:@"content"];
            }
            if (message.messageID)
            {
                [reslut setObject:message.messageID forKey:@"messageId"];
            }
            [reslut addEntriesFromDictionary:message.notification.convertDictionary];
        }
            break;
        case MPushMessageTypeLocal:
        { // 本地通知回调
            [resultDict setObject:@1 forKey:@"action"];
            
            if (message.notification.userInfo)
            {
                [reslut setObject:message.notification.userInfo forKey:@"extra"];
            }
            if (message.notification.body)
            {
                [reslut setObject:message.notification.body forKey:@"content"];
            }
            if (message.messageID)
            {
                [reslut setObject:message.messageID forKey:@"messageId"];
            }
            [reslut addEntriesFromDictionary:message.notification.convertDictionary];
        }
            break;
            
        case MPushMessageTypeClicked:
        {
            [resultDict setObject:@2 forKey:@"action"];
            
            if (message.notification.userInfo)
            {
                [reslut setObject:message.notification.userInfo forKey:@"extra"];
            }
            if (message.notification.body)
            {
                [reslut setObject:message.notification.body forKey:@"content"];
            }
            if (message.messageID)
            {
                [reslut setObject:message.messageID forKey:@"messageId"];
            }
            [reslut addEntriesFromDictionary:message.notification.convertDictionary];
        }
            break;
            
        default:
            break;
    }
    
    if (reslut.count)
    {
        [resultDict setObject:reslut forKey:@"result"];
    }
    
    if (resultDict.count)
    {
        [context callbackWithRet:resultDict err:nil delete:NO];
    }
}

@end
