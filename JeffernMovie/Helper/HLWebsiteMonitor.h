//Jeffern影视平台 ©Jeffern 2025/7/23

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 网站状态枚举
typedef NS_ENUM(NSInteger, HLWebsiteStatus) {
    HLWebsiteStatusUnknown = 0,     // 未知状态
    HLWebsiteStatusOnline,          // 在线
    HLWebsiteStatusOffline,         // 离线
    HLWebsiteStatusError            // 错误
};

// 监控网站模型
@interface HLMonitoredWebsite : NSObject

@property (nonatomic, strong) NSString *name;          // 网站名称
@property (nonatomic, strong) NSString *url;           // 网站URL
@property (nonatomic, assign) HLWebsiteStatus status;  // 当前状态
@property (nonatomic, strong) NSDate *lastCheckTime;   // 最后检查时间
@property (nonatomic, assign) NSTimeInterval responseTime; // 响应时间(毫秒)
@property (nonatomic, strong) NSString *errorMessage;  // 错误信息
@property (nonatomic, assign) NSInteger consecutiveFailures; // 连续失败次数

- (instancetype)initWithName:(NSString *)name url:(NSString *)url;
- (NSDictionary *)toDictionary;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

// 网站监控管理器
@interface HLWebsiteMonitor : NSObject

@property (nonatomic, assign) NSTimeInterval requestTimeout; // 请求超时时间(秒)，默认30秒
@property (nonatomic, assign) BOOL isChecking; // 是否正在检查

+ (instancetype)sharedInstance;

// 监控网站管理
- (void)addWebsite:(NSString *)name url:(NSString *)url;
- (void)removeWebsiteWithName:(NSString *)name;
- (void)removeWebsiteWithURL:(NSString *)url;
- (NSArray<HLMonitoredWebsite *> *)getAllWebsites;
- (HLMonitoredWebsite * _Nullable)getWebsiteWithName:(NSString *)name;
- (HLMonitoredWebsite * _Nullable)getWebsiteWithURL:(NSString *)url;

// 自动同步站点
- (void)syncBuiltInSites;
- (void)syncCustomSites;
- (void)syncAllSites;

// 内置站点配置管理
- (NSArray *)loadBuiltInSitesConfig;

// 监控控制
- (void)checkAllWebsitesNow;
- (void)checkWebsite:(HLMonitoredWebsite *)website completion:(void(^)(BOOL success))completion;

// 数据持久化
- (void)saveToFile;
- (void)loadFromFile;
- (void)clearCache;

// 通知相关
- (void)sendNotificationForWebsite:(HLMonitoredWebsite *)website 
                        oldStatus:(HLWebsiteStatus)oldStatus 
                        newStatus:(HLWebsiteStatus)newStatus;

@end

NS_ASSUME_NONNULL_END
