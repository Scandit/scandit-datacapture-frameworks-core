/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

#import <Foundation/Foundation.h>

// Exported by ScanditCaptureCore without a public header. Declaration only: a second
// implementation in a plugin would shadow it at runtime.

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VolumeButtonObserver)
@interface SDCVolumeButtonObserver : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)volumeButtonObserverWithHandler:(void (^_Nonnull)(void))volumeChanged;
- (instancetype)initWithHandler:(void (^_Nonnull)(void))volumeChanged NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
