//
//  GroupInCell.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/15.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GroupInCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *groupInUserName;
@property (weak, nonatomic) IBOutlet UILabel *groupInUserStatus;
@property (weak, nonatomic) IBOutlet UILabel *groupInUserMusical;
@property (weak, nonatomic) IBOutlet UILabel *groupInUserMusicalStatus;
@property (weak, nonatomic) IBOutlet UILabel *groupInUserHost;
@property (weak, nonatomic) IBOutlet UIButton *groupInReadyBtn;

@end
