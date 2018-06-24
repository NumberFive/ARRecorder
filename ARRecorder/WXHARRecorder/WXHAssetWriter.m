//
//  WXHAssetWriter.m
//  ARRecorder
//
//  Created by 伍小华 on 2018/3/1.
//  Copyright © 2018年 伍小华. All rights reserved.
//

#import "WXHAssetWriter.h"

#import <UIKit/UIKit.h>

static NSString *const WXHVideoFilename = @"WXHARRecorder.mp4";

@interface WXHAssetWriter ()
@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;

@property (nonatomic, strong) dispatch_queue_t writerQueue;

@property (nonatomic, strong) NSDictionary *videoSettings;
@property (nonatomic, strong) NSDictionary *audioSettings;

@property (nonatomic, assign) BOOL firstSample;
@end
@implementation WXHAssetWriter
- (instancetype)initWithVideoSettings:(NSDictionary *)videoSettings
                        audioSettings:(NSDictionary *)audioSettings
                        dispatchQueue:(dispatch_queue_t)dispatchQueue
{
    self = [super init];
    if (self) {
        _videoSettings = videoSettings;
        _audioSettings = audioSettings;
        _writerQueue = dispatchQueue;
        
        _firstSample = YES;        
    }
    return self;
}
- (void)startWriting
{
    if (_isWriting) {
        return;
    }
    __weak WXHAssetWriter *weakSelf = self;
    dispatch_async(self.writerQueue, ^{
        weakSelf.firstSample = YES;
        
        NSError *error = nil;
        weakSelf.writer = [AVAssetWriter assetWriterWithURL:[weakSelf outputURL]
                                               fileType:AVFileTypeMPEG4
                                                  error:&error];
        if (!weakSelf.writer || error) {
            WRITERLOG(@"Could not create AVAssetWriter: %@", [error localizedDescription]);
            return;
        }
        weakSelf.writer.shouldOptimizeForNetworkUse = YES;
        weakSelf.videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                         outputSettings:weakSelf.videoSettings];
        weakSelf.videoInput.expectsMediaDataInRealTime = YES;
        
//        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
//        self.videoInput.transform = TransformForDeviceOrientation(orientation);
        
        NSDictionary *attributes = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                     (id)kCVPixelBufferWidthKey : weakSelf.videoSettings[AVVideoWidthKey],
                                     (id)kCVPixelBufferHeightKey : weakSelf.videoSettings[AVVideoHeightKey]};
        
        weakSelf.pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:weakSelf.videoInput
                                                                             sourcePixelBufferAttributes:attributes];
        if ([weakSelf.writer canAddInput:weakSelf.videoInput]) {
            [weakSelf.writer addInput:weakSelf.videoInput];
        } else {
            WRITERLOG(@"Unable to add video input.");
            return;
        }
        
        weakSelf.audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                                         outputSettings:weakSelf.audioSettings];
        weakSelf.audioInput.expectsMediaDataInRealTime = YES;
        
        if ([weakSelf.writer canAddInput:weakSelf.audioInput]) {
            [weakSelf.writer addInput:weakSelf.audioInput];
        } else {
            WRITERLOG(@"Unable to add audio input.");
        }
        _isWriting = YES;
        weakSelf.firstSample = YES;
        
        if (![weakSelf.writer startWriting]) {
            WRITERLOG(@"Failed to start writing");
        }
    });
}

- (void)stopWriting:(CompletionHeander)completionHander
{
    if (_isWriting) {
        _isWriting = NO;
        __weak WXHAssetWriter *weakSelf= self;
        dispatch_async(self.writerQueue, ^{
            [weakSelf.writer finishWritingWithCompletionHandler:^{
                if (weakSelf.writer.status == AVAssetWriterStatusCompleted) {
                    if (completionHander) {
                        completionHander(weakSelf.writer.outputURL);
                    }
                } else {
                    WRITERLOG(@"Failed to write movie: %@", [weakSelf.writer.error localizedDescription]);
                }
            }];
        });
    }
}

- (void)appendPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (!_isWriting) {
        return;
    }
    CMTime time = CMTimeMakeWithSeconds(CACurrentMediaTime(), 1000);
    if (self.firstSample) {
        [self.writer startSessionAtSourceTime:time];
        self.firstSample = NO;
    }
    
    if (self.videoInput.isReadyForMoreMediaData && pixelBuffer) {
        if (![self.pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time]) {
            WRITERLOG(@"Error appending pixel buffer.");
        }
    }
}
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (!_isWriting) {
        return;
    }
    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);
    
    if (!self.firstSample && mediaType == kCMMediaType_Audio) {
        if (self.audioInput.isReadyForMoreMediaData) {
            if (![self.audioInput appendSampleBuffer:sampleBuffer]) {
                WRITERLOG(@"Error appending audio sample buffer.");
            }
        }
    }
}

- (NSURL *)outputURL
{
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:WXHVideoFilename];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }
    return url;
}

CGAffineTransform TransformForDeviceOrientation(UIDeviceOrientation orientation)
{
    CGAffineTransform result;
    
    switch (orientation) {
            
        case UIDeviceOrientationLandscapeRight:
            result = CGAffineTransformMakeRotation(M_PI);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            result = CGAffineTransformMakeRotation((M_PI_2 * 3));
            break;
            
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            result = CGAffineTransformMakeRotation(M_PI_2);
            break;
            
        default: // Default orientation of landscape left
            result = CGAffineTransformIdentity;
            break;
    }
    
    return result;
}
@end
