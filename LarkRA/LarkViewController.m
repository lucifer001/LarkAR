//
//  LarkViewController.m
//  LarkRA
//
//  Created by 赵天禹 on 2022/5/2.
//

#import "LarkViewController.h"
#import "RobotCell.h"
#import "RobotViewController.h"

#ifndef NSUSERDEFAULT
#define NSUSERDEFAULT [NSUserDefaults standardUserDefaults]
#endif

#ifndef LoadStoryboard
#define LoadStoryboard(className) \
[[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle bundleForClass:[self class]]] instantiateViewControllerWithIdentifier:NSStringFromClass([className class])];
#endif

static NSString *const kRobots = @"com.lark.ra.robot";

@interface LarkViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *dataAry;

@end

@implementation LarkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeDataAry];
    
    [self.tableView reloadData];
}

- (void)makeDataAry {
    self.dataAry = [NSMutableArray new];
    NSArray *localData = [NSUSERDEFAULT objectForKey:kRobots];
    if (localData && localData.count > 0) {
        [self.dataAry addObjectsFromArray:localData];
    }
}

- (IBAction)clickAdd:(id)sender {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"添加机器人"
                                                                              message:@"请输入机器人名称和webhook地址"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"机器人名称";
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"webhook地址";
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray *textfields = alertController.textFields;
        UITextField *namefield = textfields[0];
        UITextField *webhookfiled = textfields[1];
        if (namefield.text.length > 0 && webhookfiled.text > 0) {
            NSDictionary *dic = @{@"title": namefield.text, @"url": webhookfiled.text};
            [self.dataAry addObject:dic];
            [self.tableView reloadData];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dataAry.count - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            
            [NSUSERDEFAULT setObject:self.dataAry forKey:kRobots];
        }
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - UITableViewDelegate、UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataAry.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RobotCell *cell = [tableView dequeueReusableCellWithIdentifier:@"robotCell" forIndexPath:indexPath];
    
    NSDictionary *dic = self.dataAry[indexPath.row];
    NSString *title = dic[@"title"];
    NSString *url = dic[@"url"];
    cell.textLabel.text = title;
    cell.detailTextLabel.text = url;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dic = self.dataAry[indexPath.row];
    NSString *title = dic[@"title"];
    NSString *url = dic[@"url"];
    
    RobotViewController *robot = LoadStoryboard(RobotViewController);
    robot.robotName = title;
    robot.webhook = url;
    [self.navigationController pushViewController:robot animated:YES];
}

@end
