//
//  RXQRCodeView.h
//  RXKit
//
//  Created by Sergei Epatov on 2/9/15.
//  SerjEpatoff@gmail.com
//

#pragma once

#ifndef __APPLE__
#error "RXQRCodeView is intended for iOS and MacOS only"
#endif

#include "TargetConditionals.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define NSView  UIView
#define NSColor UIColor
#else
#import <AppKit/AppKit.h>
#endif

typedef NS_ENUM(NSUInteger, RXQRCodeRedundancy) {
    RXQRCodeRedundancyLow = 0,
    RXQRCodeRedundancyMid,
    RXQRCodeRedundancyHigh
};

typedef NS_ENUM(NSUInteger, RXQRCodeType) {
    RXQRCodeTypeQR = 0,
    RXQRCodeTypeAztec
};

@interface RXQRCodeView : NSView
@property (nonatomic, assign)   RXQRCodeType        type;
@property (nonatomic, assign)   RXQRCodeRedundancy  redundancy;
@property (nonatomic, strong)   NSString            *text;
@property (nonatomic, strong)   NSData              *data;
@property (nonatomic, copy)     NSColor             *foregroundColor;

@end
