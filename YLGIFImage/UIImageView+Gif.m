//
//  YLImageView.m
//  YLGIFImage
//
//  Created by Yong Li on 14-3-2.
//  Copyright (c) 2014年 Yong Li. All rights reserved.
//

#import "UIImageView+Gif.h"
#import "YLGIFImage.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface UIImageView ()

@property (nonatomic, strong) YLGIFImage *animatedImage;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic) NSTimeInterval accumulator;
@property (nonatomic) NSUInteger currentFrameIndex;
@property (nonatomic, strong) UIImage* currentFrame;
@property (nonatomic) NSUInteger loopCountdown;

@end

@implementation UIImageView(Gif)

#pragma mark runtimeAssociateProperty
-(YLGIFImage*)animatedImage
{
    return objc_getAssociatedObject(self, _cmd);
}

//-(void)setAnimatedImage:(YLGIFImage *)animatedImage
//{
//    objc_setAssociatedObject(self, @selector(animatedImage), animatedImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}

//-(CADisplayLink*)displayLink
//{
//    return objc_getAssociatedObject(self, _cmd);
//}

-(void)setDisplayLink:(CADisplayLink *)displayLink
{
    objc_setAssociatedObject(self, @selector(displayLink), displayLink, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIImage*)currentFrame
{
    return  objc_getAssociatedObject(self, _cmd);
}

-(void)setCurrentFrame:(UIImage *)currentFrame
{
    objc_setAssociatedObject(self, @selector(currentFrame), currentFrame, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSTimeInterval)accumulator
{
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

-(void)setAccumulator:(NSTimeInterval)accumulator
{
    objc_setAssociatedObject(self, @selector(accumulator), @(accumulator), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSUInteger)currentFrameIndex
{
   return  [objc_getAssociatedObject(self, _cmd) intValue];
}

-(void)setCurrentFrameIndex:(NSUInteger)currentFrameIndex
{
    objc_setAssociatedObject(self, @selector(currentFrameIndex), @(currentFrameIndex), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSUInteger)loopCountdown
{
   return  [objc_getAssociatedObject(self, _cmd) intValue];
}

-(void)setLoopCountdown:(NSUInteger)loopCountdown
{
    objc_setAssociatedObject(self, @selector(loopCountdown), @(loopCountdown), OBJC_ASSOCIATION_COPY_NONATOMIC);
}


#pragma mark Method Swizzing
+(void)load
{
    SEL selectors[] ={@selector(setImage:),@selector(setHighlighted:),@selector(image),@selector(isAnimating),@selector(startAnimating),@selector(stopAnimating),@selector(didMoveToWindow),@selector(didMoveToSuperview)};
    
    for (int i=0;i<7; i++) {
        SEL originalSelector = selectors[i];
        NSString * afterSelectorName = i<2?
        [NSStringFromSelector(originalSelector) stringByReplacingOccurrencesOfString:@":" withString:@"After:"]:
        [NSStringFromSelector(originalSelector) stringByAppendingString:@"After"];
        SEL afterSelector = NSSelectorFromString(afterSelectorName);
        
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method afterMethod = class_getInstanceMethod(self, afterSelector);
        method_exchangeImplementations(originalMethod, afterMethod);
    }
}

const NSTimeInterval kMaxTimeStep = 1; // note: To avoid spiral-o-death

- (CADisplayLink *)displayLink
{
    CADisplayLink * displayLink = objc_getAssociatedObject(self, _cmd);
    if (self.superview) {
        if (displayLink && self.animatedImage) {
            self.currentFrameIndex = 0;
            displayLink= [CADisplayLink displayLinkWithTarget:self selector:@selector(changeKeyframe:)];
            [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:self.runLoopMode];
        }
        self.displayLink = displayLink;
    } else {
        [displayLink invalidate];
        self.displayLink = nil;
    }
    return displayLink;
}

- (NSString *)runLoopMode
{
    return objc_getAssociatedObject(self, _cmd)?: NSRunLoopCommonModes;
}

- (void)setRunLoopMode:(NSString *)runLoopMode
{
    if (![runLoopMode isEqualToString:self.runLoopMode]){
        [self stopAnimating];
        
        NSRunLoop *runloop = [NSRunLoop mainRunLoop];
        [self.displayLink removeFromRunLoop:runloop forMode:self.runLoopMode];
        [self.displayLink addToRunLoop:runloop forMode:runLoopMode];
        
        objc_setAssociatedObject(self, @selector(runLoopMode), runLoopMode, OBJC_ASSOCIATION_COPY_NONATOMIC);
        
        [self startAnimating];
    }
}

- (void)setImageAfter:(UIImage *)image
{
    if (image == self.image) {
        return;
    }
    
    [self stopAnimating];
    
    self.currentFrameIndex = 0;
    self.loopCountdown = 0;
    self.accumulator = 0;
    
    if ([image isKindOfClass:[YLGIFImage class]] && image.images) {
        if([image.images[0] isKindOfClass:UIImage.class])
            [self setImageAfter:image.images[0]];
        else
            [self setImageAfter:nil];
        self.currentFrame = nil;
        self.animatedImage = (YLGIFImage *)image;
        self.loopCountdown = self.animatedImage.loopCount ?: NSUIntegerMax;
        [self startAnimating];
    } else {
        self.animatedImage = nil;
        [self setImageAfter:image];
    }
    [self.layer setNeedsDisplay];
}

- (void)setAnimatedImage:(YLGIFImage *)animatedImage
{
    objc_setAssociatedObject(self, @selector(animatedImage), animatedImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (animatedImage == nil) {
        self.layer.contents = nil;
    }
}

- (BOOL)isAnimatingAfter
{
    return [self isAnimatingAfter] || (self.displayLink && !self.displayLink.isPaused);
}

- (void)stopAnimatingAfter
{
    if (!self.animatedImage) {
        [self stopAnimatingAfter];
        return;
    }
    
    self.loopCountdown = 0;
    
    self.displayLink.paused = YES;
}

- (void)startAnimatingAfter
{
    if (!self.animatedImage) {
        [self  startAnimatingAfter];
        return;
    }
    
    if (self.isAnimating) {
        return;
    }
    
    self.loopCountdown = self.animatedImage.loopCount ?: NSUIntegerMax;
    
    self.displayLink.paused = NO;
}

- (void)changeKeyframe:(CADisplayLink *)displayLink
{
    if (self.currentFrameIndex >= [self.animatedImage.images count]) {
        return;
    }
    self.accumulator += fmin(displayLink.duration, kMaxTimeStep);
    
    while (self.accumulator >= self.animatedImage.frameDurations[self.currentFrameIndex]) {
        self.accumulator -= self.animatedImage.frameDurations[self.currentFrameIndex];
        if (++self.currentFrameIndex >= [self.animatedImage.images count]) {
            if (--self.loopCountdown == 0) {
                [self stopAnimating];
                return;
            }
            self.currentFrameIndex = 0;
        }
        self.currentFrameIndex = MIN(self.currentFrameIndex, [self.animatedImage.images count] - 1);
        self.currentFrame = [self.animatedImage getFrameWithIndex:self.currentFrameIndex];
        [self.layer setNeedsDisplay];
    }
}

- (void)displayLayer:(CALayer *)layer
{
    if (!self.animatedImage || [self.animatedImage.images count] == 0) {
        return;
    }
    //NSLog(@"display index: %luu", (unsigned long)self.currentFrameIndex);
    if(self.currentFrame && ![self.currentFrame isKindOfClass:[NSNull class]])
        layer.contents = (__bridge id)([self.currentFrame CGImage]);
}

- (void)didMoveToWindowAfter
{
    [self didMoveToWindowAfter];
    if (self.window) {
        [self startAnimating];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.window) {
                [self stopAnimating];
            }
        });
    }
}

- (void)didMoveToSuperviewAfter
{
    [self didMoveToSuperviewAfter];
    if (self.superview) {
        //Has a superview, make sure it has a displayLink
        [self displayLink];
    } else {
        //Doesn't have superview, let's check later if we need to remove the displayLink
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displayLink];
        });
    }
}

- (void)setHighlightedAfter:(BOOL)highlighted
{
    if (!self.animatedImage) {
        [self setHighlightedAfter:highlighted];
    }
}

- (UIImage *)imageAfter
{
    return self.animatedImage ?: [self imageAfter];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return self.image.size;
}

@end

