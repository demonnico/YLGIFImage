//
//  YLImageView+gifDownload.m
//  YLGIFImage
//
//  Created by Nicholas Tau on 5/29/14.
//  Copyright (c) 2014 Yong Li. All rights reserved.
//

#import "YLImageView+gifDownload.h"
#import <SDImageCache.h>
#import <objc/runtime.h>

@interface SDImageCache(privateMethods)
- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key;
@end

@interface YLImageView()
@property (nonatomic,strong) SDWebImageDownloaderOperation * downloader;
@property (nonatomic,strong) NSOperationQueue * operationQueue;
@end

@implementation YLImageView (gifDownload)

-(void)setDownloader:(SDWebImageDownloaderOperation *)downloader
{
    objc_setAssociatedObject(self, @selector(downloader), downloader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(SDWebImageDownloaderOperation*)downloader
{
    return objc_getAssociatedObject(self, _cmd);
}

-(NSOperationQueue*)operationQueue
{
    NSOperationQueue * queue = objc_getAssociatedObject(self, _cmd);
    if (!queue) {
        queue = [[NSOperationQueue alloc] init];
        objc_setAssociatedObject(self, _cmd, queue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return queue;
}

-(void)downloadGIFImageWithURL:(NSString*)url
              placeholderImage:(UIImage*)image
                      progress:(void (^)(NSInteger receivedSize, NSInteger expectedSize))progressBlock
                     completed:(void (^)(UIImage *image, NSData *data, NSError *error, BOOL finished))completedBlock
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
        __weak __typeof(&*self)weakSelf = self;
        self.downloader =
        [[SDWebImageDownloaderOperation alloc] initWithRequest:[NSURLRequest requestWithURL:URL]
                                                       options:SDWebImageDownloaderLowPriority
                                                      progress:progressBlock
                                                     completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                         dispatch_main_sync_safe(^(){
                                                             weakSelf.image = [YLGIFImage imageWithData:data];
                                                             [[SDImageCache sharedImageCache] storeImage:self.image
                                                                                    recalculateFromImage:NO
                                                                                               imageData:data
                                                                                                  forKey:url
                                                                                                  toDisk:YES];
                                                             if (completedBlock)
                                                                 completedBlock(image,data,error,finished);
                                                         });
                                                     } cancelled:cancelBlock];
        [self.operationQueue addOperation:self.downloader];
    }
}
-(void)cancelGIFDownload
{
    [self.downloader cancel];
}
@end
