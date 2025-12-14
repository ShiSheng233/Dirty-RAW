//
//  NikonSDKWrapper.h
//  Dirty RAW
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NKImageInfo : NSObject
@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;
@property (nonatomic) NSUInteger byteDepth;
@property (nonatomic) NSUInteger colorType;
@property (nonatomic) NSUInteger orientation;
@property (nonatomic) double resolution;
@end

@interface NKTagData : NSObject
@property (nonatomic) NSUInteger tagID;
@property (nonatomic) NSUInteger tagType;
@property (nonatomic) NSUInteger tagValue;
@property (nonatomic, nullable) NSData *data;
@property (nonatomic, nullable) NSString *stringValue;
@end

@interface NKEXIFData : NSObject
@property (nonatomic, nullable) NSString *make;
@property (nonatomic, nullable) NSString *model;
@property (nonatomic, nullable) NSString *software;
@property (nonatomic, nullable) NSString *artist;
@property (nonatomic, nullable) NSString *copyright;
@property (nonatomic, nullable) NSDate *dateTime;
@property (nonatomic) double exposureTime;
@property (nonatomic) double fNumber;
@property (nonatomic) double focalLength;
@property (nonatomic) NSUInteger iso;
@property (nonatomic) double exposureBias;
@property (nonatomic) NSUInteger meteringMode;
@property (nonatomic) NSUInteger exposureProgram;
@property (nonatomic) NSUInteger whiteBalance;
/// As-shot color temperature in Kelvin, when available from Nikon metadata.
@property (nonatomic, nullable) NSNumber *colorTemperatureKelvin;
@property (nonatomic) NSUInteger flash;
@property (nonatomic, nullable) NSString *lensInfo;
@property (nonatomic) NSUInteger fileFormat;
@property (nonatomic) NSUInteger pictureControl;
@property (nonatomic) NSUInteger activeDLighting;
@property (nonatomic) NSUInteger noiseReduction;
@property (nonatomic, nullable) NSArray<NSString *> *shootingData;
@end

@interface NikonSDKWrapper : NSObject

+ (BOOL)initializeLibrary;
+ (void)closeLibrary;

- (nullable instancetype)initWithFilePath:(NSString *)filePath;
- (void)closeSession;

- (NSUInteger)getFileFormat;
- (nullable NKImageInfo *)getImageInfo;
- (nullable NKImageInfo *)getOriginalInfo;
- (nullable NSData *)getImageDataWithInfo:(NKImageInfo *)info;
- (nullable NKEXIFData *)getEXIFData;
- (nullable NKTagData *)getTagData:(NSUInteger)tagID;
- (nullable NSImage *)decodeToImage;

@end

NS_ASSUME_NONNULL_END
