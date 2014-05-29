//
//  YLImageView+gifDownload.m
//  YLGIFImage
//
//  Created by Nicholas Tau on 5/29/14.
//  Copyright (c) 2014 Yong Li. All rights reserved.
//

#import "YLImageView+gifDownload.h"
#import <SDImageCache.h>

@interface SDImageCache(privateMethods)
- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key;
@end

@interface YLImageView()
@property (nonatomic,strong) SDWebImageDownloaderOperation * downloader;
@end

@implementation YLImageView (gifDownload)
-(void)downloadGIFImageWithURL:(NSString*)url
              placeholderImage:(UIImage*)image
                      progress:(void (^)(NSInteger, NSInteger))progressBlock
                     completed:(void (^)(UIImage *, NSData *, NSError *, BOOL))completedBlock
                     cancelled:(void (^)())cancelBlock
{
    self.image = image;
    [self.downloader cancel];
    if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url]) {
        self.image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url];
        completedBlock(self.image,nil,nil,YES);
    }else if([[SDImageCache sharedImageCache] diskImageExistsWithKey:url]){
        NSData * gifImageData = [[SDImageCache sharedImageCache] diskImageDataBySearchingAllPathsForKey:url];
        UIImage * image = [YLGIFImage imageWithData:gifImageData];
        [[SDImageCache sharedImageCache] storeImage:image
                                             forKey:url
                                             toDisk:NO];
        self.image = image;
        completedBlock(self.image,gifImageData,nil,YES);
    }else{
        NSURL * URL = [NSURL URLWithString:url];
        self.downloader =
        [[SDWebImageDownloaderOperation alloc] initWithRequest:[NSURLRequest requestWithURL:URL]
                                                       options:SDWebImageDownloaderLowPriority
                                                      progress:progressBlock
                                                     completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                         self.image = [YLGIFImage imageWithData:data];
                                                          [[SDImageCache sharedImageCache] storeImage:self.image
                                                                                 recalculateFromImage:NO
                                                                                            imageData:data
                                                                                               forKey:url
                                                                                               toDisk:YES];
                                                     } cancelled:cancelBlock];
    }
}
@end
