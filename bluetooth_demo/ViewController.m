//
//  ViewController.m
//  bluetooth_demo
//
//  Created by z on 2020/4/7.
//  Copyright © 2020 z. All rights reserved.
//

#import "ViewController.h"
#import "BeCentralViewController.h"
#import "BePeripheralViewController.h"

@interface ViewController () 


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)central:(id)sender {
    [self.navigationController pushViewController:[BeCentralViewController new] animated:YES];
}

- (IBAction)peripheral:(id)sender {
    [self.navigationController pushViewController:[UIStoryboard storyboardWithName:@"BePeripheralViewController" bundle:nil].instantiateInitialViewController animated:YES];
}


@end
