/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

#import <ScanditCaptureCore/ScanditCaptureCore.h>

// Forward declarations to expose private API
@protocol SDCControl;

NS_ASSUME_NONNULL_BEGIN

@interface SDCDataCaptureView (PrivateAccess)

@property (nonatomic, strong, readonly) NSMutableArray<id<SDCControl>> *controls;

@end

NS_ASSUME_NONNULL_END
