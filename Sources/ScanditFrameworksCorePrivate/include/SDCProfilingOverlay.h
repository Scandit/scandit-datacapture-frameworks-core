/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

#import <ScanditCaptureCore/ScanditCaptureCore.h>

// `SDCProfilingOverlay` ships in ScanditCaptureCore as an exported symbol, but its header
// lives under `ScanditCaptureCore/Private/` and is therefore not part of the public module
// map the frameworks see. Re-declare the public-shaped surface here so ScanditFrameworksCore
// can construct it; the implementation is resolved at link time against ScanditCaptureCore.
// This keeps ScanditCaptureCore's PUBLIC API unchanged (the overlay stays a private SDK type).

NS_ASSUME_NONNULL_BEGIN

@class SDCDataCaptureContext;

@interface SDCProfilingOverlay : NSObject <SDCDataCaptureOverlay>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)overlayWithContext:(SDCDataCaptureContext *)context NS_SWIFT_NAME(init(context:));

@end

NS_ASSUME_NONNULL_END
