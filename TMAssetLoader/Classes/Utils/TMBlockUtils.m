//
//  TMBlockUtils.m
//  TMAssetLoadEngine
//
//  Created by tomychen on 2020/12/25.
//

#import "TMBlockUtils.h"

@implementation TMBlockUtils
void doBlock(dispatch_queue_t queue, dispatch_block_t block)
{
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {
        block();
    } else {
        dispatch_async(queue, block);
    }
}

void doBlockSync(dispatch_queue_t queue, dispatch_block_t block)
{
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}

void doBlockMainQueue(dispatch_block_t block)
{
    doBlock(dispatch_get_main_queue(), block);
}

void doBlockMainQueueAfter(dispatch_block_t block, int64_t delayInSeconds)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        doBlock(dispatch_get_main_queue(), block);
    });
}

void doBlockSyncMainQueue(dispatch_block_t block)
{
    doBlockSync(dispatch_get_main_queue(), block);
}

@end
