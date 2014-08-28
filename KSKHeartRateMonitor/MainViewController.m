//
//  MainViewController.m
//  HeartRateMonitor
//
//  Created by Sanjeeva on 2/3/14.
//  Copyright (c) 2014 Sanjeeva. All rights reserved.
//

#import "MainViewController.h"
#import "HeartRateMonitorViewController.h"
@interface MainViewController ()

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Heart Rate Monitor";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)heartRateMonitorTapped:(id)sender {
    HeartRateMonitorViewController *heartRateMonitorViewController = [[HeartRateMonitorViewController alloc]initWithNibName:@"HeartRateMonitorViewController" bundle:nil];
    [self.navigationController pushViewController:heartRateMonitorViewController animated:YES];
}

@end
