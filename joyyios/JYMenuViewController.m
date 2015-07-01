//
//  JYMenuViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYMenuViewController.h"
#import "JYMenuViewCell.h"
#import "JYPaymentViewController.h"
#import "JYUser.h"

@interface JYMenuViewController ()

@property(nonatomic) NSArray *stringList;
@property(nonatomic) NSArray *iconList;
@property(nonatomic, weak) UITableView *tableView;

@end


static CGFloat kHeaderHeight = 100;
static NSString *const kMenuCellIdentifier = @"menuCell";


@implementation JYMenuViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.stringList = [NSArray arrayWithObjects:
                       NSLocalizedString(@"PAYMENT", nil),
                       NSLocalizedString(@"HISTORY", nil),
                       NSLocalizedString(@"HELP", nil),
                       NSLocalizedString(@"NOTIFICATIONS", nil),
                       NSLocalizedString(@"SETTINGS", nil),
                       nil];
    self.iconList = [NSArray new];

    [self _createTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_createTableView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    tableView.separatorColor = ClearColor;
    tableView.backgroundColor = FlatBlack;
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[JYMenuViewCell class] forCellReuseIdentifier:kMenuCellIdentifier];
    self.tableView = tableView;
    [self.view addSubview:self.tableView];
}

- (UILabel *)_createLabel
{
    CGFloat width = CGRectGetWidth(self.view.frame) - kMarginLeft;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kMarginLeft, 0, width, kHeaderHeight)];
    label.font = [UIFont boldSystemFontOfSize:22];
    label.backgroundColor = FlatBlack;
    label.textColor = FlatWhite;
    label.textAlignment = NSTextAlignmentLeft;

    return label;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.stringList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYMenuViewCell *cell =
    (JYMenuViewCell *)[tableView dequeueReusableCellWithIdentifier:kMenuCellIdentifier forIndexPath:indexPath];

    cell.text = self.stringList[indexPath.row];
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JYMenuViewCell height];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [self _createLabel];
    label.text = [JYUser currentUser].email;

    return label;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *viewController = nil;

    viewController = [[JYPaymentViewController alloc] init];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: viewController];
    [self presentViewController:navigationController animated:YES completion:nil];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
