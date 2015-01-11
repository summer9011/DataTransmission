//
//  ChooseHardWareController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/10.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "ChooseHardWareController.h"
#import "SimulatorHardWareController.h"
#import "ChoosePlayerController.h"

#import "AppDelegate.h"

@interface ChooseHardWareController () <CBConnectionDelegate>

@property (weak, nonatomic) IBOutlet UITableView *table;
@property (nonatomic,strong) NSMutableArray *peripheralArr;

@property (nonatomic,strong) AppDelegate *dele;

@end

static NSString *CellIdentifier=@"HardWareCell";

@implementation ChooseHardWareController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.table registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.table.tableFooterView=[[UIView alloc] init];
    
    self.peripheralArr=[NSMutableArray array];
    
    self.dele=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.dele.CBDelegate=self;
    
    self.dele.centralManager=[[CBCentralManager alloc] initWithDelegate:self.dele queue:nil];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.dele.centralManager) {
        self.dele.centralManager.delegate=self.dele;
    }
}

//进入模拟
- (IBAction)goSimulatorHardWare:(id)sender {
    self.dele.centralManager.delegate=nil;
    
    if (self.dele.peripheral) {
        self.dele.peripheral.delegate=nil;
        self.dele.peripheral=nil;
    }
    
    UIStoryboard *story=[UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SimulatorHardWareController *simulatorVC=[story instantiateViewControllerWithIdentifier:@"SimulatorVC"];
    
    [self presentViewController:simulatorVC animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.peripheralArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    CBPeripheral *one=(CBPeripheral *)self.peripheralArr[indexPath.row];
    cell.textLabel.text=one.name;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.dele.centralManager stopScan];
    CBPeripheral *peripheral=(CBPeripheral *)self.peripheralArr[indexPath.row];
    NSLog(@"连接到外设:%@",peripheral);
    
    self.dele.peripheral=peripheral;
    [self.dele.centralManager connectPeripheral:self.dele.peripheral options:nil];
}

#pragma mark - CBConnectionDelegate

-(void)didFindPeripheral:(CBPeripheral *)peripheral {
    if (![self.peripheralArr containsObject:peripheral]) {
        [self.peripheralArr addObject:peripheral];
        [self.table reloadData];
    }
}

-(void)didConnectedPeripheral {
    UIStoryboard *story=[UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChoosePlayerController *choosePlayerVC=[story instantiateViewControllerWithIdentifier:@"ChoosePlayerVC"];
    
    [self.navigationController pushViewController:choosePlayerVC animated:YES];
}

@end
