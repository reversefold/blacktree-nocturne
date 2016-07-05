//
//  QSCIEffectOverlay.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 11/20/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import "QSCIFilterWindow.h"
CGSConnection cid;

void DXSetWindowTag(int wid, CGSWindowTag tag,int state){	
  CGSConnection cid;
  
  cid = _CGSDefaultConnection();
  CGSWindowTag tags[2];
  tags[0] = tags[1] = 0;
  OSStatus retVal = CGSGetWindowTags(cid, wid, tags, 32);
  if(!retVal) {
    tags[0] = tag;
    if (state)
      retVal = CGSSetWindowTags(cid, wid, tags, 32);
    else
      retVal = CGSClearWindowTags(cid, wid, tags, 32);
  }
}

void DXSetWindowIgnoresMouse(int wid, int state){	
  DXSetWindowTag(wid,CGSTagTransparent,state);
}

#define NSRectToCGRect(r) CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height)
CGRect QSCGRectFromScreenFrame(NSRect rect){
  CGRect screenBounds = CGDisplayBounds(kCGDirectMainDisplay);
  CGRect cgrect=NSRectToCGRect(rect);
  cgrect.origin.y+=screenBounds.size.height;
  cgrect.origin.y -=rect.size.height;
  
  return cgrect;
}

CGSConnection cid;

@implementation QSCIFilterWindow
+ (void)initialize {
  cid=_CGSDefaultConnection();
}

- (id) init {
  self = [self initWithContentRect:[[NSScreen mainScreen] frame]
                         styleMask:NSBorderlessWindowMask
                           backing:NSBackingStoreBuffered
                             defer:NO];
  if (self != nil) {
    [self setHidesOnDeactivate:NO];
    [self setCanHide:NO];
    [self setIgnoresMouseEvents:YES];
    [self setLevel:CGWindowLevelForKey(kCGCursorWindowLevelKey)];
    [self setOpaque: NO];
    [self setBackgroundColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.0]];
    wid = [self windowNumber];
  }
  return self;
}

- (void) dealloc {
  [self setFilter:nil];
  [super dealloc];
}

- (void)setFilter:(NSString *)filterName{
    //NSRect rect = NSZeroRect;
    
    
    NSRect screenRect;
    NSArray *screenArray = [NSScreen screens];
    unsigned screenCount = [screenArray count];
    
    for (unsigned index = 0; index < screenCount; index++)
    {
        NSScreen *screen = [screenArray objectAtIndex: index];
        screenRect = [screen frame];
    }
    
    //rect.size = NSMakeSize(2000.0, 2000.0);
    
    /*
    NSWindow *newWin = [[NSWindow alloc] initWithContentRect:rect
                                                   styleMask:NSBorderlessWindowMask
                                                     backing:NSWindowBackingLocationDefault defer:YES];
    
    [newWin setBackgroundColor:[NSColor clearColor]];
    [newWin setOpaque:NO];
    [newWin setIgnoresMouseEvents:NO];
    [newWin setMovableByWindowBackground:YES];
    [newWin makeKeyAndOrderFront:self];
    */
    // you don't want to do this yet
    // [[newWin contentView] setWantsLayer:YES];
    
    NSRect contentFrame = [[self contentView] frame];
    CALayer *newWinLayer = [CALayer layer];
    newWinLayer.frame = NSRectToCGRect(contentFrame);
    
    // NOTE: remember that the following 2 *Create* methods return
    //  results that need to be released, unless you're using Garbage-Collection
    // Also, I'm guessing that `layer` is created somewhere?
    CALayer *layer = [CALayer layer];
    /*
    CGColorRef backgroundCol = CGColorCreateGenericGray(0.0f, 0.5f);
    CGColorRef borderCol = CGColorCreateGenericGray(0.756f, 0.5f);
    
    layer.backgroundColor=backgroundCol;
    layer.borderColor=borderCol;
    CGColorRelease(backgroundCol); CGColorRelease(borderCol);
     */
    //layer.borderWidth=5.0;
    
    
    CGImageRef screenImage = CGDisplayCreateImage(CGMainDisplayID());

    
    CIFilter *hueFilter = [CIFilter filterWithName:@"CIHueAdjust"];
    [hueFilter setValue: [NSNumber numberWithFloat:M_PI] forKey: @"inputAngle"];

    CIImage *ciImage = [[CIImage alloc] initWithCGImage:screenImage];
    [hueFilter setValue:ciImage forKey:kCIInputImageKey];
    
    CIImage *result = [hueFilter valueForKey: kCIOutputImageKey];
    CGRect extent = [result extent];
    
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CGImageRef filteredImage = [ciContext createCGImage:result fromRect:extent];
    //CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    //CGContextDrawImage(context, screenRect, filteredImage);

    /*
    //  Convert UIColor to CIColor
    CGColorRef colorRef = [UIColor randColor].CGColor;
    NSString *colorString = [CIColor colorWithCGColor:colorRef].stringRepresentation;
    CIColor *coreColor = [CIColor colorWithString:colorString];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    
    //  Convert UIImage to CIImage
    CIImage *ciImage = [[CIImage alloc] initWithImage:uIImage];
    
    //  Set values for CIColorMonochrome Filter
    CIFilter *filter = [CIFilter filterWithName:@"CIColorMonochrome"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    [filter setValue:@1.0 forKey:@"inputIntensity"];
    [filter setValue:coreColor forKey:@"inputColor"];
    
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    CGRect extent = [result extent];
    
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    
    UIImage *filteredImage = [[UIImage alloc] initWithCGImage:cgImage];
    */
    
    layer.contents = (id)filteredImage;
    
    // Calculate random origin point
    //rect.origin = SSRandomPointForSizeWithinRect( rect.size, [newWin frame] );
    
    // Set the layer frame to our random rectangle.
    layer.frame = NSRectToCGRect(screenRect);
    //layer.cornerRadius = 25.0f;
    
    [newWinLayer addSublayer:layer];
    
    NSView *view = [self contentView];
    
    // the order of the following 2 methods is critical:
    
    [view setLayer:newWinLayer];
    [view setWantsLayer:YES];
    [layer setBackgroundFilters:[NSArray arrayWithObject:hueFilter]];
    
/*
  if (fid){
    CGSRemoveWindowFilter(cid,wid,fid);
    CGSReleaseCIFilter(cid,fid);
  }
  if (filterName){
    CGError error = CGSNewCIFilterByName(cid, (CFStringRef) filterName, &fid);
    if ( noErr == error ) {
      error = CGSAddWindowFilter(cid,wid,fid, 0x00003001);
      if (error) NSLog(@"addfilter err %d",error);
    }
    if (error) NSLog(@"setfilter err %d",error);
  }
*/
}

-(void)setFilterValues:(NSDictionary *)filterValues{
  if (!fid) return;
  CGSSetCIFilterValuesFromDictionary(cid, fid, (CFDictionaryRef)filterValues);
}
@end
