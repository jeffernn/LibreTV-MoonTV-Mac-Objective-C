//Jeffern影视平台 ©Jeffern 2025/7/23

#import "HLWebsiteMonitor.h"
#import "HLHomeViewController.h"
#import <UserNotifications/UserNotifications.h>

#define MONITOR_DATA_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/JeffernMovie/monitor.json"]

@implementation HLMonitoredWebsite

- (instancetype)initWithName:(NSString *)name url:(NSString *)url {
    self = [super init];
    if (self) {
        _name = [name copy];
        _url = [url copy];
        _status = HLWebsiteStatusUnknown;
        _lastCheckTime = nil;
        _responseTime = 0;
        _errorMessage = nil;
        _consecutiveFailures = 0;
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{
        @"name": self.name ?: @"",
        @"url": self.url ?: @"",
        @"status": @(self.status),
        @"lastCheckTime": self.lastCheckTime ? @([self.lastCheckTime timeIntervalSince1970]) : [NSNull null],
        @"responseTime": @(self.responseTime),
        @"errorMessage": self.errorMessage ?: [NSNull null],
        @"consecutiveFailures": @(self.consecutiveFailures)
    };
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    NSString *name = dict[@"name"];
    NSString *url = dict[@"url"];
    
    self = [self initWithName:name url:url];
    if (self) {
        _status = [dict[@"status"] integerValue];
        
        NSNumber *timeInterval = dict[@"lastCheckTime"];
        if (timeInterval && ![timeInterval isEqual:[NSNull null]]) {
            _lastCheckTime = [NSDate dateWithTimeIntervalSince1970:[timeInterval doubleValue]];
        }
        
        _responseTime = [dict[@"responseTime"] doubleValue];
        
        id errorMsg = dict[@"errorMessage"];
        if (errorMsg && ![errorMsg isEqual:[NSNull null]]) {
            _errorMessage = errorMsg;
        }
        
        _consecutiveFailures = [dict[@"consecutiveFailures"] integerValue];
    }
    return self;
}

@end

@interface HLWebsiteMonitor ()

@property (nonatomic, strong) NSMutableArray<HLMonitoredWebsite *> *websites;
@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation HLWebsiteMonitor

+ (instancetype)sharedInstance {
    static HLWebsiteMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HLWebsiteMonitor alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _websites = [NSMutableArray array];
        _requestTimeout = 30; // 30秒
        _isChecking = NO;
        
        // 创建URL会话配置
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = _requestTimeout;
        config.timeoutIntervalForResource = _requestTimeout;
        _urlSession = [NSURLSession sessionWithConfiguration:config];
        
        // 加载保存的数据
        [self loadFromFile];
        
        // 请求通知权限
        [self requestNotificationPermission];
    }
    return self;
}

- (void)requestNotificationPermission {
    if (@available(macOS 10.14, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (error) {
                NSLog(@"通知权限请求失败: %@", error.localizedDescription);
            }
        }];
    } else {
        NSLog(@"系统版本过低，不支持UserNotifications框架");
    }
}

#pragma mark - 监控网站管理

- (void)addWebsite:(NSString *)name url:(NSString *)url {
    if (!name.length || !url.length) return;
    
    // 检查是否已存在
    for (HLMonitoredWebsite *website in self.websites) {
        if ([website.url isEqualToString:url]) {
            NSLog(@"网站已存在: %@", url);
            return;
        }
    }
    
    HLMonitoredWebsite *website = [[HLMonitoredWebsite alloc] initWithName:name url:url];
    [self.websites addObject:website];
    [self saveToFile];
    
    NSLog(@"添加监控网站: %@ - %@", name, url);
}

- (void)removeWebsiteWithName:(NSString *)name {
    if (!name.length) return;
    
    for (NSInteger i = self.websites.count - 1; i >= 0; i--) {
        HLMonitoredWebsite *website = self.websites[i];
        if ([website.name isEqualToString:name]) {
            [self.websites removeObjectAtIndex:i];
            [self saveToFile];
            NSLog(@"删除监控网站: %@", name);
            break;
        }
    }
}

- (void)removeWebsiteWithURL:(NSString *)url {
    if (!url.length) return;
    
    for (NSInteger i = self.websites.count - 1; i >= 0; i--) {
        HLMonitoredWebsite *website = self.websites[i];
        if ([website.url isEqualToString:url]) {
            [self.websites removeObjectAtIndex:i];
            [self saveToFile];
            NSLog(@"删除监控网站: %@", url);
            break;
        }
    }
}

- (NSArray<HLMonitoredWebsite *> *)getAllWebsites {
    return [self.websites copy];
}

- (HLMonitoredWebsite *)getWebsiteWithName:(NSString *)name {
    if (!name.length) return nil;
    
    for (HLMonitoredWebsite *website in self.websites) {
        if ([website.name isEqualToString:name]) {
            return website;
        }
    }
    return nil;
}

- (HLMonitoredWebsite *)getWebsiteWithURL:(NSString *)url {
    if (!url.length) return nil;

    for (HLMonitoredWebsite *website in self.websites) {
        if ([website.url isEqualToString:url]) {
            return website;
        }
    }
    return nil;
}

#pragma mark - 自动同步站点

- (NSArray *)getBuiltInSiteNames {
    NSArray *builtInSites = [self loadBuiltInSitesConfig];
    NSMutableArray *names = [NSMutableArray array];
    for (NSDictionary *site in builtInSites) {
        [names addObject:site[@"name"]];
    }
    return [names copy];
}

- (NSArray *)getBuiltInSiteURLs {
    NSArray *builtInSites = [self loadBuiltInSitesConfig];
    NSMutableArray *urls = [NSMutableArray array];
    for (NSDictionary *site in builtInSites) {
        [urls addObject:site[@"url"]];
    }
    return [urls copy];
}

- (NSArray *)loadBuiltInSitesConfig {
    // 直接从HLHomeViewController获取最新的内置站点配置
    // 这样确保监控功能始终与主应用的内置站点保持同步
    NSArray *sites = [HLHomeViewController getBuiltInSitesInfo];
    NSLog(@"从HLHomeViewController获取了 %ld 个内置站点", sites.count);
    return sites;
}



- (void)syncBuiltInSites {
    // 从HLHomeViewController动态获取最新的内置站点列表
    NSArray *builtInSites = [HLHomeViewController getBuiltInSitesInfo];

    for (NSDictionary *siteInfo in builtInSites) {
        NSString *name = siteInfo[@"name"];
        NSString *url = siteInfo[@"url"];

        if (!name.length || !url.length) continue;

        // 排除CCTV、Emby、抖音短剧和直播站点
        if ([name isEqualToString:@"CCTV"] ||
            [name isEqualToString:@"Emby"] ||
            [name isEqualToString:@"抖音短剧"] ||
            [name isEqualToString:@"直播"]) {
            NSLog(@"跳过%@站点监控: %@ - %@", name, name, url);
            continue;
        }

        // 检查是否已存在
        BOOL exists = NO;
        for (HLMonitoredWebsite *website in self.websites) {
            if ([website.url isEqualToString:url]) {
                exists = YES;
                break;
            }
        }

        if (!exists) {
            HLMonitoredWebsite *website = [[HLMonitoredWebsite alloc] initWithName:name url:url];
            [self.websites addObject:website];
            NSLog(@"添加内置站点监控: %@ - %@", name, url);
        }
    }
}

- (void)syncCustomSites {
    // 获取用户自定义站点
    NSArray *customSites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"CustomSites"] ?: @[];

    for (NSDictionary *site in customSites) {
        NSString *name = site[@"name"];
        NSString *url = site[@"url"];

        if (!name.length || !url.length) continue;

        // 检查是否已存在
        BOOL exists = NO;
        for (HLMonitoredWebsite *website in self.websites) {
            if ([website.url isEqualToString:url]) {
                exists = YES;
                break;
            }
        }

        if (!exists) {
            HLMonitoredWebsite *website = [[HLMonitoredWebsite alloc] initWithName:name url:url];
            [self.websites addObject:website];
            NSLog(@"添加自定义站点监控: %@ - %@", name, url);
        }
    }

    // 添加✨✨✨自定义网址到监控
    NSString *userCustomURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserCustomSiteURL"];
    if (userCustomURL.length > 0) {
        // 检查是否已存在
        BOOL exists = NO;
        for (HLMonitoredWebsite *website in self.websites) {
            if ([website.url isEqualToString:userCustomURL]) {
                exists = YES;
                break;
            }
        }

        if (!exists) {
            HLMonitoredWebsite *website = [[HLMonitoredWebsite alloc] initWithName:@"✨✨✨" url:userCustomURL];
            [self.websites addObject:website];
            NSLog(@"添加✨✨✨自定义网址监控: %@", userCustomURL);
        }
    }
}

- (void)syncAllSites {
    // 清理已存在的CCTV、Emby、抖音短剧和直播监控数据
    [self removeWebsiteWithName:@"CCTV"];
    [self removeWebsiteWithName:@"Emby"];
    [self removeWebsiteWithName:@"抖音短剧"];
    [self removeWebsiteWithName:@"直播"];

    [self syncBuiltInSites];
    [self syncCustomSites];
    [self saveToFile];
    NSLog(@"站点同步完成，当前监控 %ld 个站点", self.websites.count);
}

#pragma mark - 监控控制

- (void)checkAllWebsitesNow {
    if (self.isChecking) {
        NSLog(@"正在检查中，请稍候...");
        return;
    }

    if (self.websites.count == 0) {
        NSLog(@"没有需要检查的网站");
        return;
    }

    self.isChecking = YES;
    NSLog(@"开始检查 %ld 个网站状态...", self.websites.count);

    __block NSInteger completedCount = 0;
    NSInteger totalCount = self.websites.count;

    for (HLMonitoredWebsite *website in self.websites) {
        [self checkWebsite:website completion:^(BOOL success) {
            completedCount++;
            if (completedCount >= totalCount) {
                self.isChecking = NO;
                NSLog(@"所有网站检查完成");

                // 发送检查完成通知
                [[NSNotificationCenter defaultCenter] postNotificationName:@"WebsiteCheckCompleted"
                                                                    object:self
                                                                  userInfo:@{@"totalCount": @(totalCount)}];
            }
        }];
    }
}

- (void)checkWebsite:(HLMonitoredWebsite *)website completion:(void(^)(BOOL success))completion {
    if (!website || !website.url.length) {
        if (completion) completion(NO);
        return;
    }

    NSURL *url = [NSURL URLWithString:website.url];
    if (!url) {
        website.status = HLWebsiteStatusError;
        website.errorMessage = @"无效的URL";
        website.consecutiveFailures++;
        website.lastCheckTime = [NSDate date];
        if (completion) completion(NO);
        return;
    }

    NSDate *startTime = [NSDate date];
    HLWebsiteStatus oldStatus = website.status;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"HEAD"; // 使用HEAD请求减少流量
    request.timeoutInterval = self.requestTimeout;

    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request
                                                    completionHandler:^(NSData * _Nullable data,
                                                                      NSURLResponse * _Nullable response,
                                                                      NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSTimeInterval responseTime = [[NSDate date] timeIntervalSinceDate:startTime] * 1000; // 转换为毫秒
            website.responseTime = responseTime;
            website.lastCheckTime = [NSDate date];

            BOOL success = NO;

            if (error) {
                website.status = HLWebsiteStatusOffline;
                website.errorMessage = error.localizedDescription;
                website.consecutiveFailures++;
                NSLog(@"网站检查失败 %@: %@", website.name, error.localizedDescription);
            } else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSInteger statusCode = httpResponse.statusCode;

                if (statusCode >= 200 && statusCode < 400) {
                    website.status = HLWebsiteStatusOnline;
                    website.errorMessage = @"";
                    website.consecutiveFailures = 0;
                    success = YES;
                    NSLog(@"网站在线 %@: %ld (%.0fms)", website.name, statusCode, responseTime);
                } else {
                    website.status = HLWebsiteStatusError;
                    website.errorMessage = [NSString stringWithFormat:@"HTTP %ld", statusCode];
                    website.consecutiveFailures++;
                    NSLog(@"网站错误 %@: HTTP %ld", website.name, statusCode);
                }
            } else {
                website.status = HLWebsiteStatusError;
                website.errorMessage = @"未知响应类型";
                website.consecutiveFailures++;
            }

            // 如果状态发生变化，发送通知
            if (oldStatus != website.status && oldStatus != HLWebsiteStatusUnknown) {
                [self sendNotificationForWebsite:website oldStatus:oldStatus newStatus:website.status];
            }

            // 保存数据
            [self saveToFile];

            if (completion) completion(success);
        });
    }];

    [task resume];
}

#pragma mark - 数据持久化

- (void)saveToFile {
    NSMutableArray *websiteArray = [NSMutableArray array];
    for (HLMonitoredWebsite *website in self.websites) {
        [websiteArray addObject:[website toDictionary]];
    }

    NSDictionary *data = @{
        @"websites": websiteArray,
        @"requestTimeout": @(self.requestTimeout)
    };

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"保存监控数据失败: %@", error.localizedDescription);
        return;
    }

    // 确保目录存在
    NSString *dirPath = [MONITOR_DATA_PATH stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];

    BOOL success = [jsonData writeToFile:MONITOR_DATA_PATH atomically:YES];
    if (success) {
        NSLog(@"监控数据已保存到: %@", MONITOR_DATA_PATH);
    } else {
        NSLog(@"保存监控数据失败");
    }
}

- (void)loadFromFile {
    if (![[NSFileManager defaultManager] fileExistsAtPath:MONITOR_DATA_PATH]) {
        NSLog(@"监控数据文件不存在");
        return;
    }

    NSError *error;
    NSData *jsonData = [NSData dataWithContentsOfFile:MONITOR_DATA_PATH];
    if (!jsonData) {
        NSLog(@"读取监控数据文件失败");
        return;
    }

    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        NSLog(@"解析监控数据失败: %@", error.localizedDescription);
        return;
    }

    // 加载网站列表
    NSArray *websiteArray = data[@"websites"];
    [self.websites removeAllObjects];
    for (NSDictionary *websiteDict in websiteArray) {
        HLMonitoredWebsite *website = [[HLMonitoredWebsite alloc] initWithDictionary:websiteDict];
        [self.websites addObject:website];
    }

    // 加载设置
    if (data[@"requestTimeout"]) {
        self.requestTimeout = [data[@"requestTimeout"] doubleValue];
    }

    NSLog(@"已加载 %ld 个监控网站", self.websites.count);
}

- (void)clearCache {
    // 清除监控数据文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:MONITOR_DATA_PATH]) {
        NSError *error;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:MONITOR_DATA_PATH error:&error];
        if (success) {
            NSLog(@"监控缓存已清除");
        } else {
            NSLog(@"清除监控缓存失败: %@", error.localizedDescription);
        }
    }

    // 清除内存中的数据
    [self.websites removeAllObjects];
    self.isChecking = NO;

    NSLog(@"监控数据已重置");
}

#pragma mark - 通知相关

- (void)sendNotificationForWebsite:(HLMonitoredWebsite *)website
                        oldStatus:(HLWebsiteStatus)oldStatus
                        newStatus:(HLWebsiteStatus)newStatus {

    NSString *title = @"优选影视";
    NSString *body = @"";
    NSString *statusText = @"";

    switch (newStatus) {
        case HLWebsiteStatusOnline:
            statusText = @"恢复正常";
            body = [NSString stringWithFormat:@"%@ %@ (响应时间: %.0fms)", website.name, statusText, website.responseTime];
            break;
        case HLWebsiteStatusOffline:
            statusText = @"离线";
            body = [NSString stringWithFormat:@"%@ %@", website.name, statusText];
            if (website.errorMessage) {
                body = [body stringByAppendingFormat:@" - %@", website.errorMessage];
            }
            break;
        case HLWebsiteStatusError:
            statusText = @"错误";
            body = [NSString stringWithFormat:@"%@ %@", website.name, statusText];
            if (website.errorMessage) {
                body = [body stringByAppendingFormat:@" - %@", website.errorMessage];
            }
            break;
        default:
            return;
    }

    // 发送系统通知
    if (@available(macOS 10.14, *)) {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = title;
        content.body = body;
        content.sound = [UNNotificationSound defaultSound];

        NSString *identifier = [NSString stringWithFormat:@"website_monitor_%@_%ld",
                               website.url, (long)[[NSDate date] timeIntervalSince1970]];

        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                              content:content
                                                                              trigger:nil];

        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"发送通知失败: %@", error.localizedDescription);
            } else {
                NSLog(@"已发送通知: %@", body);
            }
        }];
    } else {
        // 对于较老的系统版本，使用NSUserNotification
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = title;
        notification.informativeText = body;
        notification.soundName = NSUserNotificationDefaultSoundName;

        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        NSLog(@"已发送通知(旧版): %@", body);
    }

    // 发送应用内通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WebsiteStatusChanged"
                                                        object:website
                                                      userInfo:@{
                                                          @"oldStatus": @(oldStatus),
                                                          @"newStatus": @(newStatus)
                                                      }];
}

- (void)dealloc {
    self.isChecking = NO;
}

@end
