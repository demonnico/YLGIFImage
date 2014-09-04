//
//  YLImageView+gifDownload.h
//  YLGIFImage
//
//  Created by Nicholas Tau on 5/29/14.
//  Copyright (c) 2014 Yong Li. All rights reserved.
//

#import "YLImageView.h"
#import "YLGIFImage.h"
#import <SDWebImageDownloaderOperation.h>

@interface YLImageView (gifDownload)
-(void)downloadGIFImageWithURL:(NSString*)url
              placeholderImage:(UIImage*)image
                      progress:(void (^)(NSInteger receivedSize, NSInteger expectedSize))progressBlock
                     completed:(void (^)(UIImage *image, NSData *data, NSError *error, BOOL finished))completedBlock
                     cancelled:(void (^)())cancelBlock;
-(void)cancelGIFDownload;
@end
