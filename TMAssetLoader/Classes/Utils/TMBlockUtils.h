//
//  TMBlockUtils.h
//  TMAssetLoadEngine
//
//  Created by tomychen on 2020/12/25.
//

#import <Foundation/Foundation.h>

@interface TMBlockUtils : NSObject

extern void doBlock(dispatch_queue_t queue, dispatch_block_t block);

extern void doBlockSync(dispatch_queue_t queue, dispatch_block_t block);

extern void doBlockMainQueue(dispatch_block_t block);

extern void doBlockMainQueueAfter(dispatch_block_t block, int64_t delayInSeconds);

extern void doBlockSyncMainQueue(dispatch_block_t block);

@end
