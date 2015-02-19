//
//  RXQRCodeView.m
//  RXKit
//
//  Created by Sergei Epatov on 2/9/15.
//  SerjEpatoff@gmail.com
//

#import "RXQRCodeView.h"

#if !__has_feature(objc_arc)
#error "RXQRCodeView needs ARC"
#endif

#if TARGET_OS_IPHONE
#import <CoreImage/CoreImage.h>
#define NSImage UIImage
#define NSRect  CGRect
#define NSViewWidthSizable UIViewAutoresizingFlexibleWidth
#define NSViewHeightSizable UIViewAutoresizingFlexibleHeight
#else
#import <QuartzCore/CoreImage.h>
#endif

static NSString *const  kRXQRCodeGeneratorFilter    = @"CIQRCodeGenerator";
static NSString *const  kRXAztecCodeGeneratorFilter = @"CIAztecCodeGenerator";
static NSString *const  kRXPosterizeFilter          = @"CIColorPosterize";
static NSString *const  kRXInvertFilter             = @"CIColorInvert";
static NSString *const  kRXMaskToAlphaFilter        = @"CIMaskToAlpha";
static NSString *const  kRXInputMessageKey          = @"inputMessage";
static NSString *const  kRXInputLevelsKey           = @"inputLevels";
static const NSUInteger kRXInputLevelsValue         = 2;

@interface CIFilter(RXExtensions)
@property (nonatomic, readonly) CIImage *outputImage;

@end

@interface RXQRCodeView ()
@property (nonatomic, copy)   NSColor       *backgroundColor;
@property (nonatomic, assign) CGImageRef    straightAlphaMask;
@property (nonatomic, assign) CGImageRef    invertedAlphaMask;
@property (nonatomic, assign) BOOL          dirty;

- (void)generateImages;
- (void)rx_setNeedsDisplay;
- (NSImage *)rx_imageWithCGImage:(CGImageRef)cgImage;
- (CGContextRef)rx_currentGraphicsContext;

@end

@implementation RXQRCodeView

@synthesize backgroundColor = _backgroundColor;

#pragma mark -
#pragma mark Initializations and Deallocations

- (void)dealloc {
    self.text = nil;
    self.data = nil;
    self.straightAlphaMask = nil;
    self.invertedAlphaMask = nil;
}

- (id)init {
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    [self rx_setSuperBackgroundColor:[NSColor clearColor]];
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.type = RXQRCodeTypeQR;
    self.text = @"";
    
    if (!_backgroundColor) {
        self.backgroundColor = [NSColor whiteColor];
    }
    
    if (!_foregroundColor) {
        self.foregroundColor = [NSColor blackColor];
    }
}

#pragma mark -
#pragma mark Accessors

- (void)setText:(NSString *)text {
    self.data = [text dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)text {
    return [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
}

- (void)setData:(NSData *)data {
    if (_data != data) {
        _data = data;
        self.dirty = YES;
        [self rx_setNeedsDisplay];
    }
}

- (void)setStraightAlphaMask:(CGImageRef)QRCodeImage {
    if (_straightAlphaMask != QRCodeImage) {
        CGImageRelease(_straightAlphaMask);
        _straightAlphaMask = QRCodeImage;
    }
}

- (void)setInvertedAlphaMask:(CGImageRef)invertedQRCodeImage {
    if (_invertedAlphaMask != invertedQRCodeImage) {
        CGImageRelease(_invertedAlphaMask);
        _invertedAlphaMask = invertedQRCodeImage;
    }
}

- (void)setForegroundColor:(NSColor *)foregroundColor {
    _foregroundColor = [foregroundColor copy];
    [self rx_setNeedsDisplay];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    _backgroundColor = [backgroundColor copy];
    [self rx_setNeedsDisplay];
}

- (void)setType:(RXQRCodeType)type {
    if (_type != type) {
        _type = type;
        self.dirty = YES;
        [self rx_setNeedsDisplay];
    }
}

- (void)setRedundancy:(RXQRCodeRedundancy)redundancy {
    if (_redundancy != redundancy) {
        _redundancy = redundancy;
        self.dirty = YES;
        [self rx_setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark NSView/UIView

- (void)drawRect:(NSRect)dirtyRect {
    if (self.dirty) {
        self.dirty = NO;
        [self generateImages];
    }
    
    CGContextRef context = [self rx_currentGraphicsContext];
    
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    
    CGContextSaveGState(context);
    CGContextClipToMask(context, self.bounds, self.straightAlphaMask);
    CGContextSetFillColorWithColor(context, self.foregroundColor.CGColor);
    CGContextFillRect(context, self.bounds);
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    CGContextClipToMask(context, self.bounds, self.invertedAlphaMask);
    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextFillRect(context, self.bounds);
    CGContextRestoreGState(context);
}

#pragma mark -
#pragma mark Private

- (void)generateImages {
    NSString *generatorName = self.type == RXQRCodeTypeQR ? kRXQRCodeGeneratorFilter : kRXAztecCodeGeneratorFilter;
    
    CIFilter *generator = [CIFilter filterWithName:generatorName];
    CIFilter *posterizer = [CIFilter filterWithName:kRXPosterizeFilter];
    CIFilter *inverter = [CIFilter filterWithName:kRXInvertFilter];
    CIFilter *masker = [CIFilter filterWithName:kRXMaskToAlphaFilter];
    
    [generator setDefaults];
    [generator setValue:self.data forKey:kRXInputMessageKey];
    [posterizer setValue:[generator outputImage] forKey:kCIInputImageKey];
    [posterizer setValue:@(kRXInputLevelsValue) forKey:kRXInputLevelsKey];
    [masker setValue:[posterizer outputImage] forKey:kCIInputImageKey];
    CIImage *ciImageInverted = [masker outputImage];
    
    [inverter setValue:[posterizer outputImage] forKey:kCIInputImageKey];
    [masker setValue:[inverter outputImage] forKey:kCIInputImageKey];
    CIImage *ciImageStraight = [masker outputImage];
    
    CIContext *ciContext = [self rx_CIContext];
    CGRect extent = [ciImageStraight extent];
    self.invertedAlphaMask = [ciContext createCGImage:ciImageInverted fromRect:extent];
    self.straightAlphaMask = [ciContext createCGImage:ciImageStraight fromRect:extent];
}


#if TARGET_OS_IPHONE

- (void)rx_setNeedsDisplay {
    [self setNeedsDisplay];
}

- (NSImage *)rx_imageWithCGImage:(CGImageRef)cgImage {
    return [[NSImage alloc] initWithCGImage:cgImage];
}

- (CGContextRef)rx_currentGraphicsContext {
    return UIGraphicsGetCurrentContext();
}

- (CIContext *)rx_CIContext {
    return [CIContext contextWithOptions:nil];
}

- (void)rx_setSuperBackgroundColor:(NSColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
}

#else

- (void)rx_setNeedsDisplay {
    [self setNeedsDisplay:YES];
}

- (NSImage *)rx_imageWithCGImage:(CGImageRef)cgImage {
    return [[NSImage alloc] initWithCGImage:cgImage size:CGSizeZero];
}

- (CGContextRef)rx_currentGraphicsContext {
    return [[NSGraphicsContext currentContext] graphicsPort];
}

- (CIContext *)rx_CIContext {
    return [[CIContext alloc] init];
}

- (void)rx_setSuperBackgroundColor:(NSColor *)backgroundColor {
}

#endif

@end
