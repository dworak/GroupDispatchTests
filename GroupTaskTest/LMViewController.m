//
//  LMViewController.m
//  GroupTaskTest
//
//  Created by Lukasz Dworakowski on 15.03.2014.
//  Copyright (c) 2014 Lukasz Dworakowski. All rights reserved.
//

#import "LMViewController.h"
#include <pthread.h>

typedef void (^blokPrzykladowy)(mach_port_t);
#define SLEEP_TIME 1
#define TASK_NUMBERS 100

@interface LMViewController ()
@end

@implementation LMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Problem: We want to run some scheduled task async with their completion blocks.
    // Also we want to wait till the momment, when all of the tasks will be completed;
    
    dispatch_group_t grupa = dispatch_group_create();
    dispatch_queue_t kolejka = dispatch_queue_create("pl.dworak", 0);
    __block NSUInteger inProgress = TASK_NUMBERS;
    
    __weak LMViewController *weakSelf = self;
    for (int i = 0; i<TASK_NUMBERS; i++)
    {
        dispatch_group_async(grupa, kolejka, ^{
            [weakSelf taskWithNumber:i andCompletionBlock:^(mach_port_t machTID){
                NSLog(@"Koniec zadania nr %d w threadzie %x", i, machTID);
                
                NSUInteger localInProgress;
                
                @synchronized(weakSelf)
                {
                    localInProgress = --inProgress;
                }
                
                if(localInProgress ==0)
                {
                    NSLog(@"All task done");
                }
            }];
        });
    }
    
    dispatch_group_t grupa_another = dispatch_group_create();
    
    for (int i = 0; i<TASK_NUMBERS; i++)
    {
        dispatch_group_async(grupa_another, kolejka, ^{
            dispatch_group_enter(grupa_another);
            [weakSelf taskWithNumber:i andCompletionBlock:^(mach_port_t machTID){
                NSLog(@"Koniec zadania nr %d w threadzie %x", i, machTID);
                dispatch_group_leave(grupa_another);
            }];
        });
    }
    
    
    dispatch_group_notify(grupa_another, kolejka, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Wszystko sie zakonczylo");
        });
    });
	// Do any additional setup after loading the view, typically from a nib.
}


- (void) taskWithNumber: (int) taskNumber andCompletionBlock: (blokPrzykladowy) completionBlock
{
    usleep(arc4random_uniform(SLEEP_TIME));
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        usleep(arc4random_uniform(SLEEP_TIME));
               completionBlock(pthread_mach_thread_np(pthread_self()));
    });
}



@end
