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

static NSString *const mobPushModuleName = @"mobPushPlus";

@interface MobPushPlus ()

@property (nonatomic, copy) void (^receiverHandler) (MPushMessage *message);
@property (nonatomic, assign) BOOL isPro;

@end

@implementation MobPushPlus

#pragma mark - Override
+ (void)onAppLaunch:(NSDictionary *)launchOptions
{
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

#pragma mark - addLocalNotification

JS_METHOD(addLocalNotification:(UZModuleMethodContext *)context)
{
    NSDictionary *params = context.param;
    NSDictionary *localParams = nil;
    if ([params isKindOfClass:[NSDictionary class]])
    {
        localParams = params[@"localParams"];
    }
    
    MPushMessage *message = [[MPushMessage alloc] init];
    message.messageType = MPushMessageTypeLocal;
    MPushNotification *noti = [[MPushNotification alloc] init];
    noti.body = localParams[@"content"];
    noti.title = localParams[@"title"];
    noti.subTitle = localParams[@"subTitle"];
    noti.sound = localParams[@"sound"];
    if (localParams[@"badge"])
    {
        noti.badge = [localParams[@"badge"] integerValue];
    }
    else
    {
        noti.badge = ([UIApplication sharedApplication].applicationIconBadgeNumber < 0 ? 0 : [UIApplication sharedApplication].applicationIconBadgeNumber) + 1;
    }
    
    message.notification = noti;
    
    long timeStamp = [localParams[@"timeStamp"] longValue];
    
    if (timeStamp <= 0)
    {
        message.isInstantMessage = YES;
    }
    else
    {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
        message.taskDate = (timeInterval + (NSTimeInterval)timeStamp) * 1000;
    }
    [MobPush addLocalNotification:message];
}

#pragma mark - addpushReceiver

JS_METHOD(addpushReceiver:(UZModuleMethodContext *)context)
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMessage:) name:MobPushDidReceiveMessageNotification object:nil];
    
    __weak typeof(self) weakSelf = self;
    self.receiverHandler = ^(MPushMessage *message) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf _coventMessage:message context:context];
    };
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
    [MobPush sendMessageWithMessageType:msgType
                                content:content
                                  space:space
                isProductionEnvironment:_isPro
                                 extras:extras
                             linkScheme:nil
                               linkData:nil
                                 result:^(NSError *error) {
                                     NSMutableDictionary *responseDict = [self _handlerError:error];
                                     [context callbackWithRet:responseDict err:nil delete:YES];
                                 }];
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
    
    switch (message.messageType)
    {
        case MPushMessageTypeCustom:
        {// 自定义消息
            [resultDict setObject:@0 forKey:@"action"];
            
            if (message.extraInfomation)
            {
                [reslut setObject:message.extraInfomation forKey:@"extra"];
            }
            
            if (message.content)
            {
                [reslut setObject:message.content forKey:@"content"];
            }
            
            if (message.messageID)
            {
                [reslut setObject:message.messageID forKey:@"messageId"];
            }
            
            if (message.currentServerTimestamp)
            {
                [reslut setObject:@(message.currentServerTimestamp) forKey:@"timeStamp"];
            }
        }
            break;
        case MPushMessageTypeAPNs:
        {// APNs 回调
            if (message.msgInfo)
            {
                NSDictionary *aps = message.msgInfo[@"aps"];
                if ([aps isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *alert = aps[@"alert"];
                    if ([alert isKindOfClass:[NSDictionary class]])
                    {
                        NSString *body = alert[@"body"];
                        if (body)
                        {
                            [reslut setObject:body forKey:@"content"];
                        }
                        
                        NSString *subtitle = alert[@"subtitle"];
                        if (subtitle)
                        {
                            [reslut setObject:subtitle forKey:@"subtitle"];
                        }
                        
                        NSString *title = alert[@"title"];
                        if (title)
                        {
                            [reslut setObject:title forKey:@"title"];
                        }
                    }
                    
                    NSString *sound = aps[@"sound"];
                    if (sound)
                    {
                        [reslut setObject:sound forKey:@"sound"];
                    }
                    
                    NSInteger badge = [aps[@"badge"] integerValue];
                    if (badge)
                    {
                        [reslut setObject:@(badge) forKey:@"badge"];
                    }
                    
                }
            }
            
            NSString *messageId = message.msgInfo[@"mobpushMessageId"];
            if (messageId)
            {
                [reslut setObject:messageId forKey:@"messageId"];
            }
            
            NSMutableDictionary *extra = [NSMutableDictionary dictionary];
            [message.msgInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                
                if (![key isEqualToString:@"aps"] && ![key isEqualToString:@"mobpushMessageId"])
                {
                    [extra setObject:obj forKey:key];
                }
                
            }];
            
            if (extra.count)
            {
                [reslut setObject:extra forKey:@"extra"];
            }
            
            [resultDict setObject:@1 forKey:@"action"];
        }
            break;
        case MPushMessageTypeLocal:
        { // 本地通知回调
            NSString *body = message.notification.body;
            NSString *title = message.notification.title;
            NSString *subtitle = message.notification.subTitle;
            NSInteger badge = message.notification.badge;
            NSString *sound = message.notification.sound;
            if (body)
            {
                [reslut setObject:body forKey:@"content"];
            }
            
            if (title)
            {
                [reslut setObject:title forKey:@"title"];
            }
            
            if (subtitle)
            {
                [reslut setObject:subtitle forKey:@"subtitle"];
            }
            
            if (badge)
            {
                [reslut setObject:@(badge) forKey:@"badge"];
            }
            
            if (sound)
            {
                [reslut setObject:sound forKey:@"sound"];
            }
            
            [resultDict setObject:@1 forKey:@"action"];
        }
            break;
            
        case MPushMessageTypeClicked:
        {
            if (message.msgInfo)
            {
                NSDictionary *aps = message.msgInfo[@"aps"];
                if ([aps isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *alert = aps[@"alert"];
                    if ([alert isKindOfClass:[NSDictionary class]])
                    {
                        NSString *body = alert[@"body"];
                        if (body)
                        {
                            [reslut setObject:body forKey:@"content"];
                        }
                        
                        NSString *subtitle = alert[@"subtitle"];
                        if (subtitle)
                        {
                            [reslut setObject:subtitle forKey:@"subtitle"];
                        }
                        
                        NSString *title = alert[@"title"];
                        if (title)
                        {
                            [reslut setObject:title forKey:@"title"];
                        }
                    }
                    
                    NSString *sound = aps[@"sound"];
                    if (sound)
                    {
                        [reslut setObject:sound forKey:@"sound"];
                    }
                    
                    NSInteger badge = [aps[@"badge"] integerValue];
                    if (badge)
                    {
                        [reslut setObject:@(badge) forKey:@"badge"];
                    }
                    
                }
                
                NSString *messageId = message.msgInfo[@"mobpushMessageId"];
                if (messageId)
                {
                    [reslut setObject:messageId forKey:@"messageId"];
                }
                
                NSMutableDictionary *extra = [NSMutableDictionary dictionary];
                [message.msgInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    
                    if (![key isEqualToString:@"aps"] && ![key isEqualToString:@"mobpushMessageId"])
                    {
                        [extra setObject:obj forKey:key];
                    }
                    
                }];
                
                if (extra.count)
                {
                    [reslut setObject:extra forKey:@"extra"];
                }
                
                [resultDict setObject:@2 forKey:@"action"];
            }
            else
            {
                NSString *body = message.notification.body;
                NSString *title = message.notification.title;
                NSString *subtitle = message.notification.subTitle;
                NSInteger badge = message.notification.badge;
                NSString *sound = message.notification.sound;
                if (body)
                {
                    [reslut setObject:body forKey:@"content"];
                }
                
                if (title)
                {
                    [reslut setObject:title forKey:@"title"];
                }
                
                if (subtitle)
                {
                    [reslut setObject:subtitle forKey:@"subtitle"];
                }
                
                if (badge)
                {
                    [reslut setObject:@(badge) forKey:@"badge"];
                }
                
                if (sound)
                {
                    [reslut setObject:sound forKey:@"sound"];
                }
                
                [resultDict setObject:@2 forKey:@"action"];
            }
            
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
