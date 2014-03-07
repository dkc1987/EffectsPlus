#import <CoreImage/CIFilter.h>
#import <ImageIO/ImageIO.h>

@interface _UIBackdropView : UIView
@end

@interface CIBloom : CIFilter
@property(retain, nonatomic) NSNumber *inputRadius;
@end

@interface CIGloom : CIFilter
@property(retain, nonatomic) NSNumber *inputRadius;
@end

@interface CIGaussianBlur : CIFilter
@property(retain) CIImage *inputImage;
@property(copy) NSNumber *inputRadius;
@end

@interface CIStretch : CIFilter
@property(retain) CIImage *inputImage;
@end

@interface CITwirlDistortion : CIFilter
@property(retain) CIImage *inputImage;
@property(retain) CIVector *inputCenter;
@property(retain) NSNumber *inputRadius;
@end

@interface CIPinchDistortion : CIFilter
@property(retain) CIImage *inputImage;
@property(retain) CIVector *inputCenter;
@property(retain) NSNumber *inputRadius;
@end

@interface CIMirror : CIFilter
@property(retain) CIImage *inputImage;
@property(retain, nonatomic) NSNumber *inputAngle;
@property(copy) CIVector *inputPoint;
@end

@interface CITriangleKaleidoscope : CIFilter
@property(retain) CIImage *inputImage;
@property(copy) NSNumber *inputDecay;
@property(copy) NSNumber *inputSize;
@property(retain, nonatomic) NSNumber *inputAngle;
@property(copy) CIVector *inputPoint;
@end

@interface PBFilter : CIFilter
+ (PBFilter *)filterWithName:(NSString *)name;
- (CIFilter *)ciFilter;
- (void)applyParametersToCIFilter:(CIFilter *)ciFilter extent:(CGRect)extent;
@end

@interface PLEffectFilterManager : NSObject
+ (id)sharedInstance;
- (id)aggdNameForFilter:(id)filter;
- (id)displayNameForFilter:(id)filter;
- (id)displayNameForIndex:(unsigned)index;
- (unsigned)_indexForFilter:(id)filter;
- (void)_addEffectNamed:(NSString *)name aggdName:(NSString *)aggdName filter:(CIFilter *)filter;
- (unsigned)blackAndWhiteFilterCount;
- (unsigned)blackAndWhiteFilterStartIndex;
- (id)filterForIndex:(unsigned)index;
- (unsigned)filterCount;
- (id)init;
- (void)dealloc;
@end

@interface PLImageAdjustmentView
- (void)setEditedImage:(UIImage *)image;
@end

@interface CAMBottomBar : UIToolbar
@end

@interface PLCameraView
@property(readonly, assign, nonatomic) CAMBottomBar* _bottomBar;
@end

@interface CIFilter (LEPAddition)
- (NSDictionary *)_outputProperties;
@end

static NSString *identifierFix;
static BOOL internalBlurHook = NO;
static BOOL globalFilterHook = NO;

%hook PLManagedAsset

// Workaround for bypassing the filter identifier checking
- (id)_serializedPropertyDataFromFilter:(CIFilter *)filter
{
	return [filter _outputProperties];
}

- (CIImage *)filteredImage:(CIImage *)inputImage withCIContext:(CIContext *)context
{
	globalFilterHook = YES;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		globalFilterHook = NO;
	});
	return %orig;
}

- (void)generateThumbnailsWithImageSource:(CGImageSourceRef)arg1 imageData:(id)arg2 updateExistingLargePreview:(BOOL)arg3 allowMediumPreview:(BOOL)arg4 outSmallThumbnail:(id *)arg5 outLargeThumbnail:(id *)arg6
{
	globalFilterHook = YES;
	%orig;
	globalFilterHook = NO;
}

%end

%hook CIFilter

// This method returns filters identifier
- (NSString *)_serializedXMPString
{
	return identifierFix != nil ? identifierFix : %orig;
}

// The identifier of the unofficial filters are injected in this method
+ (id)_pl_propertyArrayFromFilters:(NSArray *)filterArray inputImageExtent:(id)arg2
{
	identifierFix = NSStringFromClass([[filterArray objectAtIndex:0] class]);
	return %orig;
}

%end

%hook CIImage

// This method will be very nice if it doesn't reduce the image size, so we have to fix that
- (CIImage *)_imageByApplyingBlur:(double)blur
{
	if (!internalBlurHook)
		return %orig;
	CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
	[gaussianBlurFilter setValue:self forKey:@"inputImage"]; 
	[gaussianBlurFilter setValue:[NSNumber numberWithDouble:blur] forKey:@"inputRadius"];
	CIImage *resultImage = [gaussianBlurFilter valueForKey:@"outputImage"];
	CGRect rect = self.extent;
	CIContext *context = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [context createCGImage:resultImage fromRect:rect];
	CIImage *outputImage = [CIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return outputImage;
}

%end

%hook CIGaussianBlur

- (CIImage *)outputImage
{
	if (!globalFilterHook)
		return %orig;
	CIImage *output = %orig;
	CGRect rect = self.inputImage.extent;
	/*double blur = [self.inputRadius doubleValue];
	rect.origin.x += blur;
	rect.origin.y += blur;
	rect.size.height -= blur*2.0f;
	rect.size.width -= blur*2.0f;*/
	CIContext *context = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [context createCGImage:output fromRect:rect];
	CIImage *outputImage = [CIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return outputImage;
}

%end

%hook CIStretch

- (CIImage *)outputImage
{
	if (!globalFilterHook)
		return %orig;
	CIImage *output = %orig;
	CGRect rect = self.inputImage.extent;
	CIContext *context = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [context createCGImage:output fromRect:rect];
	CIImage *outputImage = [CIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return outputImage;
}

%end

%hook CIMirror

- (CIImage *)outputImage
{
	if (!globalFilterHook)
		return %orig;
	CIImage *output = %orig;
	CGRect rect = self.inputImage.extent;
	CIContext *context = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [context createCGImage:output fromRect:rect];
	CIImage *outputImage = [CIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return outputImage;
}

%end

%hook CITriangleKaleidoscope

- (CIImage *)outputImage
{
	if (!globalFilterHook)
		return %orig;
	CIImage *output = %orig;
	CGRect rect = self.inputImage.extent;
	CIContext *context = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [context createCGImage:output fromRect:rect];
	CIImage *outputImage = [CIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return outputImage;
}

%end

%hook CIPinchDistortion

- (CIImage *)outputImage
{
	if (!globalFilterHook)
		return %orig;
	CIImage *output = %orig;
	CGRect rect = self.inputImage.extent;
	CIContext *context = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [context createCGImage:output fromRect:rect];
	CIImage *outputImage = [CIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return outputImage;
}

%end

%hook CITwirlDistortion

- (CIImage *)outputImage
{
	if (!globalFilterHook)
		return %orig;
	CIImage *output = %orig;
	CGRect rect = self.inputImage.extent;
	CIContext *context = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [context createCGImage:output fromRect:rect];
	CIImage *outputImage = [CIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return outputImage;
}

%end

%hook PLImageAdjustmentView

// Workaround for preventing the mismatch of image size checking, it causes crashing if the old image size is not equal to the edited image size
- (void)replaceEditedImage:(UIImage *)image
{
	[self setEditedImage:image];
}

%end

%hook PLImageUtilties

+ (BOOL)generateThumbnailsFromJPEGData:(id)data inputSize:(CGSize)size preCropLargeThumbnailSize:(BOOL)crop postCropLargeThumbnailSize:(CGSize)arg4 preCropSmallThumbnailSize:(CGSize)arg5 postCropSmallThumbnailSize:(CGSize)arg6 outSmallThumbnailImageRef:(CGImage *)arg7 outLargeThumbnailImageRef:(CGImage *)arg8 outLargeThumbnailJPEGData:(id *)arg9 generateFiltersBlock:(void(^)(void))arg10
{
	globalFilterHook = YES;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		globalFilterHook = NO;
	});
	return %orig;
}

%end

%hook PLCameraView

- (void)cameraController:(id)controller didStartTransitionToShowEffectsGrid:(BOOL)showEffectsGrid animated:(BOOL)animated
{
	%orig;
	self._bottomBar.hidden = showEffectsGrid;
}

%end

%hook PLEffectsGridView

// Set the exact cell count per row of the filters grid to fit all filters there
- (unsigned)_cellsPerRow
{
	return 6;
}

// Return the exact filters count to reduce the CPU processing for filters
- (unsigned)_cellCount
{
	return 28;
}

- (void)_renderGridFilters:(id)filters withInputImage:(id)inputImage ciContext:(id)context mirrorRendering:(BOOL)rendering
{
	%orig;
	internalBlurHook = NO;
	globalFilterHook = NO;
}

/*- (void)_updatePixelBufferPoolForSize:(CGSize)size
{
	%orig(CGSizeMake(size.width*0.6, size.height*0.6));
}

- (CVBufferRef)_createPixelBufferForSize:(CGSize)size
{
	return %orig(CGSizeMake(size.width*0.6, size.height*0.6));
}*/

/*- (CGRect)rectForFilterIndex:(unsigned)index
{
	CGRect orig = %orig;
	//NSLog(@"%@", NSStringFromCGRect(orig));
	return orig;
}*/

%end

%hook PLEffectsGridLabelsView

- (void)_replaceLabelViews:(id)view
{
	%orig;
	if (MSHookIvar<_UIBackdropView *>(self, "__backdropView") != nil) {
		[MSHookIvar<_UIBackdropView *>(self, "__backdropView") removeFromSuperview];
		[MSHookIvar<_UIBackdropView *>(self, "__backdropView") release];
		MSHookIvar<_UIBackdropView *>(self, "__backdropView") = nil;
	}
}

- (void)backdropViewDidChange:(id)change
{
}

- (void)set_backdropView:(id)view
{
}

- (id)_backdropView
{
	return nil;
}

%end

%hook PLCIFilterUtilities

// These CIFilter need some modification in order to make them work correctly
+ (CIImage *)outputImageFromFilters:(NSArray *)filters inputImage:(CIImage *)image orientation:(int)orientation copyFiltersFirst:(BOOL)copyFirst
{
	if ([filters count] == 0)
		return %orig; // FIXME: This causes crashing if there are no filters in the array
	CIFilter *filter = (CIFilter *)[filters objectAtIndex:0];
	NSString *filterName = filter.name;
	if ([filterName isEqualToString:@"CIBloom"] || [filterName isEqualToString:@"CIGloom"])
		internalBlurHook = YES;
	if ([filterName isEqualToString:@"CIGaussianBlur"] ||
		[filterName isEqualToString:@"CIStretch"] ||
		[filterName isEqualToString:@"CIMirror"] ||
		[filterName isEqualToString:@"CITriangleKaleidoscope"] ||
		[filterName isEqualToString:@"CITwirlDistortion"] ||
		[filterName isEqualToString:@"CIPinchDistortion"])
		globalFilterHook = YES;
	CGRect extent = [image extent];
	if ([filterName isEqualToString:@"CIMirror"]) {
		[(CIMirror *)filter setInputPoint:[CIVector vectorWithX:extent.size.width/2 Y:extent.size.height/2]];
		[(CIMirror *)filter setInputAngle:@(1.5*M_PI)];
	}
	else if ([filterName isEqualToString:@"CITriangleKaleidoscope"]) {
		[(CITriangleKaleidoscope *)filter setInputPoint:[CIVector vectorWithX:extent.size.width/2 Y:extent.size.height/2]];
		[(CITriangleKaleidoscope *)filter setInputSize:@500];
	}
	else if ([filterName isEqualToString:@"CIPinchDistortion"])
		[(CIPinchDistortion *)filter setInputCenter:orientation == 6 ? 	[CIVector vectorWithX:extent.size.width/2 Y:extent.size.height/2] :
																		[CIVector vectorWithX:extent.size.height/2 Y:extent.size.width/2]];
	else if ([filterName isEqualToString:@"CITwirlDistortion"])
		[(CITwirlDistortion *)filter setInputCenter:orientation == 6 ? 	[CIVector vectorWithX:extent.size.width/2 Y:extent.size.height/2] :
																		[CIVector vectorWithX:extent.size.height/2 Y:extent.size.width/2]];
	return %orig;
}

%end

%hook PLEffectsFullsizeView

- (void)_renderWithInputImage:(id)inputImage ciContext:(id)context mirrorRendering:(BOOL)rendering
{
	%orig;
	internalBlurHook = NO;
	globalFilterHook = NO;
}

%end

/*%hook CIContext

- (void)drawImage:(CIImage *)image inRect:(CGRect)rect fromRect:(CGRect)rect2
{
	MSHookIvar<struct CGRect>(image, "_priv") = CGRectMake(0, 0, 107, 142);
	if (llog)
		NSLog(@"An image: %@\ninRect: %@\nfromRect: %@", image, NSStringFromCGRect(rect), NSStringFromCGRect(rect2));
	%orig;
}

%end*/

static void _addPBEffect(NSString *displayName, NSString *filterName, PLEffectFilterManager *manager)
{
	PBFilter *filter = [PBFilter filterWithName:filterName];
	CIFilter *filter2 = [filter ciFilter];
	[filter applyParametersToCIFilter:filter2 extent:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width)];
	[manager _addEffectNamed:displayName aggdName:[displayName lowercaseString] filter:filter2];
}

static void _addCIEffect(NSString *displayName, NSString *filterName, PLEffectFilterManager *manager)
{
	CIFilter *filter = [CIFilter filterWithName:filterName];
	if ([filter.name isEqualToString:@"CIGloom"])
		[(CIGloom *)filter setInputRadius:@15];
	else if ([filter.name isEqualToString:@"CIBloom"])
		[(CIBloom *)filter setInputRadius:@15];
	else if ([filter.name isEqualToString:@"CITwirlDistortion"])
		[(CITwirlDistortion *)filter setInputRadius:@200];
	[manager _addEffectNamed:displayName aggdName:[displayName lowercaseString] filter:filter];
}

%hook PLEffectFilterManager

- (PLEffectFilterManager *)init
{
	PLEffectFilterManager *manager = %orig;
	if (manager != nil) {
		#define addPBEffect(arg1, arg2) _addPBEffect(arg1, arg2, manager)
		#define addCIEffect(arg1, arg2) _addCIEffect(arg1, arg2, manager)
		addCIEffect(@"Sepia", @"CISepiaTone");
		addCIEffect(@"Vibrance", @"CIVibrance");
		addCIEffect(@"Invert", @"CIColorInvert");
		addCIEffect(@"MonoC", @"CIColorMonochrome");
		addCIEffect(@"Posterize", @"CIColorPosterize");
		addCIEffect(@"Gloom", @"CIGloom");
		addCIEffect(@"Bloom", @"CIBloom");
		addCIEffect(@"Sharp", @"CISharpenLuminance");
		addCIEffect(@"SRGB", @"CILinearToSRGBToneCurve");
		addCIEffect(@"Pixel", @"CIPixellate");
		addCIEffect(@"Blur", @"CIGaussianBlur");
		addCIEffect(@"False", @"CIFalseColor");
		addCIEffect(@"Twirl", @"CITwirlDistortion");
		addCIEffect(@"Mirrors", @"CIWrapMirror");
		addCIEffect(@"Stretch", @"CIStretch");
		addCIEffect(@"Mirror", @"CIMirror");
		addCIEffect(@"Kaleidoscope", @"CITriangleKaleidoscope");
		addPBEffect(@"Thermal", @"PBThermalFilter");
		addPBEffect(@"Squeeze", @"PBSqueezeFilter");
	}
	return manager;
}

%end

%ctor
{
	%init;
}
