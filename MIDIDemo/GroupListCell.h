//
//  GroupListCell.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/16.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GroupListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *groupName;
@property (weak, nonatomic) IBOutlet UILabel *groupType;
@property (weak, nonatomic) IBOutlet UILabel *groupStatus;

@end
