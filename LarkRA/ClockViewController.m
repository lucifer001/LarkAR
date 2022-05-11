//
//  ClockViewController.m
//  LarkRA
//
//  Created by 赵天禹 on 2022/5/2.
//

#import "ClockViewController.h"
#import "GCDTimer.h"

@interface ClockViewController ()<UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *clockBtn;
@property (weak, nonatomic) IBOutlet UIButton *loadingBtn;

@end

#ifndef weakify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
        #endif
    #endif
#endif

#ifndef strongify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
        #endif
    #endif
#endif

static NSString *const timer = @"com.clock.timer";

@implementation ClockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.delegate = self;
    
    self.clockBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    [self keepIdleTimerDisabled];
    
    __block NSInteger loadingIndex = 0;
    NSArray *loadingAry = @[@"( ´･ω･)", @"(　´･ω)", @"( 　 ´･)", @"( 　　´)", @"(        )", @"(`　　 )", @"(･` )", @"(ω･`　)", @"(･ω･` )", @"(´･ω･`)", @"( ´･ω･)", @"(　´･ω)", @"( 　 ´･)", @"( 　　´)", @"(        )"];
    
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(kCFCalendarUnitHour | kCFCalendarUnitMinute | kCFCalendarUnitSecond) fromDate: now];
    __block NSInteger hour = [components hour];
    __block NSInteger min = [components minute];
    __block NSInteger sec = [components second];
    @weakify(self)
    [GCDTimer scheduledTimer:timer start:0 interval:1 repeats:YES async:NO task:^{
        sec++;
        if (sec >= 60) {
            sec = 0;
            min++;
        }
        if (min >= 60) {
            min = 0;
            hour++;
        }
        if (hour >= 24) {
            hour = 0;
        }
        NSString *timeStr = [NSString stringWithFormat:@"%02ld : %02ld : %02ld", (long)hour, (long)min, (long)sec];
        
        
        loadingIndex++;
        if (loadingIndex >= loadingAry.count) {
            loadingIndex = 0;
        }
        NSString *loadingStr = [NSString stringWithFormat:@" %@", loadingAry[loadingIndex]];
        
        @strongify(self)
        [self.clockBtn setTitle:timeStr forState:UIControlStateNormal];
        [self.loadingBtn setTitle:loadingStr forState:UIControlStateNormal];
    }];
}

- (void)keepIdleTimerDisabled {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[UIApplication sharedApplication] addObserver:self
                                        forKeyPath:@"idleTimerDisabled"
                                           options:NSKeyValueObservingOptionNew
                                           context:nil];
}
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (![UIApplication sharedApplication].idleTimerDisabled) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
}

- (IBAction)click:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 判断要显示的控制器是否是自己
    BOOL isSelf = [viewController isKindOfClass:[self class]];
    [self.navigationController setNavigationBarHidden:isSelf animated:YES];
}

- (void)dealloc {
    [GCDTimer stopTimer:timer];
    
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:@"idleTimerDisabled"];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

@end
