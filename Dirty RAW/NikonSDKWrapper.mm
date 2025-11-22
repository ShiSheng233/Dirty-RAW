//
//  NikonSDKWrapper.mm
//  Dirty RAW
//

#import "NikonSDKWrapper.h"
#import <Carbon/Carbon.h>
#include <sys/sysctl.h>

// Declare Nkfl_Entry with C linkage before including the header
extern "C" {
    unsigned long Nkfl_Entry(unsigned long ulCommand, void* pParam);
}

#include "Nkfl_Interface.h"

static NkflPtr s_pNkflPtr = NULL;
static Nkfl_EntryProcPtr s_entryFunc = NULL;

@implementation NKImageInfo
@end

@implementation NKTagData
@end

@implementation NKEXIFData
@end

@interface NikonSDKWrapper ()
{
    unsigned long _sessionID;
}
@end

@implementation NikonSDKWrapper

+ (BOOL)initializeLibrary {
    if (s_pNkflPtr != NULL) {
        return YES;
    }

    // Use static linking like the sample app
    s_entryFunc = (Nkfl_EntryProcPtr)Nkfl_Entry;
    if (!s_entryFunc) {
        NSLog(@"NikonSDK: Failed to get Nkfl_Entry");
        return NO;
    }

    // Initialize library
    NkflLibraryParam libParam = {0};
    libParam.ulSize = sizeof(NkflLibraryParam);
    libParam.ulVersion = 0x01000000;
    
    // Get system memory and set VM size
    uint64_t installedRAM = 0;
    size_t size = sizeof(installedRAM);
    sysctlbyname("hw.memsize", &installedRAM, &size, NULL, 0);
    installedRAM = installedRAM / 1024 / 1024 / 4; // Convert to MB and use 1/4
    libParam.ulVMMemorySize = (unsigned long)installedRAM;
    
    // Set temp file path
    NSString *tempDir = NSTemporaryDirectory();
    NSString *vmFile = [tempDir stringByAppendingPathComponent:@"DirtyRAW_VM.tmp"];
    strncpy((char *)libParam.VMFileInfo, [vmFile UTF8String], MAX_PATH - 1);
    
    libParam.pNkflPtr = &s_pNkflPtr;

    unsigned long result = s_entryFunc(kNkfl_Cmd_OpenLibrary, &libParam);
    if (result != kNkfl_Code_None) {
        NSLog(@"NikonSDK: Failed to open library: %lu", result);
        s_entryFunc = NULL;
        return NO;
    }

    return YES;
}

+ (void)closeLibrary {
    if (s_pNkflPtr && s_entryFunc) {
        s_entryFunc(kNkfl_Cmd_CloseLibrary, s_pNkflPtr);
        s_pNkflPtr = NULL;
    }
    s_entryFunc = NULL;
}

- (nullable instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        if (!s_entryFunc) {
            return nil;
        }

        _sessionID = 0;

        NkflSessionParam sessionParam = {0};
        sessionParam.ulSize = sizeof(NkflSessionParam);
        sessionParam.ulType = kNkfl_Source_FileName_UTF8;
        sessionParam.pFileInfo = (void *)[filePath UTF8String];
        sessionParam.bImageLoadSkip = false;

        unsigned long result = s_entryFunc(kNkfl_Cmd_OpenSession, &sessionParam);
        if (result != kNkfl_Code_None) {
            NSLog(@"NikonSDK: Failed to open session: %lu for file: %@", result, filePath);
            return nil;
        }

        _sessionID = sessionParam.ulSessionID;
    }
    return self;
}

- (void)dealloc {
    [self closeSession];
}

- (void)closeSession {
    if (_sessionID && s_entryFunc) {
        NkflSessionParam sessionParam = {0};
        sessionParam.ulSize = sizeof(NkflSessionParam);
        sessionParam.ulSessionID = _sessionID;

        s_entryFunc(kNkfl_Cmd_CloseSession, &sessionParam);
        _sessionID = 0;
    }
}

- (NSUInteger)getFileFormat {
    if (!_sessionID || !s_entryFunc) return 0;

    NkflFileInfoParam param = {0};
    param.ulSize = sizeof(NkflFileInfoParam);
    param.ulSessionID = _sessionID;

    unsigned long result = s_entryFunc(kNkfl_Cmd_GetFileInfo, &param);
    if (result != kNkfl_Code_None) {
        return 0;
    }

    return param.ulFormat;
}

- (nullable NKImageInfo *)getImageInfo {
    if (!_sessionID || !s_entryFunc) return nil;

    NkflImageInfoParam param = {0};
    param.ulSize = sizeof(NkflImageInfoParam);
    param.ulSessionID = _sessionID;

    unsigned long result = s_entryFunc(kNkfl_Cmd_GetImageInfo, &param);
    if (result != kNkfl_Code_None) {
        return nil;
    }

    NKImageInfo *info = [[NKImageInfo alloc] init];
    info.width = param.ulWidth;
    info.height = param.ulHeight;
    info.byteDepth = param.ulByteDepth;
    info.colorType = param.ulColor;
    info.orientation = param.ulOrientation;
    info.resolution = param.dbResolution;

    return info;
}

- (nullable NKImageInfo *)getOriginalInfo {
    if (!_sessionID || !s_entryFunc) return nil;

    NkflImageInfoParam param = {0};
    param.ulSize = sizeof(NkflImageInfoParam);
    param.ulSessionID = _sessionID;

    unsigned long result = s_entryFunc(kNkfl_Cmd_GetOriginalInfo, &param);
    if (result != kNkfl_Code_None) {
        return nil;
    }

    NKImageInfo *info = [[NKImageInfo alloc] init];
    info.width = param.ulWidth;
    info.height = param.ulHeight;
    info.byteDepth = param.ulByteDepth;
    info.colorType = param.ulColor;
    info.orientation = param.ulOrientation;
    info.resolution = param.dbResolution;

    return info;
}

- (nullable NSData *)getImageDataWithInfo:(NKImageInfo *)info {
    if (!_sessionID || !s_entryFunc || !info) return nil;

    NSUInteger planes = 3; // RGB
    NSUInteger dataSize = info.width * info.height * info.byteDepth * planes;

    void *buffer = malloc(dataSize);
    if (!buffer) return nil;

    NkflImageParam param = {0};
    param.ulSize = sizeof(NkflImageParam);
    param.ulSessionID = _sessionID;
    param.rectArea.top = 0;
    param.rectArea.left = 0;
    param.rectArea.bottom = (short)info.height;
    param.rectArea.right = (short)info.width;
    param.ulDataSize = (unsigned long)dataSize;
    param.pData = buffer;

    unsigned long result = s_entryFunc(kNkfl_Cmd_GetImageData, &param);
    if (result != kNkfl_Code_None) {
        free(buffer);
        return nil;
    }

    return [NSData dataWithBytesNoCopy:buffer length:dataSize freeWhenDone:YES];
}

- (nullable NKTagData *)getTagData:(NSUInteger)tagID {
    if (!_sessionID || !s_entryFunc) return nil;

    NkflTagDataParam param = {0};
    param.ulSize = sizeof(NkflTagDataParam);
    param.ulSessionID = _sessionID;
    param.ulTagID = (unsigned long)tagID;

    unsigned long result = s_entryFunc(kNkfl_Cmd_GetTagData, &param);
    if (result != kNkfl_Code_None) {
        return nil;
    }

    NKTagData *tagData = [[NKTagData alloc] init];
    tagData.tagID = param.ulTagID;
    tagData.tagType = param.ulTagType;
    tagData.tagValue = param.ulTagValue;

    // Handle string tags
    if (param.ulTagType == kNkfl_TagType_String && param.ulTagLength > 0) {
        char *buffer = (char *)malloc(param.ulTagLength + 1);
        if (buffer) {
            param.pData = buffer;
            result = s_entryFunc(kNkfl_Cmd_GetTagData, &param);
            if (result == kNkfl_Code_None) {
                buffer[param.ulTagLength] = '\0';
                tagData.stringValue = [NSString stringWithUTF8String:buffer];
            }
            free(buffer);
        }
    }

    return tagData;
}

- (nullable NKEXIFData *)getEXIFData {
    if (!_sessionID || !s_entryFunc) return nil;

    NKEXIFData *exif = [[NKEXIFData alloc] init];

    // Get string tags
    NKTagData *tag;

    tag = [self getTagData:kNkfl_Tag_Make];
    if (tag.stringValue) exif.make = tag.stringValue;

    tag = [self getTagData:kNkfl_Tag_Model];
    if (tag.stringValue) exif.model = tag.stringValue;

    tag = [self getTagData:kNkfl_Tag_Software];
    if (tag.stringValue) exif.software = tag.stringValue;

    tag = [self getTagData:kNkfl_Tag_Artist];
    if (tag.stringValue) exif.artist = tag.stringValue;

    tag = [self getTagData:kNkfl_Tag_CopyRight];
    if (tag.stringValue) exif.copyright = tag.stringValue;

    // Get numeric tags
    tag = [self getTagData:kNkfl_Tag_NkISOSensitivity];
    if (tag) exif.iso = tag.tagValue;

    tag = [self getTagData:kNkfl_Tag_ExposureProgram];
    if (tag) exif.exposureProgram = tag.tagValue;

    tag = [self getTagData:kNkfl_Tag_MeteringMode];
    if (tag) exif.meteringMode = tag.tagValue;

    tag = [self getTagData:kNkfl_Tag_Flash];
    if (tag) exif.flash = tag.tagValue;

    tag = [self getTagData:kNkfl_Tag_NkWhiteBalance];
    if (tag) exif.whiteBalance = tag.tagValue;

    tag = [self getTagData:kNkfl_Tag_NkActiveDLighting];
    if (tag) exif.activeDLighting = tag.tagValue;

    tag = [self getTagData:kNkfl_Tag_NkPictureControlMode];
    if (tag) exif.pictureControl = tag.tagValue;

    // Get rational tags (exposure time, f-number, etc.)
    NkflTagDataParam param = {0};
    param.ulSize = sizeof(NkflTagDataParam);
    param.ulSessionID = _sessionID;

    // Exposure Time
    param.ulTagID = kNkfl_Tag_ExposureTime;
    if (s_entryFunc(kNkfl_Cmd_GetTagData, &param) == kNkfl_Code_None) {
        if (param.ulTagType == kNkfl_TagType_Double) {
            double value;
            param.pData = &value;
            if (s_entryFunc(kNkfl_Cmd_GetTagData, &param) == kNkfl_Code_None) {
                exif.exposureTime = value;
            }
        }
    }

    // F-Number
    param.ulTagID = kNkfl_Tag_FNumber;
    param.pData = NULL;
    if (s_entryFunc(kNkfl_Cmd_GetTagData, &param) == kNkfl_Code_None) {
        if (param.ulTagType == kNkfl_TagType_Double) {
            double value;
            param.pData = &value;
            if (s_entryFunc(kNkfl_Cmd_GetTagData, &param) == kNkfl_Code_None) {
                exif.fNumber = value;
            }
        }
    }

    // Focal Length
    param.ulTagID = kNkfl_Tag_FocalLength;
    param.pData = NULL;
    if (s_entryFunc(kNkfl_Cmd_GetTagData, &param) == kNkfl_Code_None) {
        if (param.ulTagType == kNkfl_TagType_Double) {
            double value;
            param.pData = &value;
            if (s_entryFunc(kNkfl_Cmd_GetTagData, &param) == kNkfl_Code_None) {
                exif.focalLength = value;
            }
        }
    }

    // Exposure Bias
    param.ulTagID = kNkfl_Tag_ExposureBiasValue;
    param.pData = NULL;
    if (s_entryFunc(kNkfl_Cmd_GetTagData, &param) == kNkfl_Code_None) {
        if (param.ulTagType == kNkfl_TagType_Double) {
            double value;
            param.pData = &value;
            if (s_entryFunc(kNkfl_Cmd_GetTagData, &param) == kNkfl_Code_None) {
                exif.exposureBias = value;
            }
        }
    }

    // DateTime
    param.ulTagID = kNkfl_Tag_DateTime;
    param.pData = NULL;
    if (s_entryFunc(kNkfl_Cmd_GetTagData, &param) == kNkfl_Code_None) {
        if (param.ulTagType == kNkfl_TagType_DateTime) {
            NkflTagParam_DateTime dateTime;
            param.pData = &dateTime;
            if (s_entryFunc(kNkfl_Cmd_GetTagData, &param) == kNkfl_Code_None) {
                NSDateComponents *components = [[NSDateComponents alloc] init];
                components.year = dateTime.ulYear;
                components.month = dateTime.ulMonth;
                components.day = dateTime.ulDay;
                components.hour = dateTime.ulHour;
                components.minute = dateTime.ulMinute;
                components.second = (NSInteger)dateTime.dbSecond;
                exif.dateTime = [[NSCalendar currentCalendar] dateFromComponents:components];
            }
        }
    }

    // Get shooting data strings
    unsigned long ulLine = 0, ulColumn = 0;
    NkflTagStringInfoParam stringInfoParam = {0};
    stringInfoParam.ulSize = sizeof(NkflTagStringInfoParam);
    stringInfoParam.ulSessionID = _sessionID;

    if (s_entryFunc(kNkfl_Cmd_GetTagStringInfo, &stringInfoParam) == kNkfl_Code_None) {
        ulLine = stringInfoParam.ulLines;
        ulColumn = stringInfoParam.ulColumns;

        NSMutableArray *shootingStrings = [NSMutableArray array];

        for (unsigned long i = 0; i < ulLine; i++) {
            for (unsigned long j = 0; j < ulColumn; j++) {
                NkflTagStringParam strParam = {0};
                strParam.ulSize = sizeof(NkflTagStringParam);
                strParam.ulSessionID = _sessionID;
                strParam.ulLines = i;
                strParam.ulColumns = j;

                if (s_entryFunc(kNkfl_Cmd_GetTagString, &strParam) == kNkfl_Code_None && strParam.ulStringLength > 0) {
                    char *buffer = (char *)malloc(strParam.ulStringLength + 1);
                    if (buffer) {
                        strParam.pData = buffer;
                        if (s_entryFunc(kNkfl_Cmd_GetTagString, &strParam) == kNkfl_Code_None) {
                            buffer[strParam.ulStringLength] = '\0';
                            NSString *str = [NSString stringWithUTF8String:buffer];
                            if (str && str.length > 0) {
                                [shootingStrings addObject:str];
                            }
                        }
                        free(buffer);
                    }
                }
            }
        }

        if (shootingStrings.count > 0) {
            exif.shootingData = [shootingStrings copy];
        }
    }

    return exif;
}

- (nullable NSImage *)decodeToImage {
    NKImageInfo *info = [self getImageInfo];
    if (!info) return nil;

    NSData *imageData = [self getImageDataWithInfo:info];
    if (!imageData) return nil;

    NSUInteger width = info.width;
    NSUInteger height = info.height;
    NSUInteger byteDepth = info.byteDepth;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)imageData);
    
    if (!provider) {
        CGColorSpaceRelease(colorSpace);
        return nil;
    }
    
    CGImageRef cgImage = NULL;
    
    if (byteDepth == 2) {
        // 16-bit per channel
        CGBitmapInfo bitmapInfo = (CGBitmapInfo)kCGImageAlphaNone | (CGBitmapInfo)kCGBitmapByteOrder16Host;
        cgImage = CGImageCreate(
            width,
            height,
            16,                                          // bits per component
            48,                                          // bits per pixel (16 * 3)
            width * 6,                                   // bytes per row (width * 2 bytes * 3 channels)
            colorSpace,
            bitmapInfo,
            provider,
            NULL,
            false,
            kCGRenderingIntentDefault
        );
    } else {
        // 8-bit per channel
        cgImage = CGImageCreate(
            width,
            height,
            8,
            24,
            width * 3,
            colorSpace,
            (CGBitmapInfo)(kCGImageAlphaNone | kCGBitmapByteOrderDefault),
            provider,
            NULL,
            false,
            kCGRenderingIntentDefault
        );
    }
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    if (!cgImage) return nil;

    NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(width, height)];
    CGImageRelease(cgImage);

    return image;
}

@end
