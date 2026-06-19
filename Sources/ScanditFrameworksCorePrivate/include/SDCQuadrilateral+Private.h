/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2017- Scandit AG. All rights reserved.
 */

#import <ScanditCaptureCore/SDCQuadrilateral.h>

SDC_EXTERN SDCQuadrilateral SDCQuadrilateralFromRect(CGRect rect);
SDC_EXTERN SDCQuadrilateral SDCQuadrilateralApplyTransform(SDCQuadrilateral quad,
                                                           CGAffineTransform transform);
SDC_EXTERN SDCQuadrilateral SDCQuadrilateralOffset(SDCQuadrilateral quad, CGPoint offset);
