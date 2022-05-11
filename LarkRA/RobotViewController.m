//
//  RobotViewController.m
//  LarkRA
//
//  Created by 赵天禹 on 2022/5/2.
//

#import "RobotViewController.h"

#ifndef GCD_SAFE_MAIN
#define GCD_SAFE_MAIN(block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }
#endif


@interface RobotViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UILabel *robotNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *clearBtn;

@end

static NSString * const placeHoderText = @"请输入要发送的内容";

@implementation RobotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.robotName;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(textFieldDidChangeValue:)
                                             name:UITextFieldTextDidChangeNotification
                                           object:self.textField];
    
    self.robotNameLabel.text = self.robotName;
    self.clearBtn.hidden = YES;
    [self showPlaceHoder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.textField becomeFirstResponder];
}

- (void)textInput {
    self.textLabel.textColor = UIColor.blackColor;
    self.clearBtn.hidden = NO;
}

- (void)showPlaceHoder {
    self.textLabel.text = placeHoderText;
    self.textLabel.textColor = UIColor.lightGrayColor;
    self.clearBtn.hidden = YES;
}

- (void)sendTextMessage:(NSString *)text complete:(dispatch_block_t)complete {
    NSString *jsonStr = [NSString stringWithFormat:@"{\"msg_type\":\"text\",\"content\":{\"text\":\"%@\"}}", text];
    NSDictionary *param = [self dictionaryWithJsonString:jsonStr];
    [self requestWithUrl:self.webhook param:param header:nil complete:^(BOOL isSuc, NSDictionary *result, NSString *errMsg) {
        if (isSuc) {
            complete ? complete() : nil;
        } else {
            NSInteger code = ((NSNumber *)result[@"code"]).intValue;
            [self showText:@"发送失败" detail:[NSString stringWithFormat:@"[%ld]-%@", (long)code, errMsg]];
        }
    }];
}

- (IBAction)clickClear:(id)sender {
    self.textField.text = @"";
    [self showPlaceHoder];
}

- (IBAction)clickEat:(id)sender {
    NSArray *eatAry = @[@"海底捞", @"螺蛳粉", @"轻食", @"便利蜂快餐", @"裤带面", @"老坑酸菜", @"鱼子酱", @"大肘子", @"不吃了"];
    NSInteger index = [self getRandomNumber:0 to:eatAry.count - 1];
    NSString *food = eatAry[index];
    NSString *text = [NSString stringWithFormat:@"今天中午吃: %@", food];
    
    __weak typeof(self) weakSelf = self;
    [self sendTextMessage:text complete:^{
        [weakSelf showText:text detail:nil];
    }];
}

- (NSInteger)getRandomNumber:(NSInteger)from to:(NSInteger)to {
    return from + arc4random() % (to - from + 1);
}

#pragma mark - TextField

- (void)textFieldDidChangeValue:(NSNotification *)notification {
    [self textInput];
    self.textLabel.text = self.textField.text;
    
    if (self.textField.text.length == 0) {
        [self showPlaceHoder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.textLabel.text.length > 0 &&
        ![self.textLabel.text isEqualToString:placeHoderText]
        ) {
        __weak typeof(self) weakSelf = self;
        [self sendTextMessage:self.textLabel.text complete:^{
            [weakSelf showText:@"发送成功" detail:nil];
        }];
        
        return YES;
    }
    return NO;
}

#pragma mark - Json Request

- (void)requestWithUrl:(NSString *)url
                 param:(NSDictionary *)param
                header:(NSDictionary *)header complete:(void(^)(BOOL isSuc, NSDictionary *result, NSString *errMsg))complete {
    NSURLRequest *req = [self makeReqWithUrl:url parameters:param header:header];
    NSURLSession *session = NSURLSession.sharedSession;
    session.configuration.timeoutIntervalForRequest = 60;
    session.configuration.timeoutIntervalForResource = 60;
    [[session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        GCD_SAFE_MAIN(^{
            if (!error) {
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                NSInteger code = ((NSNumber *)dictionary[@"code"]).intValue;
                NSString *msg = dictionary[@"msg"];
                if (code == 0) {
                    complete ? complete(YES, dictionary, nil) : nil;
                } else {
                    complete ? complete(NO, dictionary, msg) : nil;
                }
            } else {
                complete ? complete(NO, nil, error.localizedDescription) : nil;
            }
        });
    }] resume];
}

- (NSURLRequest *)makeReqWithUrl:(NSString *)urlStr
                      parameters:(NSDictionary *)parameters
                          header:(NSDictionary *)header {
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    if (parameters) {
        NSData *data= [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
        if (data) {
            request.HTTPBody = data;
        }
    }
    
    NSMutableDictionary *dictionary = [@{
            @"Content-Type": @"application/json",
            @"Accept": @"*/*",
    } mutableCopy];
    
    if (header) {
        [dictionary addEntriesFromDictionary:header];
    }
    request.allHTTPHeaderFields = dictionary;
    return request;
}

#pragma mark - Json Formart

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

#pragma mark - Message

- (void)showText:(NSString *)text detail:(NSString *)detail {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:text
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
        
    }];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
