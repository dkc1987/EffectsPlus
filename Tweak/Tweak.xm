#import "../Common.h"
#import <CoreImage/CIFilter.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/ALAssetsLibrary.h>

static BOOL TweakEnabled;
static BOOL FillGrid;
static BOOL AutoHideBB;
static BOOL oldEditor;

static BOOL internalBlurHook = NO;
static BOOL globalFilterHook = NO;

static float CISepiaTone_inputIntensity;
static float CIVibrance_inputAmount;
static float CIColorMonochrome_inputIntensity;
static float CIColorMonochrome_R, CIColorMonochrome_G, CIColorMonochrome_B;
static float CIColorPosterize_inputLevels;
static float CIGloom_inputRadius, CIGloom_inputIntensity;
static float CIBloom_inputRadius, CIBloom_inputIntensity;
static float CISharpenLuminance_inputSharpness;
static float CIPixellate_inputScale;
static float CIGaussianBlur_inputRadius;
static float CIFalseColor_R1, CIFalseColor_G1, CIFalseColor_B1;
static float CIFalseColor_R2, CIFalseColor_G2, CIFalseColor_B2;
static float CITwirlDistortion_inputRadius, CITwirlDistortion_inputAngle;
static float CITriangleKaleidoscope_inputSize, CITriangleKaleidoscope_inputDecay;
static float CIPinchDistortion_inputRadius, CIPinchDistortion_inputScale;
static float CILightTunnel_inputRadius, CILightTunnel_inputRotation;
static float CIHoleDistortion_inputRadius;
static float CICircleSplashDistortion_inputRadius;
static float CICircularScreen_inputWidth, CICircularScreen_inputSharpness;
static float CILineScreen_inputAngle, CILineScreen_inputWidth, CILineScreen_inputSharpness;
static float CIMirror_inputAngle;

static float qualityFactor;
static int mode = 1;

static NSArray *enabledArray = nil;

%hook CIImage

- (CIImage *)_imageByApplyingBlur:(double)blur
{
	if (!internalBlurHook)
		return %orig;
	CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
	[gaussianBlurFilter setValue:self forKey:@"inputImage"]; 
	[gaussianBlurFilter setValue:[NSNumber numberWithDouble:blur] forKey:@"inputRadius"];
	CIImage *resultImage = [gaussianBlurFilter valueForKey:@"outputImage"];
	return resultImage;
}

%end

static inline CIImage *ciImageInternalFixIfNecessary(CIImage *outputImage, CIFilter *itsFilter)
{
	if (!globalFilterHook)
		return outputImage;
	CGRect rect = itsFilter.inputImage.extent;
	CIImage *fixedImage = [outputImage imageByCroppingToRect:rect];
	return fixedImage;
}

static inline NSDictionary *dictionaryByAddingSomeNativeValues(NSDictionary *inputDict)
{
	NSMutableDictionary *mutableInputDict = [inputDict mutableCopy];
	NSMutableArray *filterCategoriesArray = [(NSArray *)[mutableInputDict objectForKey:@"CIAttributeFilterCategories"] mutableCopy];
	if (filterCategoriesArray == nil)
		return inputDict;
	if (![filterCategoriesArray containsObject:@"CICategoryXMPSerializable"])
		[filterCategoriesArray addObject:@"CICategoryXMPSerializable"];
	[mutableInputDict setObject:filterCategoriesArray forKey:@"CIAttributeFilterCategories"];
	return (NSDictionary *)mutableInputDict;
}

@interface CINone : CIFilter {
    CIImage *inputImage;
}
@property (retain, nonatomic) CIImage *inputImage;
@end

@implementation CINone
@synthesize inputImage;

- (CIImage *)outputImage
{
    return inputImage;
}

@end

%hook CIFilter

+ (NSArray *)filterNamesInCategories:(NSArray *)categories
{
	NSMutableArray *orig = [%orig mutableCopy];
	if (orig != nil) {
		[orig addObject:CINoneName];
	}
	return orig;
}

- (NSString *)_serializedXMPString
{
	NSString *name = %orig;
	return name == nil ? [self name] : name;
}

%end

%hook CISharpenLuminance

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

- (void)setInputSharpness:(NSNumber *)sharpness
{
	%orig(globalFilterHook ? @(CISharpenLuminance_inputSharpness) : sharpness);
}

%end

%hook CIGaussianBlur

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

- (CIImage *)outputImage
{
	return ciImageInternalFixIfNecessary(%orig, self);
}

%end

%hook CIPixellate

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

- (CIImage *)outputImage
{
	return ciImageInternalFixIfNecessary(%orig, self);
}

%end

%hook CIMirror

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

- (CIImage *)outputImage
{
	return ciImageInternalFixIfNecessary(%orig, self);
}

%end

%hook CIXRay

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

%end

%hook CICircleSplashDistortion

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

- (CIImage *)outputImage
{
	return ciImageInternalFixIfNecessary(%orig, self);
}

%end

%hook CIStretch

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

- (CIImage *)outputImage
{
	return ciImageInternalFixIfNecessary(%orig, self);
}

%end

%hook CIThermal

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

%end

%hook CIColorInvert

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

%end

%hook CITriangleKaleidoscope

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

- (CIImage *)outputImage
{
	return ciImageInternalFixIfNecessary(%orig, self);
}

%end

%hook CIHoleDistortion

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

- (CIImage *)outputImage
{
	return ciImageInternalFixIfNecessary(%orig, self);
}

%end

%hook CIWrapMirror

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

%end

%hook CIPinchDistortion

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

- (CIImage *)outputImage
{
	return ciImageInternalFixIfNecessary(%orig, self);
}

%end

%hook CILightTunnel

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

- (CIImage *)outputImage
{
	return ciImageInternalFixIfNecessary(%orig, self);
}

%end

%hook CITwirlDistortion

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

%end

%hook CIColorMonochrome

- (void)setInputIntensity:(NSNumber *)intensity
{
	%orig(globalFilterHook ? @(CIColorMonochrome_inputIntensity) : intensity);
}

- (void)setInputColor:(CIColor *)color
{
	%orig(globalFilterHook ? [CIColor colorWithRed:CIColorMonochrome_R green:CIColorMonochrome_G blue:CIColorMonochrome_B] : color);
}

%end

%hook CIColorPosterize

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

- (void)setInputLevels:(NSNumber *)levels
{
	%orig(globalFilterHook ? @(CIColorPosterize_inputLevels) : levels);
}

%end

%hook CISepiaTone

- (void)setInputIntensity:(NSNumber *)intensity
{
	%orig(globalFilterHook ? @(CISepiaTone_inputIntensity) : intensity);
}

%end

%hook CIVibrance

- (void)setInputAmount:(NSNumber *)amount
{
	%orig(globalFilterHook ? @(CIVibrance_inputAmount) : amount);
}

%end

%hook CIBloom

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

%end

%hook CIGloom

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

%end

%hook CICircularScreen

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

%end

%hook CILineScreen

+ (NSDictionary *)customAttributes
{
	return dictionaryByAddingSomeNativeValues(%orig);
}

%end

/*%hook PLEffectsGridLabelsView

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

%end*/

static void effectCorrection(CIFilter *filter, CGRect extent, int orientation)
{
	NSString *filterName = filter.name;
	CIVector *normalHalfExtent = [CIVector vectorWithX:extent.size.width/2 Y:extent.size.height/2];
	CIVector *invertHalfExtent = [CIVector vectorWithX:extent.size.height/2 Y:extent.size.width/2];
	BOOL normal = (orientation == 0 || orientation == 1 || orientation == 3 || orientation == 5 || orientation == 6 || orientation == 8);
	CIVector *globalCenter = normal ? normalHalfExtent : invertHalfExtent;
	#define valueCorrection(value) @((extent.size.width/640)*value)
	if ([filterName isEqualToString:@"CIMirror"]) {
		[(CIMirror *)filter setInputPoint:normalHalfExtent];
		[(CIMirror *)filter setInputAngle:@(1.5*M_PI + CIMirror_inputAngle)];
	}
	else if ([filterName isEqualToString:@"CITriangleKaleidoscope"]) {
		[(CITriangleKaleidoscope *)filter setInputPoint:normalHalfExtent];
		[(CITriangleKaleidoscope *)filter setInputSize:valueCorrection(CITriangleKaleidoscope_inputSize)];
	}
	else if ([filterName isEqualToString:@"CIPixellate"]) {
		[(CIPixellate *)filter setInputScale:valueCorrection(CIPixellate_inputScale)];
		[(CIPixellate *)filter setInputCenter:globalCenter];
	}
	else if ([filterName isEqualToString:@"CIStretch"])
		[(CIStretch *)filter setInputPoint:globalCenter];
	else if ([filterName isEqualToString:@"CIPinchDistortion"]) {
		[(CIPinchDistortion *)filter setInputRadius:valueCorrection(CIPinchDistortion_inputRadius)];
		[(CIPinchDistortion *)filter setInputCenter:globalCenter];
	}
	else if ([filterName isEqualToString:@"CITwirlDistortion"]) {
		[(CITwirlDistortion *)filter setInputRadius:valueCorrection(CITwirlDistortion_inputRadius)];
		[(CITwirlDistortion *)filter setInputAngle:@(M_PI/2+CITwirlDistortion_inputAngle)];
		[(CITwirlDistortion *)filter setInputCenter:globalCenter];
	}
	else if ([filterName isEqualToString:@"CICircleSplashDistortion"]) {
		[(CICircleSplashDistortion *)filter setInputRadius:valueCorrection(CICircleSplashDistortion_inputRadius)];
		[(CICircleSplashDistortion *)filter setInputCenter:globalCenter];
	}
	else if ([filterName isEqualToString:@"CIHoleDistortion"]) {
		[(CIHoleDistortion *)filter setInputRadius:valueCorrection(CIHoleDistortion_inputRadius)];
		[(CIHoleDistortion *)filter setInputCenter:globalCenter];
	}
	else if ([filterName isEqualToString:@"CILightTunnel"]) {
		[(CILightTunnel *)filter setInputRadius:valueCorrection(CILightTunnel_inputRadius)];
		[(CILightTunnel *)filter setInputCenter:globalCenter];
	}
	else if ([filterName isEqualToString:@"CIGloom"])
		[(CIGloom *)filter setInputRadius:valueCorrection(CIGloom_inputRadius)];
	else if ([filterName isEqualToString:@"CIBloom"])
		[(CIBloom *)filter setInputRadius:valueCorrection(CIBloom_inputRadius)];
	else if ([filterName isEqualToString:@"CIGaussianBlur"])
		[(CIGaussianBlur *)filter setInputRadius:valueCorrection(CIGaussianBlur_inputRadius)];
	else if ([filterName isEqualToString:@"CISharpenLuminance"])
		[(CISharpenLuminance *)filter setInputSharpness:valueCorrection(CISharpenLuminance_inputSharpness)];
	else if ([filterName isEqualToString:@"CIColorMonochrome"])
		[(CIColorMonochrome *)filter setInputColor:[CIColor colorWithRed:CIColorMonochrome_R green:CIColorMonochrome_G blue:CIColorMonochrome_B]];
	else if ([filterName isEqualToString:@"CIFalseColor"]) {
		[(CIFalseColor *)filter setInputColor0:[CIColor colorWithRed:CIFalseColor_R1 green:CIFalseColor_G1 blue:CIFalseColor_B1]];
		[(CIFalseColor *)filter setInputColor1:[CIColor colorWithRed:CIFalseColor_R2 green:CIFalseColor_G2 blue:CIFalseColor_B2]];
	}
	else if ([filterName isEqualToString:@"CICircularScreen"]) {
		[(CICircularScreen *)filter setInputCenter:globalCenter];
		[(CICircularScreen *)filter setInputWidth:valueCorrection(CICircularScreen_inputWidth)];
	}
	else if ([filterName isEqualToString:@"CILineScreen"])
		[(CILineScreen *)filter setInputWidth:valueCorrection(CILineScreen_inputWidth)];
}

%hook PLCIFilterUtilities

+ (CIImage *)outputImageFromFilters:(NSArray *)filters inputImage:(CIImage *)image orientation:(UIImageOrientation)orientation copyFiltersFirst:(BOOL)copyFirst
{
	if ([filters count] == 0)
		return %orig;
	internalBlurHook = YES;
	globalFilterHook = YES;
	CGRect extent = [image extent];
	for (CIFilter *filter in filters) {
		if (![filter respondsToSelector:@selector(_outputProperties)])
			effectCorrection(filter, extent, orientation);
	}

	NSMutableArray *mutableFiltersArray = [filters mutableCopy];
	if ([filters count] > 1) {
		for (NSUInteger i = 0; i < [filters count]; i++) {
			if (![(CIFilter *)[mutableFiltersArray objectAtIndex:i] respondsToSelector:@selector(_outputProperties)]) {
				if (i != 0) {
					[mutableFiltersArray insertObject:[mutableFiltersArray objectAtIndex:i] atIndex:0];
					[mutableFiltersArray removeObjectAtIndex:i+1];
				}
			}
		}
	}
	CIImage *outputImage = %orig(mutableFiltersArray, image, orientation, copyFirst);
	internalBlurHook = NO;
	globalFilterHook = NO;
	return outputImage;
}

%end

static void configEffect(CIFilter *filter)
{
	NSString *filterName = filter.name;
	if ([filterName isEqualToString:@"CIGloom"])
		[(CIGloom *)filter setInputIntensity:@(CIGloom_inputIntensity)];
	else if ([filterName isEqualToString:@"CIBloom"])
		[(CIBloom *)filter setInputIntensity:@(CIBloom_inputIntensity)];
	else if ([filterName isEqualToString:@"CITwirlDistortion"])
		[(CITwirlDistortion *)filter setInputAngle:@(M_PI/2+CITwirlDistortion_inputAngle)];
	else if ([filterName isEqualToString:@"CIPinchDistortion"])
		[(CIPinchDistortion *)filter setInputScale:@(CIPinchDistortion_inputScale)];
	else if ([filterName isEqualToString:@"CIVibrance"])
		[(CIVibrance *)filter setInputAmount:@(CIVibrance_inputAmount)];
	else if ([filterName isEqualToString:@"CISepiaTone"])
		[(CISepiaTone *)filter setInputIntensity:@(CISepiaTone_inputIntensity)];
	else if ([filterName isEqualToString:@"CIColorMonochrome"])
		[(CIColorMonochrome *)filter setInputColor:[CIColor colorWithRed:CIColorMonochrome_R green:CIColorMonochrome_G blue:CIColorMonochrome_B]];
	else if ([filterName isEqualToString:@"CIFalseColor"]) {
		CIColor *color0 = [CIColor colorWithRed:CIFalseColor_R1 green:CIFalseColor_G1 blue:CIFalseColor_B1];
		CIColor *color1 = [CIColor colorWithRed:CIFalseColor_R2 green:CIFalseColor_G2 blue:CIFalseColor_B2];
		[(CIFalseColor *)filter setInputColor0:color0];
		[(CIFalseColor *)filter setInputColor1:color1];
	}
	else if ([filterName isEqualToString:@"CILightTunnel"])
		[(CILightTunnel *)filter setInputRotation:@(CILightTunnel_inputRotation)];
	else if ([filterName isEqualToString:@"CICircularScreen"]) {
		[(CICircularScreen *)filter setInputWidth:@(CICircularScreen_inputWidth)];
		[(CICircularScreen *)filter setInputSharpness:@(CICircularScreen_inputSharpness)];
	}
	else if ([filterName isEqualToString:@"CILineScreen"]) {
		[(CILineScreen *)filter setInputAngle:@(CILineScreen_inputAngle)];
		[(CILineScreen *)filter setInputSharpness:@(CILineScreen_inputSharpness)];
	}
}

static void _addCIEffect(NSString *displayName, NSString *filterName, NSObject *manager)
{
	if ([filterName hasPrefix:@"CIPhotoEffect"])
		return;
	CIFilter *filter = [CIFilter filterWithName:filterName];
	if (![MSHookIvar<NSMutableArray *>(manager, "_effects") containsObject:filter]) {
		configEffect(filter);
		[(id)manager _addEffectNamed:displayName aggdName:[displayName lowercaseString] filter:filter];
	}
}

static void addExtraSortedEffects(NSObject *effectFilterManager)
{
	#define addCIEffect(arg) _addCIEffect(displayNameFromCIFilterName(arg), arg, effectFilterManager)
	NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	if (prefDict != nil) {
		NSMutableArray *effects = [[prefDict objectForKey:ENABLED_EFFECT] mutableCopy];
		if (effects == nil)
			return;
		for (NSUInteger i = 0; i < [effects count]; i++) {
			NSString *string = [effects objectAtIndex:i];
			addCIEffect(string);
		}

		NSMutableArray *array = [NSMutableArray array];
		NSMutableArray *allEffects = MSHookIvar<NSMutableArray *>(effectFilterManager, "_effects");
		NSMutableArray *names = MSHookIvar<NSMutableArray *>(effectFilterManager, "_names");
		NSMutableArray *aggdNames = MSHookIvar<NSMutableArray *>(effectFilterManager, "_aggdNames");
		for (NSUInteger i = 0; i < [allEffects count]; i++) {
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
									(CIFilter *)[allEffects objectAtIndex:i], @"Filter",
									[names objectAtIndex:i], @"displayName",
									[aggdNames objectAtIndex:i], @"aggdName", nil];
			[array addObject:dict];
		}
		for (NSUInteger i = 0; i < [effects count]; i++) {
			NSString *string1 = [effects objectAtIndex:i];
			NSString *string2 = ((CIFilter *)[[array objectAtIndex:i] objectForKey:@"Filter"]).name;
			if (![string1 isEqualToString:string2]) {
				for (NSUInteger j = 0; j < [array count]; j++) {
					NSString *string3 = ((CIFilter *)[[array objectAtIndex:j] objectForKey:@"Filter"]).name;
					if ([string3 isEqualToString:string1])
						[array exchangeObjectAtIndex:i withObjectAtIndex:j];
				}
			}
		}
		NSArray *disabledEffects = [prefDict objectForKey:DISABLED_EFFECT];
		BOOL deleteSome = (disabledEffects != nil);
		if (deleteSome) {
			for (NSUInteger i = 0; i < [disabledEffects count]; i++) {
				for (NSUInteger j = 0; j < [array count]; j++) {
					if ([((CIFilter *)[[array objectAtIndex:j] objectForKey:@"Filter"]).name isEqualToString:[disabledEffects objectAtIndex:i]])
						[array removeObjectAtIndex:j];
				}
			}
		}
			
		NSMutableArray *a1 = [NSMutableArray array];
		for (NSUInteger i = 0; i < [array count]; i++) {
			[a1 addObject:[[array objectAtIndex:i] objectForKey:@"Filter"]];
		}
		[MSHookIvar<NSMutableArray *>(effectFilterManager, "_effects") setArray:a1];
			
		NSMutableArray *a2 = [NSMutableArray array];
		for (NSUInteger i = 0; i < [array count]; i++) {
			[a2 addObject:[[array objectAtIndex:i] objectForKey:@"displayName"]];
		}
		[MSHookIvar<NSMutableArray *>(effectFilterManager, "_names") setArray:a2];
			
		NSMutableArray *a3 = [NSMutableArray array];
		for (NSUInteger i = 0; i < [array count]; i++) {
			[a3 addObject:[[array objectAtIndex:i] objectForKey:@"aggdName"]];
		}
		[MSHookIvar<NSMutableArray *>(effectFilterManager, "_aggdNames") setArray:a3];
	}
}

static void showFilterSelectionAlert(id self)
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Effects+" message:@"ERROR: The selected filter isn't existed in the current library. You have to enable this filter in settings first." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

%group iOS7

%hook PLImageAdjustmentView

- (void)replaceEditedImage:(UIImage *)image
{
	[MSHookIvar<UIImage *>(self, "_editedImage") release];
	MSHookIvar<UIImage *>(self, "_editedImage") = [image retain];
	[self setEditedImage:MSHookIvar<UIImage *>(self, "_editedImage")];
	[MSHookIvar<UIImageView *>(self, "_imageView") setImage:MSHookIvar<UIImage *>(self, "_editedImage")];
}

%end

%hook PLEffectFilterManager

- (PLEffectFilterManager *)init
{
	PLEffectFilterManager *manager = %orig;
	addExtraSortedEffects(manager);
	return manager;
}

%end

%hook PLEffectsGridView

- (unsigned)_filterIndexForGridIndex:(unsigned)index
{
	return [self isBlackAndWhite] ? index + [[%c(PLEffectFilterManager) sharedInstance] blackAndWhiteFilterStartIndex] : index;
}

- (unsigned)_gridIndexForFilterIndex:(unsigned)index
{
	return [self isBlackAndWhite] ? index - [[%c(PLEffectFilterManager) sharedInstance] blackAndWhiteFilterStartIndex] : index;
}

- (unsigned)_cellsPerRow
{
	NSUInteger filterCount = [[%c(PLEffectFilterManager) sharedInstance] filterCount];
	NSUInteger i = 1;
	do {
		if (filterCount <= i*i)
			break;
		i++;
	} while (1);
	return i;
}

- (unsigned)_cellCount
{
	unsigned orig = %orig;
	if (FillGrid)
		return orig;
	return enabledArray != nil ? [enabledArray count] : orig;
}

- (void)_updatePixelBufferPoolForSize:(CGSize)size
{
	%orig(CGSizeMake(size.width*qualityFactor, size.height*qualityFactor));
}

- (CVBufferRef)_createPixelBufferForSize:(CGSize)size
{
	return %orig(CGSizeMake(size.width*qualityFactor, size.height*qualityFactor));
}

%end

%hook PLCameraView

- (void)_updateFilterButtonOnState
{
	%orig;
	PLCameraController *cameraController = MSHookIvar<PLCameraController *>(self, "_cameraController");
	CIFilter *currentFilter = [[%c(PLEffectFilterManager) sharedInstance] filterForIndex:[cameraController _activeFilterIndex]];
	CAMFilterButton *filterButton = MSHookIvar<CAMFilterButton *>(self, "__filterButton");
	BOOL shouldOn;
	if (currentFilter == nil)
		shouldOn = NO;
	else
		shouldOn = ![currentFilter.name isEqualToString:CINoneName];
	[filterButton setOn:shouldOn];
}

- (void)cameraController:(id)controller didStartTransitionToShowEffectsGrid:(BOOL)showEffectsGrid animated:(BOOL)animated
{
	%orig;
	if (AutoHideBB) {
		if (self._bottomBar != nil)
			self._bottomBar.hidden = showEffectsGrid;
		if (self._topBar != nil)
			self._topBar.hidden = showEffectsGrid;
	}
}

%end

%hook PLEffectSelectionViewController

- (NSArray *)_generateFilters
{
	PLEffectFilterManager *manager = [%c(PLEffectFilterManager) sharedInstance];
	NSUInteger filterCount = [manager filterCount];
    NSMutableArray *effects = [[NSMutableArray alloc] initWithCapacity:filterCount];
    NSUInteger index = 0;
	do {
		CIFilter *filter = [manager filterForIndex:index];
		if (![filter.name isEqualToString:CINoneName])
			[effects addObject:filter];
		index++;
	} while (filterCount != index);
	MSHookIvar<NSArray *>(self, "_effects") = effects;
    return effects;
}

- (void)setSelectedEffect:(CIFilter *)filter
{
	%log;
	if (filter != nil) {
		NSArray *filters = MSHookIvar<NSArray *>(self, "_effects");
		for (NSUInteger i = 0; i < [filters count]; i++) {
			if ([((CIFilter *)[filters objectAtIndex:i]).name isEqualToString:filter.name]) {
				[self _setSelectedIndexPath:[NSIndexPath indexPathForItem:i inSection:1]];
				return;
			}
		}
		showFilterSelectionAlert(self);
	} else
		%orig;
}

%end

%end

%group iOS8

/*
%hook PLPhotoEffect

+ (NSArray *)allEffects
{
	static NSMutableArray *effects = [NSMutableArray array];
	static dispatch_once_t onceToken;
	dispatch_once (&onceToken, ^{
		CAMEffectFilterManager *manager = [%c(CAMEffectFilterManager) sharedInstance];
		NSUInteger filterCount = [manager filterCount];
    	NSUInteger index = 0;
		do {
			CIFilter *filter = [manager filterForIndex:index];
			NSString *filterName = filter.name;
			NSString *displayName = displayNameFromCIFilterName(filterName);
			PLPhotoEffect *effect = [%c(PLPhotoEffect) _effectWithIdentifier:displayName CIFilterName:filterName displayName:displayName];
			[effects addObject:effect];
			index++;
		} while (filterCount != index);
	});
    return effects;
}

+ (PLPhotoEffect *)effectWithIdentifier:(NSString *)identifier
{
	return [[self allEffects] objectAtIndex:[self indexOfEffectWithIdentifier:identifier]];
}

+ (PLPhotoEffect *)effectWithCIFilterName:(NSString *)filterName
{
	PLPhotoEffect *targetEffect = nil;
	NSArray *allEffects = [%c(PLPhotoEffect) allEffects];
	for (NSUInteger i = 0; i < [allEffects count]; i++) {
		PLPhotoEffect *effect = [allEffects objectAtIndex:i];
		NSString *effectFilterName = [effect CIFilterName];
		if ([effectFilterName isEqualToString:filterName]) {
			targetEffect = effect;
			break;
		}
	}
	return targetEffect;
}

+ (NSUInteger)indexOfEffectWithIdentifier:(NSString *)identifier
{
	NSUInteger index = 0;
	NSArray *allEffects = [%c(PLPhotoEffect) allEffects];
	for (NSUInteger i = 0; i < [allEffects count]; i++) {
		PLPhotoEffect *effect = [allEffects objectAtIndex:i];
		NSString *effectIdentifier = [effect filterIdentifier];
		if ([effectIdentifier isEqualToString:identifier]) {
			index = i;
			break;
		}
	}
	return index;
}

%end
*/

%hook CAMEffectFilterManager

- (CAMEffectFilterManager *)init
{
	CAMEffectFilterManager *manager = %orig;
	addExtraSortedEffects(manager);
	return manager;
}

%end

%hook CAMEffectsGridView

- (unsigned)_filterIndexForGridIndex:(unsigned)index
{
	return [self isBlackAndWhite] ? index + [[%c(CAMEffectFilterManager) sharedInstance] blackAndWhiteFilterStartIndex] : index;
}

- (unsigned)_gridIndexForFilterIndex:(unsigned)index
{
	return [self isBlackAndWhite] ? index - [[%c(CAMEffectFilterManager) sharedInstance] blackAndWhiteFilterStartIndex] : index;
}

- (unsigned)_cellsPerRow
{
	NSUInteger filterCount = [[%c(CAMEffectFilterManager) sharedInstance] filterCount];
	NSUInteger i = 1;
	do {
		if (filterCount <= i*i)
			break;
		i++;
	} while (1);
	return i;
}

- (unsigned)_cellCount
{
	unsigned orig = %orig;
	if (FillGrid)
		return orig;
	return enabledArray != nil ? [enabledArray count] : orig;
}

%end

%hook CAMCameraView

- (void)_updateFilterButtonOnState
{
	%orig;
	CAMCaptureController *cameraController = MSHookIvar<CAMCaptureController *>(self, "_cameraController");
	CIFilter *currentFilter = [[%c(CAMEffectFilterManager) sharedInstance] filterForIndex:[cameraController _activeFilterIndex]];
	CAMFilterButton *filterButton = MSHookIvar<CAMFilterButton *>(self, "__filterButton");
	BOOL shouldOn;
	if (currentFilter == nil)
		shouldOn = NO;
	else
		shouldOn = ![currentFilter.name isEqualToString:CINoneName];
	[filterButton setOn:shouldOn];
}

- (void)cameraController:(id)controller didStartTransitionToShowEffectsGrid:(BOOL)showEffectsGrid animated:(BOOL)animated
{
	%orig;
	if (AutoHideBB) {
		if (self._bottomBar != nil)
			self._bottomBar.hidden = showEffectsGrid;
		if (self._topBar != nil)
			self._topBar.hidden = showEffectsGrid;
	}
}

%end

%hook CAMEffectSelectionViewController

- (void)setSelectedEffect:(CIFilter *)filter
{
	if (filter != nil) {
		NSArray *filters = MSHookIvar<NSArray *>(self, "_effects");
		for (NSUInteger i = 0; i < [filters count]; i++) {
			if ([((CIFilter *)[filters objectAtIndex:i]).name isEqualToString:filter.name]) {
				[self _setSelectedIndexPath:[NSIndexPath indexPathForItem:i inSection:1]];
				return;
			}
		}
		showFilterSelectionAlert(self);
	} else
		%orig;
}

%end

%hook PUPhotoEditProtoSettings

- (BOOL)useOldPhotosEditor2
{
	return oldEditor ? YES : %orig;
}

- (void)setUseOldPhotosEditor2:(BOOL)use
{
	%orig(oldEditor ? YES : use);
}

%end

%end

static PLProgressHUD *epHUD = nil;

%hook PLEditPhotoController

%new
- (void)ep_save:(int)mode
{
	switch (mode) {
		case 2:
			[self save:nil];
			break;
		case 3:
			[self _setControlsEnabled:NO animated:NO];
			epHUD = [[PLProgressHUD alloc] init];
			[epHUD setText:PLLocalizedFrameworkString(@"SAVING_PHOTO", nil)];
			[epHUD showInView:self.view];
			[self EPSavePhoto];
			break;
		case 4:
			MSHookIvar<BOOL>(self, "_savesAdjustmentsToCameraRoll") = YES;
			[self saveAdjustments];
			MSHookIvar<BOOL>(self, "_savesAdjustmentsToCameraRoll") = NO;
			break;
	}
}

%new
- (void)ep_showOptions
{
	if (mode == 1) {
		UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select saving options" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Default", @"New image", @"New image (w/ adjustments)", nil];
		sheet.tag = 9598;
		[sheet showInView:self.view];
		[sheet release];
	} else
		[self ep_save:mode];
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (popup.tag == 9598) {
		int mode = buttonIndex + 2;
		[self ep_save:mode];
	} else
		%orig;
}

%new
- (void)EPSavePhoto
{
	PLManagedAsset *asset = MSHookIvar<PLManagedAsset *>(self, "_editedPhoto");
	NSString *actualImagePath = isiOS8 ? [asset pathForOriginalFile] : [asset pathForImageFile];
	UIImage *actualImage = [UIImage imageWithContentsOfFile:actualImagePath];
	NSMutableArray *effectFilters = [[self _currentNonGeometryFiltersWithEffectFilters:MSHookIvar<NSArray *>(self, "_effectFilters")] mutableCopy];
	CIImage *ciImage = [self _newCIImageFromUIImage:actualImage];
	
	// Fixing image orientation, still dirt (?)
	int orientation = 1;
	float rotation = MSHookIvar<float>(self, "_rotationAngle");
	float angle = rotation;
	
	if (angle > 6)
		angle = fmodf(rotation, 6.28319);
	if (round(abs(angle)) == 3)
		orientation = 3;
	else if (round(angle) == 2)
		orientation = 8;
	else if (round(angle) == 5 || (round(angle) == -2 && angle < 0))
		orientation = 6;
	
	NSArray *cropAndStraightenFilters = [self _cropAndStraightenFiltersForImageSize:ciImage.extent.size forceSquareCrop:NO forceUseGeometry:NO];
	[effectFilters addObjectsFromArray:cropAndStraightenFilters];
	CIImage *ciImageWithFilters = [%c(PLCIFilterUtilities) outputImageFromFilters:effectFilters inputImage:ciImage orientation:orientation copyFiltersFirst:NO];
	CGImageRef cgImage = [MSHookIvar<CIContext *>(self, "_ciContextFullSize") createCGImage:ciImageWithFilters fromRect:[ciImageWithFilters extent]];
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	[library writeImageToSavedPhotosAlbum:cgImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
		CGImageRelease(cgImage);
		if (epHUD != nil) {
			[epHUD hide];
			[epHUD release];
		}
		[self _setControlsEnabled:YES animated:NO];
		[self cancel:nil];
	}];
	[library release];
}

- (UIBarButtonItem *)_rightButtonForMode:(int)mode enableDone:(BOOL)done enableSave:(BOOL)save
{
	UIBarButtonItem *item = %orig;
	if (mode == 0 && !done && save)
		[item setAction:@selector(ep_showOptions)];
	return item;
}

%end

static void EPLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	enabledArray = [[dict objectForKey:ENABLED_EFFECT] retain];
	TweakEnabled = [dict[@"Enabled"] boolValue];
	FillGrid = [dict[@"FillGrid"] boolValue];
	AutoHideBB = [dict[@"AutoHideBB"] boolValue];
	oldEditor = [dict[@"useOldEditor"] boolValue];
	#define readFloat(val, defaultVal) \
		val = dict[[NSString stringWithUTF8String:#val]] ? [dict[[NSString stringWithUTF8String:#val]] floatValue] : defaultVal;
	readFloat(CIColorMonochrome_R, 0.5)
	readFloat(CIColorMonochrome_G, 0.6)
	readFloat(CIColorMonochrome_B, 0.7)
	readFloat(CIFalseColor_R1, 0.2)
	readFloat(CIFalseColor_G1, 0.3)
	readFloat(CIFalseColor_B1, 0.5)
	readFloat(CIFalseColor_R2, 0.6)
	readFloat(CIFalseColor_G2, 0.8)
	readFloat(CIFalseColor_B2, 0.9)
	readFloat(CISepiaTone_inputIntensity, 1)
	readFloat(CIVibrance_inputAmount, 1)
	readFloat(CIColorMonochrome_inputIntensity, 1)
	readFloat(CIColorPosterize_inputLevels, 6)
	readFloat(CIGloom_inputRadius, 10)
	readFloat(CIGloom_inputIntensity, 1)
	readFloat(CIBloom_inputRadius, 10)
	readFloat(CIBloom_inputIntensity, 1)
	readFloat(CISharpenLuminance_inputSharpness, .4)
	readFloat(CIPixellate_inputScale, 8)
	readFloat(CIGaussianBlur_inputRadius, 10)
	readFloat(CITwirlDistortion_inputRadius, 200)
	readFloat(CITwirlDistortion_inputAngle, 3.14)
	readFloat(CITriangleKaleidoscope_inputSize, 300)
	readFloat(CITriangleKaleidoscope_inputDecay, 0.85)
	readFloat(CIPinchDistortion_inputRadius, 200)
	readFloat(CIPinchDistortion_inputScale, 0.5)
	readFloat(CILightTunnel_inputRadius, 90)
	readFloat(CILightTunnel_inputRotation, 0)
	readFloat(CIHoleDistortion_inputRadius, 150)
	readFloat(CICircleSplashDistortion_inputRadius, 150)
	readFloat(CICircularScreen_inputWidth, 6)
	readFloat(CICircularScreen_inputSharpness, 0.7)
	readFloat(CILineScreen_inputAngle, 0)
	readFloat(CILineScreen_inputWidth, 6)
	readFloat(CILineScreen_inputSharpness, 0.7)
	readFloat(CIMirror_inputAngle, 0.0)
	
	readFloat(qualityFactor, 1)
	mode = integerValueForKey(saveMode, 1);
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera MobileSlideShow");
	EPLoader();
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	EPLoader();
	if (TweakEnabled) {
		%init;
		if (isiOS7) {
			%init(iOS7);
		}
		else if (isiOS8) {
			%init(iOS8);
		}
	}
	[pool drain];
}
